package KohaSuomiServices::Model::Biblio::Search;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use POSIX 'strftime';
use Mojo::Log;
use Mojo::URL;
use Mojo::JSON qw(decode_json encode_json from_json to_json);
use KohaSuomiServices::Model::Exception::NotFound;
use KohaSuomiServices::Model::Exception::BadParameter;

use KohaSuomiServices::Model::Packages::Biblio;

has packages => sub {KohaSuomiServices::Model::Packages::Biblio->new};

sub callInterface {
    my ($self, $method, $format, $path, $body, $authentication) = @_;
    $self->log->debug(to_json($body));
    my $tx = $self->packages->interface->buildTX($method, $format, $path, $body, $authentication);
    return ($tx->res->code, $tx->res->body, $tx->res->error->{message}) if $tx->res->error;
    return ($tx->res->code, from_json($tx->res->body), $tx->res->headers);
}

sub searchTarget {
    my ($self, $remote_interface, $record, $source_id) = @_;

    my $search;
    my ($interface, %matchers);
    ($interface, %matchers) = $self->packages->matchers->fetchMatchers($remote_interface, "search", "identifier") if !$source_id;
    $interface = $self->packages->interface->load({name => $remote_interface, type => "get"}) if $source_id;
    if ($interface->{interface} eq "SRU" && !$source_id) {
        my $matcher = $self->search_fields($record, %matchers);
        my $path = $self->create_query($interface->{params}, $matcher);
        $path->{url} = $interface->{endpoint_url};
        $search = $self->packages->sru->search($path);
    }

    if ($interface->{interface} eq "REST" && $source_id) {
        my $authentication; #= $self->exportauth->interfaceAuthentication($interface, $export->{authuser_id}, $interface->{method});
        my $matcher = {source_id => $source_id};
        my $path = $self->create_path($interface, $matcher);
        my $tx = $self->packages->interface->buildTX($interface->{method}, $interface->{format}, $path, $authentication);
        my $body = from_json($tx->res->body);
        $body = $body->{marcxml} if $body->{marcxml};
        $body = ref($body) eq "HASH" ? $body : $self->convert->formatjson($body);
        $search = $body;
    }

    return $search;
    
}

sub remoteValues {
    my ($self, $interface, $biblio, $tag, $code) = @_;

    my $remote = $self->searchTarget($interface, $biblio);
    my $data;
    my $target_id;
    my $field_value;

    if (defined $remote && ref($remote) eq 'ARRAY' && @{$remote}) {
        $remote = shift @{$remote};
        $field_value = $self->packages->fields->findField($remote, $tag, $code) if $tag;
        $target_id = $self->getTargetId($interface, $remote);
        $self->packages->compare->getMandatory($biblio, $remote);
        $data = $remote;
    }
    if ($field_value) {
        return ($data, $target_id, $field_value);
    } else {
        return ($data, $target_id);
    }
}

sub getTargetId {
    my ($self, $remote_interface, $record) = @_;

    return unless $record;

    my $schema = $self->packages->schema->client($self->config);
    my $interface = $self->packages->interface->load({name => $remote_interface, type => "update"});
    my %matchers = $self->packages->matchers->find($schema, $interface->{id}, "identifier");

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
    $self->packages->log->debug("Key: ".$key." value: ".$value);
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
                $body->{$param->{name}} = $self->packages->convert->formatxml($matcher) if $body->{$param->{name}};
                $body = $self->packages->convert->formatxml($matcher) unless $body->{$param->{name}};
            }
            if (defined $valuematch[0] && $valuematch[0] eq "marcjson") {
                $body = $matcher;
            }
        }
    }
    return $body;
}

1;