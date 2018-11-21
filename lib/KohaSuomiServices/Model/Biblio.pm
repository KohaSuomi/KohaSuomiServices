package KohaSuomiServices::Model::Biblio;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);
use KohaSuomiServices::Model::Biblio::Interface;
use KohaSuomiServices::Model::Biblio::Fields;
use KohaSuomiServices::Model::Biblio::Matcher;
use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Model::Biblio::Exporter;

has sru => sub {KohaSuomiServices::Model::SRU->new};
has interface => sub {KohaSuomiServices::Model::Biblio::Interface->new};
has fields => sub {KohaSuomiServices::Model::Biblio::Fields->new};
has matchers => sub {KohaSuomiServices::Model::Biblio::Matcher->new};
has exporter => sub {KohaSuomiServices::Model::Biblio::Exporter->new};
has convert => sub {KohaSuomiServices::Model::Convert->new};
has ua => sub {Mojo::UserAgent->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has "schema";

sub export {
    my ($self, $params) = @_;

    my $schema = $self->schema->client($self->config);
    my $interface;
    my $exporter->{status} = "pending";
    $exporter->{localnumber} = $params->{localnumber};
    if (defined $params->{remotemarc}) {
        $interface = $self->interface->load({name => $params->{interface}, type => "update"});
        my %matchers = $self->matchers->find($schema, $interface->{id}, "identifier");
        my $remotenumber = $self->search_fields($params->{remotemarc}, %matchers);
        my $key = (%{$remotenumber})[0];
        $remotenumber->{$key} =~ s/\D//g;
        $exporter->{remotenumber} = $remotenumber->{$key};
        $exporter->{type} = "update";
    } else {
        $interface = $self->interface->load({name => $params->{interface}, type => "add"});
        $exporter->{type} = "add";
    }
    $exporter->{interface_id} = $interface->{id};
    my $data = $schema->resultset('Exporter')->new($exporter)->insert();

    $params->{localmarc} = ref($params->{localmarc}) eq "HASH" ? $params->{localmarc} : $self->convert->formatjson($params->{localmarc});
    $self->fields->store($data->id, $params->{localmarc});
    
    return {message => "Success"};
    
}

sub importer {
    my ($self, $params) = @_;

    my $schema = $self->schema->client($self->config);
    my $interface;
    
    my $importer->{status} = "pending";
    $importer->{remotenumber} = $params->{remotenumber};

    if (defined $params->{remotemarc}) {
        $interface = $self->interface->load({name => $params->{interface}, type => "update"});
        my %matchers = $self->matchers->find($schema, $interface->{id}, "identifier");
        my $remotenumber = $self->search_fields($params->{remotemarc}, %matchers);
        if ($remotenumber) {
            my $key = (%{$remotenumber})[0];
            $remotenumber->{$key} =~ s/\D//g;
            $importer->{localnumber} = $remotenumber->{$key};
        }
        $importer->{type} = "update";
        
    } else {
        $interface = $self->interface->load({name => $params->{interface}, type => "add"});
        $importer->{type} = "add";
    }
    
    $importer->{interface_id} = $interface->{id};
    my $data = $schema->resultset('Exporter')->new($importer)->insert();

    if (defined $params->{remotemarc}) {
        $params->{remotemarc} = ref($params->{remotemarc}) eq "HASH" ? $params->{remotemarc} : $self->convert->formatjson($params->{remotemarc});
        $self->fields->store($data->id, $params->{remotemarc});
    }
    
    return {message => "Success"};
    
}

sub push {
    my ($self) = @_;

    my $updates = $self->exporter->getUpdate();
    foreach my $update (@{$updates}){
        my $interface = $self->interface->load({id=> $update->{interface_id}});
        my $path = $self->create_path($interface, $update);
        my $data = $self->fields->find($update->{id});
        my $body = $self->create_body($interface->{params}, $data);
        $self->update($path, $body);
    }

    my $adds = $self->exporter->getAdd();
    foreach my $add (@{$adds}){
        my $interface = $self->interface->load({id=> $add->{interface_id}});
        my $path = $self->create_path($interface, $add);
        my $data = $self->fields->find($add->{id});
        my $body = $self->create_body($interface->{params}, $data);
        $self->add($path, $body);
    }
    return {message => "Success"};
}

sub list {
    my ($self, $params) = @_;
    
    my $schema = $self->schema->client($self->config);
    my @data = $self->exporter->find($schema, $params );
    
    return $self->schema->get_columns(@data);
}

sub find {
    my ($self, $auth, $interface, $params) = @_;
    
    my $path = $self->create_path($interface, $params);
    $auth = $auth->api_auth("local", "GET");
    my $tx = $self->ua->build_tx(GET => $path => $auth);
    $tx = $self->ua->start($tx);
    return decode_json($tx->res->body);
    
}

sub update {
    my ($self, $path, $body) = @_;
    
    warn Data::Dumper::Dumper $path;
    warn Data::Dumper::Dumper $body;
    # my $tx = $self->ua->build_tx(PUT => $path);
    # $tx = $self->ua->start($tx);
    # return decode_json($tx->res->body);
    
}

sub add {
    my ($self, $path, $body) = @_;
    
    
}

sub search_remote {
    my ($self, $remote_interface, $record) = @_;

    my $search;
    my $schema = $self->schema->client($self->config);
    my $interface = $self->interface->load({name => $remote_interface, type => "search"});
    my %matchers = $self->matchers->find($schema, $interface->{id}, "identifier"); #("020" => "a", "024" => "a", "027" => "a", "028" => "a", "028" => "b");
    if ($interface->{interface} eq "SRU") {
        my $matcher = $self->search_fields($record, %matchers);
        my $path = $self->create_query($interface->{params}, $matcher);
        $path->{url} = $interface->{endpoint_url};
        $search = $self->sru->search($path);
    } else {
        my $params = {};
        my $results = $self->find(undef, $interface, $params);
    }
    return $search;
    
}

sub search_fields {
    my ($self, $record, %matchers) = @_;

    my $matcher;
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

sub create_body {
    my ($self, $params, $matcher) = @_;

    my $body;
    foreach my $param (@{$params}) {
        if($param->{type} eq "body") {
            my @valuematch = $param->{value} =~ /{(.*?)}/g;
            if (defined $valuematch[0] && $valuematch[0] ne "marcxml") {
                if ($matcher->{$valuematch[0]}) {
                    $param->{value} =~ s/{$valuematch[0]}/$matcher->{$valuematch[0]}/g;
                    $body->{$param->{name}} = $matcher->{$valuematch[0]};
                } else {
                    delete $param->{name};
                    delete $param->{value};
                }
            }
            if (defined $valuematch[0] && $valuematch[0] eq "marcxml") {
                $body->{$param->{name}} = $self->convert->formatxml($matcher);
            }
        }
    }
    return $body;
}

1;