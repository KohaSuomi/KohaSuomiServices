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
has exporter => sub {KohaSuomiServices::Model::Biblio::Exporter->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};

sub exportComponentParts {
    my ($self, $parent_id, $linkvalue) = @_;
    my $schema = $self->schema->client($self->config);
    my @componentparts = $self->biblio->exporter->find($schema, {status => "waiting", parent_id => $parent_id}, undef);
    foreach my $d (@{$self->schema->get_columns(@componentparts)}) {
        $self->biblio->fields->replaceValue($d->{id}, "773", "w", $linkvalue);
        $self->exporter->update($d->{id}, {status => "pending"});
    }
}

sub find {
    my ($self, $remote_interface, $source_id) = @_;
    my $interface = $self->interface->load({name => $remote_interface, type => "getcomponentparts"});
    my $search;
    if ($interface->{interface} eq "SRU") {
        my $matcher = {source_id => $source_id};
        $search = $self->sruLoopAll($interface, $matcher);

    }

    if ($interface->{interface} eq "REST") {
        my $matcher = {source_id => $source_id};
    }

    return $search;
}

sub failWithParent {
    my ($self, $parent_id) = @_;

    my $schema = $self->schema->client($self->config);
    my @componentparts = $self->biblio->exporter->find($schema, {status => "waiting", parent_id => $parent_id}, undef);
    foreach my $d (@{$self->schema->get_columns(@componentparts)}) {
        $self->exporter->update($d->{id}, {status => "failed", errorstatus => "Parent failed"});
    }
}

sub fetchComponentParts {
    my ($self, $remote_interface, $source_id) = @_;
    my $host = $self->interface->host("add");
    my $results = $self->find($remote_interface, $source_id);
    $self->biblio->log->info("Component parts not found from ".$remote_interface) unless defined $results && $results;
    foreach my $result (@{$results}) {
        my $sourceid = $self->biblio->getTargetId($remote_interface, $result);
        my $res = $self->biblio->export({source_id => $sourceid, marc => $result, interface => $host->{name}});
        $self->biblio->log->info("Component part ".$res->{export}." fetched");
    }
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