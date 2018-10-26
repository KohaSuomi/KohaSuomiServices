package KohaSuomiServices::Model::Biblio;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);
use KohaSuomiServices::Model::Biblio::Interface;
use KohaSuomiServices::Model::Biblio::Fields;
use KohaSuomiServices::Model::Config;

has sru => sub {KohaSuomiServices::Model::SRU->new};
has interface => sub {KohaSuomiServices::Model::Biblio::Interface->new};
has fields => sub {KohaSuomiServices::Model::Biblio::Fields->new};
has ua => sub {Mojo::UserAgent->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has "schema";

sub export {
    my ($self, $params) = @_;

    try {
        my $schema = $self->schema->client($self->config);
        my $interface = $self->interface->load({name => $params->{interface}, type => "add"});
        my $exporter->{interface_id} = $interface->{id};
        $exporter->{status} = "pending";
        $exporter->{localnumber} = $params->{localnumber};
        my $data = $schema->resultset('Exporter')->new($exporter)->insert();
        $self->fields->store($data->id, $params->{marc});
        return {message => "Success"};
    } catch {
        my $e = $_;
        warn Data::Dumper::Dumper $e->{message};
        return $e;
    }
    
}

sub find {
    my ($self, $auth, $interface, $params) = @_;
    
    try {
        my $path = $self->create_path($interface, $params);
        $auth = $auth->api_auth("local", "GET");
        my $tx = $self->ua->build_tx(GET => $path => $auth);
        $tx = $self->ua->start($tx);
        return decode_json($tx->res->body);
    } catch {
        my $e = $_;
        return $e;
    }
    
}

sub search_remote {
    my ($self, $remote_interface, $record) = @_;

    try {
        my $search;
        my $interface = $self->interface->load({name => $remote_interface, type => "search"});
        if ($interface->{interface} eq "SRU") {
            my $matcher = $self->search_fields($record);
            my $path = $self->create_query($interface->{params}, $matcher);
            $path->{url} = $interface->{endpoint_url};
            $search = $self->sru->search($path);
        } else {
            my $params = {};
            my $results = $self->find(undef, $interface, $params);
        }
        return $search;
    } catch {
        my $e = $_;
        return $e;
    }
    
}

sub search_fields {
    my ($self, $record) = @_;

    try {
        my $matcher;
        my %matchers = ("020" => "a", "022" => "a");
        foreach my $field (@{$record->{fields}}) {
            if ($matchers{$field->{tag}}) {
                foreach my $subfield (@{$field->{subfields}}) {
                    if ($subfield->{code} eq $matchers{$field->{tag}}) {
                        $matcher->{$field->{tag}.$matchers{$field->{tag}}} = $subfield->{value};
                    }
                }
            }
        }
        return $matcher;

    } catch {
        my $e = $_;
        return $e;
    }
    
}

sub create_path {
    my ($self, $interface, $params) = @_;
    my @matches = $interface->{endpoint_url} =~ /{(.*?)}/g;

    foreach my $match (@matches) {
        my $m = $params->{$match};
        $interface->{endpoint_url} =~ s/{$match}/$m/g;
    }
    return $interface->{endpoint_url};
}

sub create_query {
    my ($self, $params, $matcher) = @_;

    my $query;
    foreach my $param (@{$params}) {
        if($param->{type} eq "query") {
            my @valuematch = $param->{value} =~ /{(.*?)}/g;
            if (defined $valuematch[0]) {
                if ($matcher->{$valuematch[0]}) {
                    $param->{value} =~ s/{$valuematch[0]}/$matcher->{$valuematch[0]}/g;
                } else {
                    delete $param->{name};
                    delete $param->{value};
                }
            }
            if (defined $param->{name} && defined $param->{value}) {
                $query->{$param->{name}} = $param->{value};
            }
        }
    }
    return $query;
}

sub update {
    my ($self, $res) = @_;

}

sub add {
    my ($self, $res) = @_;

}

1;