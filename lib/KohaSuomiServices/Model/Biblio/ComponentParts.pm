package KohaSuomiServices::Model::Biblio::ComponentParts;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);

use KohaSuomiServices::Model::Exception::NotFound;

has schema => sub {KohaSuomiServices::Database::Client->new};
has sru => sub {KohaSuomiServices::Model::SRU->new};
has biblio => sub {KohaSuomiServices::Model::Biblio->new};
has interface => sub {KohaSuomiServices::Model::Biblio::Interface->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};

sub exportComponentParts {
    my ($self, $componentparts) = @_;

    foreach my $componentpart (@{$componentparts}) {
        my $host = $self->interface->host("update");
        my $req = $resBody->{marcxml} ? {marc => $resBody->{marcxml}, source_id => $targetId->{target_id}, target_id => $source_id, interface => $host->{name}} : {marc => $resBody, source_id => $targetId->{target_id}, target_id => $source_id, interface => $host->{name}};
        $self->biblio->export($req);
    }
}

sub find {
    my ($self, $remote_interface, $target_id) = @_;
    my $interface = $self->interface->load({name => $remote_interface, type => "getcomponentparts"});
    my $search;
    if ($interface->{interface} eq "SRU") {
        my $matcher = {target_id => $target_id};
        $search = $self->sruLoopAll($interface, $matcher);

    }
    return $search;
}

sub sruLoopAll {
    my ($self, $interface, $matcher) = @_;

    my $loopstart = 1;
    my $oldstart = 1;
    my $increase;
    my $search;
    while ($loopstart > 0) {
        my @params;
        foreach my $param (@{$interface->{params}}) {
            $increase = $param->{value} if ($param->{name} eq "maximumRecords");
            if ($param->{name} eq "startRecord") {
                if ($loopstart gt $oldstart) {
                    $param->{value} = $param->{value} + $increase;
                    $oldstart++;
                }
            }
            push @params, $param;
        }

        $interface->{params} = \@params;
        my $path = $self->biblio->create_query($interface->{params}, $matcher);
        $path->{url} = $interface->{endpoint_url};
        my $results = $self->sru->search($path);
        my $resultsize = scalar @{$results};
        if (@{$results}) {
            push @{$search}, @{$results};
            if ($resultsize < $increase) {
                $loopstart = 0;
            } else {
                $loopstart++;
            }
        } else {
            $loopstart = 0;
        }
    }

    return $search;
}
1;