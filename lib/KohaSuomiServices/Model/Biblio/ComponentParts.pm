package KohaSuomiServices::Model::Biblio::ComponentParts;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json from_json);

use KohaSuomiServices::Model::Exception::NotFound;

use KohaSuomiServices::Model::Packages::Biblio;

has packages => sub {KohaSuomiServices::Model::Packages::Biblio->new};

sub search {
    my ($self, $client, $params) = @_;
    return $self->packages->schema->get_columns($client->resultset('ComponentParts')->search($params));
}

sub insert {
    my ($self, $client, $params) = @_;
    return $client->resultset('ComponentParts')->new($params)->insert();
}

sub update {
    my ($self, $client, $params) = @_;
    my $id = $params->{source_id};
    unlink $params->{source_id};
    my $record = $client->resultset('ComponentParts')->find($id);
    return 0 unless $record;
    return $client->resultset('ComponentParts')->find($id)->update($params);
}

sub pushToExport {
    my ($self, $client, $remote_interface, $parent_id, $target_parent) = @_;
    my $componentParts = $self->search($client, {parent_id => $parent_id});
    my @arr = $self->getTargetsComponentParts($remote_interface, $target_parent);
    unless (@arr) {
        foreach my $componentpart (@{$componentParts}) {
            my $res = $self->packages->biblio->export({source_id => $componentpart->{source_id}, marc => from_json($componentpart->{marc}), interface => $remote_interface, parent_id => $parent_id, broadcast_record => 1});
            $self->packages->log->info("New component part export ".$res->{export}." added");
        }
    } else {
        foreach my $componentpart (@{$componentParts}) {
            my $res;
            my $targetid = shift @arr;
            if (defined $targetid && $targetid) {
                $res = $self->packages->biblio->export({target_id => $targetid, source_id => $componentpart->{source_id}, marc => from_json($componentpart->{marc}), interface => $remote_interface, parent_id => $parent_id, broadcast_record => 1});
                $self->packages->log->info("Component part ".$res->{export}." replaced");
            } else {
                $res = $self->packages->biblio->export({source_id => $componentpart->{source_id}, marc => from_json($componentpart->{marc}), interface => $remote_interface, parent_id => $parent_id, broadcast_record => 1});
                $self->packages->log->info("New component part export ".$res->{export}." added");
            }
        }
    }
}

sub exportComponentParts {
    my ($self, $parent_id, $linkvalue, $parent_datetime) = @_;
    my $schema = $self->packages->schema->client($self->packages->config);
    my @componentparts = $self->packages->exporter->find($schema, {status => "waiting", parent_id => $parent_id, timestamp => {">=" => $parent_datetime}}, undef);
    foreach my $d (@{$self->packages->schema->get_columns(@componentparts)}) {
        $self->packages->log->info("Processing componentpart ".$d->{id});
        $self->packages->fields->replaceValue($d->{id}, "773", "w", $linkvalue) if $linkvalue;
        $self->packages->exporter->update($d->{id}, {status => "pending"});
    }
}

sub find {
    my ($self, $remote_interface, $source_id) = @_;
    my $interface = $self->packages->interface->load({name => $remote_interface, type => "getcomponentparts"});
    my $search;
    my $matcher = {source_id => $source_id};
    if ($interface->{interface} eq "SRU") {
        $search = $self->sruLoopAll($interface, $matcher);
    }

    if ($interface->{interface} eq "REST") {
        $search = $self->restGetAll($interface, $matcher);
    }

    return $search;
}

sub failWithParent {
    my ($self, $parent_id, $pexport_id) = @_;

    my $schema = $self->packages->schema->client($self->packages->config);
    my @componentparts = $self->packages->exporter->find($schema, {status => "waiting", parent_id => $parent_id}, undef);
    foreach my $d (@{$self->packages->schema->get_columns(@componentparts)}) {
        $self->packages->exporter->update($d->{id}, {status => "failed", errorstatus => "Parent failed", parent_id => $pexport_id});
    }
}

sub componentpartsCount {
    my ($self, $exporter_id, $parent_id, $parent_datetime, $count_value, $broadcast) = @_;
    my $equal = 1;
    my $schema = $self->packages->schema->client($self->packages->config);
    my @componentparts = $self->packages->exporter->find($schema, {status => "waiting", parent_id => $parent_id, broadcast_record => $broadcast}, undef);
    my $length = @{$self->packages->schema->get_columns(@componentparts)};
    unless ($length == $count_value) {
        $self->packages->log->info("Missing component parts, will not process parent ". $parent_id);
        my @failedcomponentparts = $self->packages->exporter->find($schema, {status => "failed", parent_id => $parent_id, timestamp => {">=" => $parent_datetime}, broadcast_record => $broadcast}, undef);
        if (@failedcomponentparts) {
            $self->packages->exporter->update($exporter_id, {status => "failed", errorstatus => "Component parts failed"});
        }
        $equal = 0;
    }
    if ($length == $count_value && $broadcast) {
        my @componentparts = $self->packages->exporter->find($schema, {status => "waiting", parent_id => $parent_id, timestamp => {">=" => $parent_datetime}, broadcast_record => $broadcast}, undef);
        foreach my $componentpart (@{$self->packages->schema->get_columns(@componentparts)}) {
            $self->packages->exporter->update($componentpart->{id}, {status => "pending"});
        }
    }
    return $equal;
}

sub fetchComponentParts {
    my ($self, $remote_interface, $fetch_interface, $source_id, $search) = @_;
    my $host = $self->packages->interface->host("add");
    my $interface = $self->packages->interface->load({name => $remote_interface, type => "add"});
    if (defined $search && $search && !$source_id) {
        $source_id = $self->getSourceId($host->{name}, $search);
        $self->packages->log->info("Source id: ".$source_id);
        $remote_interface = $host->{name};
    }
    my $get_interface = defined $fetch_interface && $fetch_interface ? $fetch_interface : $remote_interface;
    my $results = $self->find($get_interface, $source_id);
    $self->packages->log->info("Component parts not found from ".$get_interface. " for ".$source_id) unless defined $results && $results;
    foreach my $result (@{$results}) {
        my $marc = $result->{marcxml} ? $self->packages->convert->formatjson($result->{marcxml}) : $result;
        my $sourceid = $result->{biblionumber} ? $result->{biblionumber} : $self->packages->search->getTargetId($get_interface, $result);
        my $res = $self->packages->biblio->export({source_id => $sourceid, marc => $marc, interface => $interface->{name}});
        $self->packages->log->info("Component part ".$res->{export}." fetched");
    }
    return $source_id;
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
        my $path = $self->packages->search->create_query($interface->{params}, $matcher);
        $path->{url} = $interface->{endpoint_url};
        my $results = $self->packages->sru->search($path);
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

sub restGetAll {
    my ($self, $interface, $matcher) = @_;

    my $authentication = $self->packages->exportauth->authorize($interface);
    my $path = $self->packages->search->create_path($interface, $matcher);
    my $tx = $self->packages->interface->buildTX($interface->{method}, $interface->{format}, $path, $authentication);
    $self->packages->log->error($interface->{name}." REST error: ". $tx->res->message) if $tx->res->error;
    return if $tx->res->error;
    my $body = from_json($tx->res->body);
    if ($body->{componentparts}) {
        return $body->{componentparts};
    }
}

sub getSourceId {
    my ($self, $remote_interface, $search) = @_;

    my ($interface, %matchers) = $self->packages->matchers->fetchMatchers($remote_interface, "getcomponentparts", "identifier");
    $self->packages->log->info("No identifier defined for getcomponentparts ".$remote_interface) unless %matchers;
    my $identifiers = $self->packages->search->getIdentifier($search, %matchers);
    my $identifier;
    if (ref($identifiers) eq "ARRAY") {
        $identifier = @{$identifiers}[0];
    } else {
        $identifier = $identifiers;
    }
    return $identifier;
}

sub replaceComponentParts {
    my ($self, $remote_interface, $target_id, $source_id) = @_;

    my @arr = $self->getTargetsComponentParts($remote_interface, $target_id);
    my $host = $self->packages->interface->host("update");
    my $results = $self->find($host->{name}, $source_id);
    $self->packages->log->info("Component parts not found from ".$remote_interface. " for ".$source_id) unless defined $results && $results;
    unless (@arr) {
        foreach my $result (@{$results}) {
            my $marc = $result->{marcxml} ? $self->packages->convert->formatjson($result->{marcxml}) : $result;
            my $sourceid = $result->{biblionumber} ? $result->{biblionumber} : $self->biblio->search->getTargetId($host->{name}, $result);
            my $res = $self->packages->biblio->export({source_id => $sourceid, marc => $marc, interface => $remote_interface});
            $self->packages->log->info("New component part ".$res->{export}." added");
        }
    } else {
        foreach my $result (@{$results}) {
            my $marc = $result->{marcxml} ? $self->packages->convert->formatjson($result->{marcxml}) : $result;
            my $targetid = shift @arr;
            if (defined $targetid && $targetid) {
                my $sourceid = $result->{biblionumber} ? $result->{biblionumber} : $self->biblio->search->getTargetId($host->{name}, $result);
                my $res = $self->packages->biblio->export({source_id => $sourceid, target_id => $targetid, marc => $marc, interface => $remote_interface});
                $self->packages->log->info("Component part ".$res->{export}." replaced");
            } else {
                last;
            }

        }
    }

}

sub getTargetsComponentParts {
    my ($self, $remote_interface, $target_id) = @_;

    my $results = $self->find($remote_interface, $target_id);
    $self->packages->log->info("Component parts not found from ".$remote_interface. " for ".$target_id) unless defined $results && $results;
    my @arr;
    foreach my $result (@{$results}) {
        if (defined $result->{biblionumber} && $result->{biblionumber}) {
            push @arr, $result->{biblionumber};
        }
    }

    return @arr;
}

sub deleteTargetsComponentParts {
    my ($self, $remote_interface, $target_id) = @_;

    my $results = $self->find($remote_interface, $target_id);
    $self->packages->log->info("Component parts not found from ".$remote_interface. " for ".$target_id) unless defined $results && $results;
    return 0 unless defined $results && $results;
    foreach my $result (@{$results}) {
        if (defined $result->{biblionumber} && $result->{biblionumber}) {
            my $interface = $self->packages->interface->load({name => $remote_interface, type => "delete"});
            my $authentication = $self->packages->exportauth->authorize($interface);
            my $path = $self->packages->search->create_path($interface, {target_id => $result->{biblionumber}});
            my ($resCode, $resBody, $resHeaders) = $self->packages->search->callInterface($interface->{method}, $interface->{format}, $path, undef, $authentication, undef);
        }
    }
    return 1;
}

1;