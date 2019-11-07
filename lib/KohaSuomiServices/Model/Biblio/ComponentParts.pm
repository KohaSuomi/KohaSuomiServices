package KohaSuomiServices::Model::Biblio::ComponentParts;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json from_json);

use KohaSuomiServices::Model::Exception::NotFound;

use KohaSuomiServices::Model::Packages::Biblio;

has packages => sub {KohaSuomiServices::Model::Packages::Biblio->new};

sub exportComponentParts {
    my ($self, $parent_id, $linkvalue) = @_;
    my $schema = $self->packages->schema->client($self->config);
    my @componentparts = $self->packages->exporter->find($schema, {status => "waiting", parent_id => $parent_id}, undef);
    foreach my $d (@{$self->packages->schema->get_columns(@componentparts)}) {
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

    my $schema = $self->packages->schema->client($self->config);
    my @componentparts = $self->packages->exporter->find($schema, {status => "waiting", parent_id => $parent_id}, undef);
    foreach my $d (@{$self->packages->schema->get_columns(@componentparts)}) {
        $self->packages->exporter->update($d->{id}, {status => "failed", errorstatus => "Parent failed", parent_id => $pexport_id});
    }
}

sub fetchComponentParts {
    my ($self, $remote_interface, $fetch_interface, $source_id, $search) = @_;
    my $host = $self->packages->interface->host("add");
    my $interface = $self->packages->interface->load({name => $remote_interface, type => "add"});
    if (defined $search && !$source_id) {
        $source_id = $self->getSourceId($host->{name}, $search);
        $self->packages->log->info("Source id: ".$source_id);
        $remote_interface = $host->{name};
    }
    my $results = defined $fetch_interface && $fetch_interface ? $self->find($fetch_interface, $source_id) : $self->find($remote_interface, $source_id);
    $self->packages->log->info("Component parts not found from ".$remote_interface. " for ".$source_id) unless defined $results && $results && !$fetch_interface;
    $self->packages->log->info("Component parts not found from ".$fetch_interface. " for ".$source_id) unless defined $results && $results && $fetch_interface;
    foreach my $result (@{$results}) {
        my $marc = $result->{marcxml} ? $self->biblio->convert->formatjson($result->{marcxml}) : $result;
        my $sourceid = $result->{biblionumber} ? $result->{biblionumber} : $self->packages->search->getTargetId($remote_interface, $result);
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

    my $authentication; #= $self->packages->exportauth->interfaceAuthentication($interface, $export->{authuser_id}, $interface->{method});
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
    return $self->packages->search->getIdentifier($search, %matchers);
}

sub replaceComponentParts {
    my ($self, $remote_interface, $target_id, $source_id) = @_;

    my @arr = $self->getTargetsComponentParts($remote_interface, $target_id);
    return unless @arr;
    my $host = $self->packages->interface->host("update");
    my $results = $self->find($host->{name}, $source_id);
    $self->packages->log->info("Component parts not found from ".$remote_interface. " for ".$source_id) unless defined $results && $results;
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

1;