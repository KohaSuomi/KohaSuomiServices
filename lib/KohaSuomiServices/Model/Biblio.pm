package KohaSuomiServices::Model::Biblio;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use POSIX 'strftime';
use Mojo::UserAgent;
use Mojo::Log;
use Mojo::URL;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json from_json);
use KohaSuomiServices::Model::Exception::NotFound;
use KohaSuomiServices::Model::Exception::BadParameter;
use KohaSuomiServices::Model::Biblio::Interface;
use KohaSuomiServices::Model::Biblio::Fields;
use KohaSuomiServices::Model::Biblio::Matcher;
use KohaSuomiServices::Model::Biblio::ActiveRecords;
use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Model::Biblio::Exporter;
use KohaSuomiServices::Model::Biblio::ExportAuth;
use KohaSuomiServices::Model::Biblio::Response;

has schema => sub {KohaSuomiServices::Database::Client->new};
has sru => sub {KohaSuomiServices::Model::SRU->new};
has interface => sub {KohaSuomiServices::Model::Biblio::Interface->new};
has fields => sub {KohaSuomiServices::Model::Biblio::Fields->new};
has matchers => sub {KohaSuomiServices::Model::Biblio::Matcher->new};
has active => sub {KohaSuomiServices::Model::Biblio::ActiveRecords->new};
has exporter => sub {KohaSuomiServices::Model::Biblio::Exporter->new};
has exportauth => sub {KohaSuomiServices::Model::Biblio::ExportAuth->new};
has response => sub {KohaSuomiServices::Model::Biblio::Response->new};
has convert => sub {KohaSuomiServices::Model::Convert->new};
has ua => sub {Mojo::UserAgent->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has log => sub {Mojo::Log->new(path => KohaSuomiServices::Model::Config->new->load->{"logs"}, level => KohaSuomiServices::Model::Config->new->load->{"log_level"})};

sub export {
    my ($self, $params) = @_;

    my $schema = $self->schema->client($self->config);
    my $interface = defined $params->{target_id} ? $self->interface->load({name => $params->{interface}, type => "update"}) : $self->interface->load({name => $params->{interface}, type => "add"});
    
    my $type = defined $params->{target_id} ? "update" :"add";
    my $authuser = $self->exportauth->checkAuthUser($schema, $params->{username}, $interface->{id});
    my $exporter = $self->exporter->setExporterParams($interface, $type, "waiting", $params->{source_id}, $params->{target_id}, $authuser, $params->{parent_id});
    my $data = $self->exporter->insert($schema, $exporter);

    $params->{marc} = ref($params->{marc}) eq "HASH" ? $params->{marc} : $self->convert->formatjson($params->{marc});
    $self->fields->store($data->id, $params->{marc});

    return {export => $data->id, message => "Success"};
    
}

sub broadcast {
    my ($self, $params) = @_;
    
    my %matchers = $self->matchers->defaultSearchMatchers();
    my $identifier = $self->getIdentifier($params->{marc}, %matchers);
    my $schema = $self->schema->client($self->config);
    my $results = $self->active->find($schema, {identifier => $identifier});
    foreach my $result (@{$results}) {
        if ($params->{updated} gt $result->{updated} || !defined $result->{updated}) {
            $self->export({
                target_id => $result->{target_id},
                marc => $params->{marc},
                interface => $result->{interface_name}
            });
            $self->active->update($schema, $result->{id}, {updated => $params->{updated}});
        }
    }

    return {message => "Success"};
}

sub pushExport {
    my ($self, $type, $parent_id) = @_;

    my $exports = $self->exporter->getExports($type, $parent_id);
    foreach my $export (@{$exports}){
        warn Data::Dumper::Dumper $export;
        # my $interface = $self->interface->load({id=> $export->{interface_id}}); 
        # my $path = $self->create_path($interface, $export);
        # my %removeMatchers = $self->matchers->removeMatchers($interface->{id});
        # my $data = $self->fields->find($export->{id}, %removeMatchers);
        # my $body = $self->create_body($interface->{params}, $data);
        # my $authentication = $self->exportauth->interfaceAuthentication($interface, $export->{authuser_id}, $interface->{method});
        # my ($resCode, $resBody, $resHeaders) = $self->callInterface($interface->{method}, $interface->{format}, $path, $body, $authentication);
        # if ($resCode eq "200" || $resCode eq "201") {
        #     $self->exporter->update($export->{id}, {status => "success", errorstatus => ""});
        #     $self->response->getAndUpdate($interface, $resBody, $resHeaders, $export->{source_id});
        #     $self->log->info("Export ".$export->{id}." finished successfully with");
        #     $self->log->debug($resBody);
        # } else {
        #     my $error = $resHeaders;
        #     $error = $resHeaders.' '.$resBody if ($type eq "add");
        #     $self->exporter->update($export->{id}, {status => "failed", errorstatus => $error});
        #     $self->log->info("Export ".$export->{id}." failed with ".$error);

        # }
    }

    return {message => "Success"};
}

sub list {
    my ($self, $params) = @_;
    
    my $schema = $self->schema->client($self->config);
    my @data = $self->exporter->find($schema, $params, { order_by => { -desc => [qw/timestamp/] }});
    my @results;
    foreach my $data (@{$self->schema->get_columns(@data)}) {
        my $d = $data;
        my $interface = $self->interface->load({id=> $data->{interface_id}})->{name};
        $d->{interface_name} = $interface;
        push @results, $d;
    }  
    return \@results;
}

sub callInterface {
    my ($self, $method, $format, $path, $body, $authentication) = @_;

    my $tx = $self->interface->buildTX($method, $format, $path, $body, $authentication);
    return ($tx->res->code, $tx->res->body, $tx->res->error->{message}) if $tx->res->error;
    return ($tx->res->code, from_json($tx->res->body), $tx->res->headers);
    
}

sub addActive {
    my ($self, $params) = @_;

    
    my $schema = $self->schema->client($self->config);
    my %matchers = $self->matchers->defaultSearchMatchers();
    my $record = $self->convert->formatjson($params->{marcxml});
    my $matcher = $self->search_fields($record, %matchers);
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No valid identifier ") unless $matcher;
    delete $params->{marcxml};
    $params->{identifier} = join("|", map { "$_" } values %{$matcher});
    $params->{identifier_field} = join("|", map { "$_" } keys %{$matcher});
    my $exist = $self->active->find($schema, $params);
    $self->active->insert($schema, $params) unless @{$exist};

    return {message => "Success"};
}

sub updateActive {
    my ($self) = @_;
    
    my $schema = $self->schema->client($self->config);
    my $dt = strftime "%Y-%m-%d 00:00:00", ( localtime(time) );
    my $params = {updated => undef, created => {">=" => $dt}};
    my $results = $self->active->find($schema, $params);
    my $host = $self->interface->load({host => 1, type => "search"});
    foreach my $result (@{$results}) {
        my $path = $self->getSearchPath($host, {$result->{identifier_field} => $result->{identifier}});
        my $search = $self->sru->search($path);
        $search = shift @{$search};
        if ($search) {
            my $exporter = $self->exporter->setExporterParams($host, "update", "pending", $result->{target_id});
            my $data = $self->exporter->insert($schema, $exporter);
            $self->fields->store($data->id, $search);
            my $now = strftime "%Y-%m-%d %H:%M:%S", ( localtime(time) );
            $self->active->update($schema, $result->{id}, {updated => $now});
        }
    }
}

sub searchTarget {
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

sub getTargetId {
    my ($self, $remote_interface, $record) = @_;

    return unless $record;

    my $schema = $self->schema->client($self->config);
    my $interface = $self->interface->load({name => $remote_interface, type => "update"});
    my %matchers = $self->matchers->find($schema, $interface->{id}, "identifier");

    my $identifier = $self->search_fields($record, %matchers);
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "Identifier not found on record") unless $identifier;
    my ($key, $value) = %{$identifier};
    $value =~ s/\D//g;
    my $target_id = $value;

    return $target_id;
}

sub getSearchPath {
    my ($self, $interface, $matcher) = @_;

    my $path = $self->create_query($interface->{params}, $matcher);
    $path->{url} = $interface->{endpoint_url};

    return $path;
}

sub getIdentifier {
    my ($self, $record, %matchers) = @_;

    my ($key, $value) = %{$self->search_fields($record, %matchers)} if $self->search_fields($record, %matchers);
    $value =~ s/\D//g;
    return $value;
}

sub search_fields {
    my ($self, $record, %matchers) = @_;

    my $matcher;
    foreach my $field (@{$record->{fields}}) {
        if ($matchers{$field->{tag}}) {
            foreach my $subfield (@{$field->{subfields}}) {
                if (ref($matchers{$field->{tag}}) eq "ARRAY") {
                    foreach my $code (@{$matchers{$field->{tag}}}) {
                        if ($subfield->{code} eq $code) {
                            $matcher->{$field->{tag}.$code} = $subfield->{value} unless $matcher->{$field->{tag}.$code};
                        }
                    }
                }
                if ($subfield->{code} eq $matchers{$field->{tag}}) {
                    $matcher->{$field->{tag}.$matchers{$field->{tag}}} = $subfield->{value} unless $matcher->{$field->{tag}.$matchers{$field->{tag}}};
                }
            }
        } else {
            my ($key, $value) = %matchers;
            if ($key eq $field->{tag}) {
                $matcher->{$field->{tag}} = $field->{value};
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
                my ($key, $value) = %{$matcher} if $matcher;
                if ($matcher->{$valuematch[0]}) {
                    if ($param->{value} =~ /id=/) {
                        $matcher->{$valuematch[0]} =~ s/\D//g;
                    }
                    $param->{value} =~ s/{$valuematch[0]}/$matcher->{$valuematch[0]}/g;
                } elsif ($key eq $valuematch[0]) {
                        $param->{value} =~ s/{$valuematch[0]}/$valuematch[0]/g;
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
            if (defined $valuematch[0] && $valuematch[0] ne "marcxml" && $valuematch[0] ne "marcjson") {
                if ($matcher->{$valuematch[0]}) {
                    $param->{value} =~ s/{$valuematch[0]}/$matcher->{$valuematch[0]}/g;
                    $body->{$param->{name}} = $matcher->{$valuematch[0]};
                } else {
                    delete $param->{name};
                    delete $param->{value};
                }
            }
            if (defined $valuematch[0] && $valuematch[0] eq "marcxml") {
                $body->{$param->{name}} = $self->convert->formatxml($matcher) if $body->{$param->{name}};
                $body = $self->convert->formatxml($matcher) unless $body->{$param->{name}};
            }
            if (defined $valuematch[0] && $valuematch[0] eq "marcjson") {
                $body = $matcher;
            }
        }
    }
    return $body;
}

1;