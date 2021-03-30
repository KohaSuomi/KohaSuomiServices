package KohaSuomiServices::Model::Biblio::Fields;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);
use KohaSuomiServices::Model::Biblio::Subfields;
use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;

has schema => sub {KohaSuomiServices::Database::Client->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has subfields => sub {KohaSuomiServices::Model::Biblio::Subfields->new};
has exporter => sub {KohaSuomiServices::Model::Biblio::Exporter->new};

sub store {
    my ($self, $exporter_id, $parent_id, $record) = @_;

    my $client = $self->schema->client($self->config);
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No fields defined") unless @{$record->{fields}};
    my $leader = $self->insert($client, {exporter_id => $exporter_id, type => "leader", value => $record->{leader}});
    foreach my $field (@{$record->{fields}}) {
        my $data = $self->insert($client, $self->parse($exporter_id, $field));
        foreach my $subfield (@{$field->{subfields}}) {
            $self->subfields->insert($client, $self->parse($data->id, $subfield));
        }
    }
    $self->exporter->update($exporter_id, {status => "pending"}) unless defined $parent_id && $parent_id;
}

sub insert {
    my ($self, $client, $field) = @_;
    return $client->resultset('Fields')->create($field);
}

sub update {
    my ($self, $client, $id, $params) = @_;
    return $client->resultset('Fields')->find($id)->update($params);
}

sub find {
    my ($self, $id, %matcher) = @_;
    
    my $client = $self->schema->client($self->config);
    my @data = $client->resultset('Fields')->search({exporter_id => $id});
    my $format;
    my @fields;
    foreach my $field (@{$self->schema->get_columns(@data)}) {
        if ($field->{type} eq "leader") {
            $format->{leader} = $field->{value};
        } else {
            my $hash;
            unless (defined $matcher{$field->{tag}} && !$matcher{$field->{tag}}) {
                $hash->{tag} = $field->{tag};
                $hash->{value} = $field->{value} if ($field->{type} eq "controlfield");
                $hash->{ind1} = $field->{ind1} if ($field->{type} eq "datafield");
                $hash->{ind2} = $field->{ind2} if ($field->{type} eq "datafield");
                $hash->{subfields} = $self->subfields->find($client, $field->{id}) if ($field->{type} eq "datafield");
                if (defined $matcher{$field->{tag}} && $matcher{$field->{tag}}) {
                    my $index = 0;
                    foreach my $subfield (@{$hash->{subfields}}) {
                        if ($matcher{$field->{tag}} eq $subfield->{code}) {
                            delete $hash->{subfields}[$index];
                        }
                        $index++;
                    }
                }
                push @fields, $hash;
            }
        }
    }
    $format->{fields} = \@fields;
    return $format;
}

sub findValue {
    my ($self, $id, $tag, $code) = @_;
    my $client = $self->schema->client($self->config);
    my @data = $client->resultset('Fields')->search({exporter_id => $id, tag => $tag});
    my $return;
    foreach my $field (@{$self->schema->get_columns(@data)}) {
        if (defined $code && $code) {
            my $subfields = $self->subfields->findAll($client, $field->{id});
            foreach my $subfield (@{$subfields}) {
                if (defined $subfield && $subfield->{code} eq $code) {
                    $return = $subfield->{value};
                }
            }
        }
        $return = $field->{value};
    }
    
    return $return;
}

sub replaceValue {
    my ($self, $id, $tag, $code, $newvalue) = @_;
    my $client = $self->schema->client($self->config);
    my @data = $client->resultset('Fields')->search({exporter_id => $id});
    foreach my $field (@{$self->schema->get_columns(@data)}) {
        if (defined $code && $code && $field->{type} eq "datafield") {
            my $subfields = $self->subfields->findAll($client, $field->{id});
            foreach my $subfield (@{$subfields}) {
                if (defined $subfield && $subfield->{code} eq $code) {
                    $self->subfields->update($client, $subfield->{id}, {value => $newvalue});
                    return;
                }
            }
        }
        if ($field->{tag} eq $tag && $field->{type} eq "controlfield") {
            $self->update($client, $field->{id}, {value => $newvalue});
            return;
        }
    }
}

sub findField {
    my ($self, $biblio, $tag, $code) = @_;

    my $value;

    foreach my $field (@{$biblio->{fields}}) {
        if ($field->{tag} eq $tag) {
            if ($field->{subfields} && $code) {
                foreach my $subfield (@{$field->{subfields}}) {
                    if ($subfield->{code} eq $code) {
                        $value = $subfield->{value};
                        last;
                    }
                }
            } else {
                $value = $field->{value};
                last;
            }
        }
    }

    return $value;
}

sub parse {
    my ($self, $id, $field) = @_;
    my $params;
    if (defined $field->{value}) {
        $params = {exporter_id => $id, tag => $field->{tag}, value => $field->{value}, type => "controlfield"};
    } else {
        $params = {exporter_id => $id, tag => $field->{tag}, ind1 => $field->{ind1}, ind2 => $field->{ind2}, type => "datafield"};
    }
    if (defined $field->{code}) {
        $params = {field_id => $id, code => $field->{code}, value => defined $field->{value} ? $field->{value} : ""};
    }

    return $params;
}

1;