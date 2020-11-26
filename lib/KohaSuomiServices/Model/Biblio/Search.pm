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
    $self->packages->log->debug(to_json($body)) if defined $body && $body;
    my $tx = $self->packages->interface->buildTX($method, $format, $path, $body, $authentication);
    
    return ($tx->res->code, $tx->res->body, $tx->res->error->{message}) if $tx->res->error;
    if ($tx->res->body ne '') {
        return ($tx->res->code, from_json($tx->res->body), $tx->res->headers);    
    } else {
        return ($tx->res->code, "Success", $tx->res->headers);
    }
}

sub searchTarget {
    my ($self, $remote_interface, $record, $source_id) = @_;

    my $search;
    my ($interface, %matchers);
    ($interface, %matchers) = $self->packages->matchers->fetchMatchers($remote_interface, "search", "identifier") if !$source_id;
    $interface = $self->packages->interface->load({name => $remote_interface, type => "get"}) if $source_id;
    if ($interface->{interface} eq "SRU" && !$source_id) {
        my $matcher = $self->search_fields($record, %matchers);
        my $path;       
        if(to_json($matcher) ne "{}") {

            $path = $self->create_query($interface->{params}, $matcher);
            $path->{url} = $interface->{endpoint_url};
            $search = $self->packages->sru->search($path);
        }
        else {
            my $tag = "024";
            my @matcher_array = $self->search_024_fields($record, $tag ,%matchers);
            my $value_count =  scalar @matcher_array;
            my $ii = 0;
            $tag=$tag."a";            
            while($ii < $value_count && !$search->[0]) {
                my %matcher24;
                ($interface, %matchers) = $self->packages->matchers->fetchMatchers($remote_interface, "search", "identifier") if !$source_id;
                $matcher24{$tag} = $matcher_array[$ii];
                $path = $self->create_query($interface->{params}, \%matcher24);
                $path->{url} = $interface->{endpoint_url};
                try {
                        $search = $self->packages->sru->search($path);
                }
                catch {
                        $search = undef;
                };
                $ii++;
            }
        }
    }

    if ($interface->{interface} eq "REST" && $source_id) {
        my $path = $self->create_path($interface, {source_id => $source_id});
        my ($resCode, $resBody, $resHeaders) = $self->callInterface($interface->{method}, $interface->{format}, $path, undef, undef);
        $resBody = $resBody->{marcxml} if $resBody->{marcxml};
        $resBody = ref($resBody) eq "HASH" ? $resBody : $self->packages->convert->formatjson($resBody);
        $search = $resBody;
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

    my $schema = $self->packages->schema->client($self->packages->config);
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
        if ($matchers{$field->{tag}} && $field->{tag} ne '024') {
            foreach my $subfield (@{$field->{subfields}}) {
                if (ref($matchers{$field->{tag}}) eq "ARRAY") {
                    foreach my $code (@{$matchers{$field->{tag}}}) {
                        if ($subfield->{code} eq $code) {
                            $matcher->{$field->{tag}.$code} = $subfield->{value} unless $matcher->{$field->{tag}.$code};
                        }
                    }
                }
                if (ref($matchers{$field->{tag}}) eq "HASH") {
                    my @keys = keys % { $matchers{$field->{tag}} };
                    if ($subfield->{code} eq $keys[0] && $subfield->{value} =~ /$matchers{$field->{tag}}->{$keys[0]}/) {
                        $matcher->{$field->{tag}.$keys[0]} = $subfield->{value} unless $matcher->{$field->{tag}.$keys[0]};
                    }
                    
                }
                if ($subfield->{code} eq $matchers{$field->{tag}}) {
                    $matcher->{$field->{tag}.$matchers{$field->{tag}}} = $subfield->{value} unless $matcher->{$field->{tag}.$matchers{$field->{tag}}};
                }
            }
        } else {
            my ($key, $value) = %matchers;
            if ($key eq $field->{tag} && $field->{tag} ne '024') {
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

#######################################
#collect all 024a values to an array
sub search_024_fields {
    my ($self,$record, $tag, %matchers) = @_;

    my @matcher_array;
    my $value_counter=0;
    my $record_tag;
   
    foreach my $field (@{$record->{fields}}) {
        $record_tag = $field->{tag};
        $record_tag =~ s/^\s+|\s+$//g;

        if ($record_tag eq $tag) {
            foreach my $subfield (@{$field->{subfields}}) {
                if ($subfield->{code} eq "a") {
                    $matcher_array[$value_counter] = $subfield->{value};
                    $value_counter++;
                }
            }
        }     
    }
   
    return @matcher_array;
    
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
            if (defined $valuematch[0]) {
                my ($key, $value) = %{$matcher} if $matcher;
                if ($valuematch[0] eq "028a" && $matcher->{$valuematch[0]} && $valuematch[1] eq "028b" && $matcher->{$valuematch[1]}) {
                    $param->{value} =~ s/{$valuematch[0]}/$matcher->{$valuematch[0]}/g;
                    $param->{value} =~ s/{$valuematch[1]}/$matcher->{$valuematch[1]}/g;
                } elsif ($matcher->{$valuematch[0]}) {
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