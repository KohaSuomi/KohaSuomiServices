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
use KohaSuomiServices::Model::Biblio::Search;

has schema => sub {KohaSuomiServices::Database::Client->new};
has sru => sub {KohaSuomiServices::Model::SRU->new};
has interface => sub {KohaSuomiServices::Model::Biblio::Interface->new};
has search => sub {KohaSuomiServices::Model::Biblio::Search->new};
has fields => sub {KohaSuomiServices::Model::Biblio::Fields->new};
has matchers => sub {KohaSuomiServices::Model::Biblio::Matcher->new};
has active => sub {KohaSuomiServices::Model::Biblio::ActiveRecords->new};
has exporter => sub {KohaSuomiServices::Model::Biblio::Exporter->new};
has exportauth => sub {KohaSuomiServices::Model::Biblio::ExportAuth->new};
has response => sub {KohaSuomiServices::Model::Biblio::Response->new};
has convert => sub {KohaSuomiServices::Model::Convert->new};
has compare => sub {KohaSuomiServices::Model::Compare->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has log => sub {Mojo::Log->new(path => KohaSuomiServices::Model::Config->new->load->{"logs"}, level => KohaSuomiServices::Model::Config->new->load->{"log_level"})};

sub export {
    my ($self, $params) = @_;

    my $schema = $self->schema->client($self->config);
    my $abort = 0;
    my $errormessage;

    $params->{marc} = ref($params->{marc}) eq "HASH" ? $params->{marc} : $self->convert->formatjson($params->{marc});

    if ($params->{check} || ($params->{check} && $params->{parent_id})) {
        my ($modified_marc, $target_id, $remote_value) = $self->search->remoteValues($params->{interface}, $params->{marc}, "005", undef);
        
        my $encoding_level = $self->compare->encodingLevelCompare($params->{marc}->{leader}, $modified_marc->{leader});
        if ($encoding_level eq 'lower') {
            $abort = 1;
            $errormessage = 'Lower encoding level';
        } else {
            $params->{target_id} = $target_id if $params->{check} && $params->{parent_id} && $target_id;
            my $export_value = $self->fields->findField($params->{marc}, "005", undef);
            $abort = 1 if $self->compare->intCompare($export_value, $remote_value) && $encoding_level ne 'greater';
            $errormessage = 'Older record';
        }
        
    }

    my $interface = defined $params->{target_id} && $params->{target_id} ? $self->interface->load({name => $params->{interface}, type => "update"}) : $self->interface->load({name => $params->{interface}, type => "add"}); 
    my $type = defined $params->{target_id} && $params->{target_id} ? "update" : "add";
    my $authuser = $self->exportauth->checkAuthUser($schema, $params->{username}, $interface->{id});

    my $exporter;
    unless ($abort) {
        $exporter = $self->exporter->setExporterParams($interface, $type, "waiting", $params->{source_id}, $params->{target_id}, $authuser, $params->{parent_id}, $params->{force}, $params->{componentparts}, $params->{fetch_interface}, $params->{activerecord_id}, "", $params->{componentparts_count});
    } else {
        $exporter = $self->exporter->setExporterParams($interface, $type, "failed", $params->{source_id}, $params->{target_id}, $authuser, $params->{parent_id}, $params->{force}, $params->{componentparts}, $params->{fetch_interface}, $params->{activerecord_id}, $errormessage, $params->{componentparts_count});
    }

    my $data = $self->exporter->insert($schema, $exporter);
    $self->fields->store($data->id, $params->{parent_id}, $params->{marc});

    return {export => $data->id, message => "Success"};
    
}

sub broadcast {
    my ($self, $params) = @_;
    
    $self->log->debug(Data::Dumper::Dumper $params);
    my %matchers = $self->matchers->defaultSearchMatchers();
    my $schema = $self->schema->client($self->config);
    my @controlkey;
    foreach my $ckey (keys %matchers) {
        if ($ckey eq "003") {
            $controlkey[0] = $ckey;
            delete $matchers{"003"};
        }
        if ($ckey eq "001") {
            $controlkey[1] = $ckey;
            delete $matchers{"001"};
        }
    }
    $matchers{$controlkey[0].'|'.$controlkey[1]} = {"" => "FI-BTJ"};
    while (my ($key, $value) = each %matchers) {
        my %matcher;
        $matcher{$key} = $value;

        if($key =~ /\|/) {
            my ($f003,$f001) = split(/\|/, $key);
            $matcher{$f003} = $value;
            $matcher{$f001} = "";
            delete $matcher{"003|001"};
        }
        
        my $identifier = $self->search->getIdentifier($params->{marc}, %matcher);
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
        if ($export->{componentparts_count}) {
            my $equal = $self->response->componentparts->componentpartsCount($export->{source_id}, $export->{componentparts_count});
            next unless $equal;
        }
        my $interface = $self->interface->load({id=> $export->{interface_id}}, $export->{force_tag});
        if ($export->{componentparts} && $export->{fetch_interface}) {
            $self->response->componentparts->fetchComponentParts($interface->{name}, $export->{fetch_interface}, $export->{source_id}, undef);
        }
        my $query = $self->search->create_query($interface->{params});
        my $path = $self->search->create_path($interface, $export, $query);
        my %removeMatchers = $self->matchers->removeMatchers($interface->{id});
        my $data = $self->fields->find($export->{id}, %removeMatchers);
        $data = $self->matchers->modifyFields($export->{interface_id}, $export->{id}, $data);
        if ($type eq "update" && $export->{target_id}) {
            my $remote = $self->search->searchTarget($interface->{name}, undef, $export->{target_id});
            my $diff = $self->compare->getDiff($remote, $data);
            $self->exporter->update($export->{id}, {diff => $diff});
        }
        my $body = $self->search->create_body($interface->{params}, $data);
        my $headers = $self->search->create_headers($interface->{params});
        my $authentication = $self->exportauth->interfaceAuthentication($interface, $export->{authuser_id}, $interface->{method});
        my ($resCode, $resBody, $resHeaders) = $self->search->callInterface($interface->{method}, $interface->{format}, $path, $body, $authentication, $headers);
        if ($resCode eq "200" || $resCode eq "201") {
            $self->exporter->update($export->{id}, {status => "success", errorstatus => ""});
            $self->response->getAndUpdate($interface, $resBody, $resHeaders, $export->{source_id}, $type);
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

    $self->exporter->update($id, {status => "pending", force_tag => 1, timestamp => \'NOW()'});
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
    my ($self, $interface_name, $status, $page, $rows) = @_;
    
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
    my $params = $status ? [{interface_id => $add_id, status => $status}, {interface_id => $update_id, status => $status}] : [{interface_id => $add_id}, {interface_id => $update_id}];
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

sub getLastActive {
    my ($self, $interface) = @_;
    my $schema = $self->schema->client($self->config);
    my $last = $self->active->findLast($schema, {interface_name => $interface});
    if ($last) {
       $last = pop @{$last};
       return {target_id => $last->{target_id}};
    } else {
       return {target_id => 1};
    }
    
}

sub addActive {
    my ($self, $params) = @_;
    
    
    my $schema = $self->schema->client($self->config);
    my %matchers = $self->matchers->defaultSearchMatchers();
    my $record = $self->convert->formatjson($params->{marcxml});
    my $matcher = $self->search->search_fields($record, %matchers);
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
    my $exist = $self->active->find($schema, {target_id => $params->{target_id}, interface_name => $params->{interface_name}});
    unless (@{$exist}) {
        $self->active->insert($schema, $params);
        return {message => "Success"};
    } else {
        my $newweight = $self->matchers->weightMatchers($params->{identifier_field});
        $exist = shift @{$exist};
        my $activeweight = $self->matchers->weightMatchers($exist->{identifier_field});
        if ($newweight < $activeweight) {
            $self->active->update($schema, $exist->{id}, {identifier_field => $params->{identifier_field}, identifier => $params->{identifier}});
            return {message => "Active record updated"};
        } else {
            return {message => "Already exists"};
        }     
    }
}

sub updateActive {
    my ($self, @interfaces) = @_;
    
    my $schema = $self->schema->client($self->config);
    my $dt = strftime "%Y-%m-%d 00:00:00", ( localtime(time) );
    my $params = @interfaces ? {updated => undef, created => {">=" => $dt}, interface_name => \@interfaces} : {updated => undef, created => {">=" => $dt}};
    my $results = $self->active->find($schema, $params);
    foreach my $result (@{$results}) {
        $self->active->updateActiveRecords($result->{id});
        my $source_id;
        my $host = $self->interface->load({host => 1, type => "search"});
        my $path = $self->search->getSearchPath($host, {$result->{identifier_field} => $result->{identifier}});
        my $search = $self->sru->search($path);
        $search = shift @{$search};
        if ($search) {
            my $abort = 0;
            my $remote = $self->search->searchTarget($result->{interface_name}, $search, $result->{target_id});
            my $encoding_level = $self->compare->encodingLevelCompare($search->{leader}, $remote->{leader});
            $abort = 1 if $encoding_level eq 'lower';
            $abort = $self->compare->intCompare($self->fields->findField($search, "005", undef), $self->fields->findField($remote, "005", undef)) if $encoding_level eq 'equal';
            unless ($abort) {
                my $hascomponentparts = $self->response->componentparts->deleteTargetsComponentParts($result->{interface_name}, $result->{target_id});
                $source_id = $self->response->componentparts->fetchComponentParts($result->{interface_name}, undef, undef, $search);
                my $exporter = {
                    interface => $result->{interface_name}, 
                    target_id => $result->{target_id},
                    source_id => $source_id,
                    marc => $search,
                    activerecord_id => $result->{id}
                };
                my $res = $self->export($exporter);
            }
        }
    }
}

sub copyInterface {
    my ($self, $interfacename, $copy, $type) = @_;

    my $schema = $self->schema->client($self->config);
    my $interface = $self->interface->find({name => $interfacename, type => $type});
    $interface = pop @{$interface};

    my $old_interface_id = $interface->{id};
    delete $interface->{id};
    $interface->{name} = $copy;
    $interface->{host} = 0;

    my $newinterface = $schema->resultset("Interface")->new($interface)->insert();

    my $parameters = $self->interface->parameter->find({interface_id => $old_interface_id});
    foreach my $parameter (@{$parameters}) {
        delete $parameter->{id};
        $parameter->{interface_id} = $newinterface->id;
        $schema->resultset("Parameter")->new($parameter)->insert();
    }

    my @exportauthlist = $schema->resultset('AuthUsers')->search({interface_id => $old_interface_id});
    my $exportauths = $self->schema->get_columns(@exportauthlist);
    foreach my $exportauth (@{$exportauths}) {
        my @userlinkslist = $schema->resultset('UserLinks')->search({interface_id => $old_interface_id, authuser_id => $exportauth->{id}});
        my $userlinks = $self->schema->get_columns(@userlinkslist);
        delete $exportauth->{id};
        $exportauth->{interface_id} = $newinterface->id;
        my $newauth = $schema->resultset("AuthUsers")->new($exportauth)->insert();
        foreach my $userlink (@{$userlinks}) {
            delete $userlink->{id};
            $userlink->{authuser_id} = $newauth->id;
            $userlink->{interface_id} = $newinterface->id;
            $schema->resultset("UserLinks")->new($userlink)->insert();
        }
    }

    my @responseslist = $schema->resultset('Response')->search({interface_id => $old_interface_id});
    my $responses = $self->schema->get_columns(@responseslist);
    foreach my $response (@{$responses}) {
        delete $response->{id};
        $response->{interface_id} = $newinterface->id;
        $schema->resultset("Response")->new($response)->insert();
    }

    my @matcherslist = $schema->resultset('Matcher')->search({interface_id => $old_interface_id});
    my $matchers = $self->schema->get_columns(@matcherslist);
    foreach my $matcher (@{$matchers}) {
        delete $matcher->{id};
        $matcher->{interface_id} = $newinterface->id;
        $schema->resultset("Matcher")->new($matcher)->insert();
    }
    
    print "Created $copy $type interface successfully\n";
}

1;
