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
use Mojo::JSON qw(decode_json encode_json from_json to_json);
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
has compare => sub {KohaSuomiServices::Model::Compare->new};
has ua => sub {Mojo::UserAgent->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has log => sub {Mojo::Log->new(path => KohaSuomiServices::Model::Config->new->load->{"logs"}, level => KohaSuomiServices::Model::Config->new->load->{"log_level"})};

sub export {
    my ($self, $params) = @_;

    my $schema = $self->schema->client($self->config);
    my $interface = defined $params->{target_id} && $params->{target_id} ? $self->interface->load({name => $params->{interface}, type => "update"}) : $self->interface->load({name => $params->{interface}, type => "add"});
    
    my $type = defined $params->{target_id} && $params->{target_id} ? "update" :"add";
    my $authuser = $self->exportauth->checkAuthUser($schema, $params->{username}, $interface->{id});
    my $exporter = $self->exporter->setExporterParams($interface, $type, "waiting", $params->{source_id}, $params->{target_id}, $authuser, $params->{parent_id}, $params->{force}, $params->{componentparts}, $params->{fetch_interface}, $params->{activerecord_id});
    my $data = $self->exporter->insert($schema, $exporter);
    $params->{marc} = ref($params->{marc}) eq "HASH" ? $params->{marc} : $self->convert->formatjson($params->{marc});
    if ($params->{check}) {
	my $target_id;
        ($params->{marc}, $target_id) = $self->remoteValues($params->{interface}, $params->{marc});
    }
    $self->fields->store($data->id, $params->{parent_id}, $params->{marc});

    return {export => $data->id, message => "Success"};
    
}

sub broadcast {
    my ($self, $params) = @_;
    
    $self->log->debug(Data::Dumper::Dumper $params);
    my %matchers = $self->matchers->defaultSearchMatchers();
    my $schema = $self->schema->client($self->config);
    while (my ($key, $value) = each %matchers) {
        my %matcher;
        $matcher{$key} = $value;
        my $identifier = $self->getIdentifier($params->{marc}, %matcher);
        $self->log->debug($identifier);
        my $results = $self->active->find($schema, {identifier => $identifier});
        next unless defined $results && $results;
        foreach my $result (@{$results}) {
            $self->log->debug($result->{updated});
            if (($params->{updated} gt $result->{updated}) || !defined $result->{updated}) {
                $self->export({
                    target_id => $result->{target_id},
                    source_id => $params->{source_id},
                    marc => $params->{marc},
                    interface => $result->{interface_name}
                });
                $self->response->componentparts->replaceComponentParts($result->{interface_name}, $result->{target_id}, $params->{source_id});
                $self->active->update($schema, $result->{id}, {updated => $params->{updated}});
            }
        }
    }

    return {message => "Success"};
}

sub pushExport {
    my ($self, $type, $componentparts) = @_;

    my $exports = $self->exporter->getExports($type, $componentparts);
    foreach my $export (@{$exports}){
        my $interface = $self->interface->load({id=> $export->{interface_id}}, $export->{force_tag});
        if ($export->{componentparts} && $export->{fetch_interface}) {
            $self->response->componentparts->fetchComponentParts($interface->{name}, $export->{fetch_interface}, $export->{source_id}, undef);
        }
        my $query = $self->create_query($interface->{params});
        my $path = $self->create_path($interface, $export, $query);
        my %removeMatchers = $self->matchers->removeMatchers($interface->{id});
        my $data = $self->fields->find($export->{id}, %removeMatchers);
        $data = $self->matchers->addFields($export->{interface_id}, $export->{id}, $data);
        my $body = $self->create_body($interface->{params}, $data);
        my $authentication = $self->exportauth->interfaceAuthentication($interface, $export->{authuser_id}, $interface->{method});
        my ($resCode, $resBody, $resHeaders) = $self->callInterface($interface->{method}, $interface->{format}, $path, $body, $authentication);
        if ($resCode eq "200" || $resCode eq "201") {
            $self->exporter->update($export->{id}, {status => "success", errorstatus => ""});
            $self->response->getAndUpdate($interface, $resBody, $resHeaders, $export->{source_id});
            $self->active->updateActiveRecords($export->{activerecord_id}) if defined $export->{activerecord_id} && $export->{activerecord_id};
            $self->log->info("Export ".$export->{id}." finished successfully with");
            $self->log->debug($resBody);
        } else {
            my $error = $resHeaders;
            $error = $resHeaders.' '.$resBody if ($type eq "add");
            $self->exporter->update($export->{id}, {status => "failed", errorstatus => $error});
            $self->response->componentparts->failWithParent($export->{source_id}, $export->{id});
            $self->log->info("Export ".$export->{id}." failed with ".$error);
        }
    }

    return {message => "Success"};
}

sub forceExport {
    my ($self, $id) = @_;

    $self->exporter->update($id, {status => "pending", force_tag => 1});
    my $schema = $self->schema->client($self->config);
    my @componentparts = $self->exporter->find($schema, {parent_id => $id, errorstatus => 'Parent failed'}, undef);
    if(@componentparts) {
        my @record = $self->exporter->find($schema, {id => $id}, undef);
        foreach my $d (@{$self->schema->get_columns(@componentparts)}) {
            $self->exporter->update($d->{id}, {status => "waiting", errorstatus => "", parent_id => $record[0]->source_id});
        }
    }

    return {message => "Success"};
    
}

sub list {
    my ($self, $params, $page, $rows) = @_;
    
    my $schema = $self->schema->client($self->config);
    my $conditions = defined $page && defined $rows ? { order_by => { -desc => [qw/timestamp/]}, page => $page, rows => $rows } : { order_by => { -desc => [qw/timestamp/]}};
    my @data = $self->exporter->find($schema, $params, $conditions);
    my $count = $self->exporter->count($schema, $params);
    my @results;
    foreach my $data (@{$self->schema->get_columns(@data)}) {
        my $d = $data;
        my $interface = $self->interface->load({id=> $data->{interface_id}})->{name};
        $d->{interface_name} = $interface;
        push @results, $d;
    }  

    return {results => \@results, count => $count};
}

sub interfaceReport {
    my ($self, $interface_name, $page, $rows) = @_;
    
    my $schema = $self->schema->client($self->config);
    my $interfaces = $self->interface->find({name => $interface_name});
    my $add_id;
    my $update_id;
    foreach my $interface (@{$interfaces}) {
        if ($interface->{type} eq "add") {
            $add_id = $interface->{id};
        }
        if ($interface->{type} eq "update") {
            $update_id = $interface->{id};
        }
    }
    my $params = [{interface_id => $add_id}, {interface_id => $update_id}];
    my $conditions = defined $page && defined $rows ? { order_by => { -desc => [qw/timestamp/]}, page => $page, rows => $rows } : { order_by => { -desc => [qw/timestamp/]}};
    my @data = $self->exporter->find($schema, $params, $conditions);
    my $count = $self->exporter->count($schema, $params);
    my @results;
    foreach my $data (@{$self->schema->get_columns(@data)}) {
        my $d = $data;
        push @results, $d;
    }  

    return {results => \@results, count => $count};
}

sub getRecord {
    my ($self, $id) = @_;

    return $self->fields->find($id);

}

sub callInterface {
    my ($self, $method, $format, $path, $body, $authentication) = @_;
    $self->log->debug(to_json($body));
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
    $matcher = $self->matchers->targetMatchers($matcher);
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No valid identifier ") unless defined $matcher && $matcher && %{$matcher};
    delete $params->{marcxml};
    if ($matcher->{"028a"} && $matcher->{"028b"}) {
        $params->{identifier} = "028a|028b";
        $params->{identifier_field} = $matcher->{"028a"}.'|'.$matcher->{"028b"};
    } else {
        $params->{identifier} = join("|", map { "$_" } values %{$matcher});
        $params->{identifier_field} = join("|", map { "$_" } keys %{$matcher});
    }
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
    foreach my $result (@{$results}) {
        my $source_id;
        my $host = $self->interface->load({host => 1, type => "search"});
        my $path = $self->getSearchPath($host, {$result->{identifier_field} => $result->{identifier}});
        my $search = $self->sru->search($path);
        $search = shift @{$search};
        if ($search) {
            $source_id = $self->response->componentparts->fetchComponentParts($result->{interface_name}, undef, undef, $search);
            my $exporter = {
                interface => $result->{interface_name}, 
                target_id => $result->{target_id},
                source_id => $source_id,
                marc => $search,
                activerecord_id => $result->{id}
            };
            my $res = $self->export($exporter);
        } else {
            $self->active->updateActiveRecords($result->{id});
        }
    }
}

sub searchTarget {
    my ($self, $remote_interface, $record) = @_;

    my $search;
    my ($interface, %matchers) = $self->matchers->fetchMatchers($remote_interface, "search", "identifier");
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

sub remoteValues {
    my ($self, $interface, $biblio) = @_;

    my $remote = $self->searchTarget($interface, $biblio);
    my $data;
    my $target_id;

    if (defined $remote && ref($remote) eq 'ARRAY' && @{$remote}) {
        $remote = shift @{$remote};
        $target_id = $self->getTargetId($interface, $remote);
        $self->compare->getMandatory($biblio, $remote);
        $data = $remote;
    }

    return ($data, $target_id);
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
    $self->log->debug("Key: ".$key." value: ".$value);
    if ($key eq "020a") {
        $value =~ s/\D//g;
    }

    return $value;
}

sub search_fields {
    my ($self, $record, %matchers) = @_;

    my $matcher;
    foreach my $field (@{$record->{fields}}) {
        if (($matchers{$field->{tag}} && $field->{tag} ne '024') || ($matchers{$field->{tag}} && $field->{tag} eq '024' && $field->{ind1} eq "3")) {
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
            if (($key eq $field->{tag} && $field->{tag} ne '024') || ($key eq $field->{tag} && $field->{tag} eq '024' && $field->{ind1} eq "3") ) {
                $matcher->{$field->{tag}} = $field->{value};
            }
        }
    }

    if ($matcher->{"028a"} && $matcher->{"028b"}) {
        $matcher->{"028a|028b"} = $matcher->{"028a"}.'|'.$matcher->{"028b"};
        delete $matcher->{"028a"};
        delete $matcher->{"028b"};
    }

    return $matcher;
    
}

sub create_path {
    my ($self, $interface, $params, $query) = @_;
    my @matches = $interface->{endpoint_url} =~ /{(.*?)}/g;

    foreach my $match (@matches) {
        my $m = $params->{$match};
        $interface->{endpoint_url} =~ s/{$match}/$m/g;
    }
    if (defined $query && $query) {
        my $firstkey = (%{$query})[0];
        foreach my $q (keys %{$query}) {
            if ($firstkey eq $q) {
                $interface->{endpoint_url} = $interface->{endpoint_url}.'?'.$q.'='.$query->{$q};
            } else {
                $interface->{endpoint_url} = $interface->{endpoint_url}.'&'.$q.'='.$query->{$q};
            }
        }
    }
    return $interface->{endpoint_url};
}

sub create_query {
    my ($self, $params, $matcher) = @_;

    my $query;
    if ($matcher->{"028a|028b"}) {
        my @identifiers = split(/\|/, $matcher->{"028a|028b"});
        $matcher->{"028a"} = $identifiers[0];
        $matcher->{"028b"} = $identifiers[1];
        delete $matcher->{"028a|028b"};
    }
    foreach my $param (@{$params}) {
        if($param->{type} eq "query") {
            my @valuematch = $param->{value} =~ /{(.*?)}/g;
            if (defined $valuematch[0] && $valuematch[0] ne "028a") {
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
            if (defined $valuematch[0] && $valuematch[0] eq "028a" && defined $valuematch[1] && $valuematch[1] eq "028b") {
                $param->{value} =~ s/{$valuematch[0]}/$matcher->{$valuematch[0]}/g;
                $param->{value} =~ s/{$valuematch[1]}/$matcher->{$valuematch[1]}/g;
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
