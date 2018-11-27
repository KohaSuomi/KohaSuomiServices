package KohaSuomiServices::Model::Biblio::Fields;
use Mojo::Base -base;

use Modern::Perl;

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

sub store {
    my ($self, $exporter_id, $record) = @_;

    my $client = $self->schema->client($self->config);
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No fields defined") unless @{$record->{fields}};
    my $leader = $self->insert($client, {exporter_id => $exporter_id, type => "leader", value => $record->{leader}});
    foreach my $field (@{$record->{fields}}) {
        my $data = $self->insert($client, $self->parse($exporter_id, $field));
        foreach my $subfield (@{$field->{subfields}}) {
            $self->subfields->insert($client, $self->parse($data->id, $subfield));
        }
    }
}

sub insert {
    my ($self, $client, $field) = @_;
    return $client->resultset('Fields')->new($field)->insert();
}

sub find {
    my ($self, $id) = @_;
    
    my $client = $self->schema->client($self->config);
    my @data = $client->resultset('Fields')->search({exporter_id => $id});
    my $format;
    my @fields;
    foreach my $field (@{$self->schema->get_columns(@data)}) {
        if ($field->{type} eq "leader") {
            $format->{leader} = $field->{value};
        } else {
            my $hash;
            $hash->{tag} = $field->{tag};
            $hash->{value} = $field->{value} if ($field->{type} eq "controlfield");
            $hash->{ind1} = $field->{ind1} if ($field->{type} eq "datafield");
            $hash->{ind2} = $field->{ind2} if ($field->{type} eq "datafield");
            $hash->{subfields} = $self->subfields->find($client, $field->{id}) if ($field->{type} eq "datafield");
            push @fields, $hash;
        }
    }
    $format->{fields} = \@fields;
    return $format;
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
        $params = {field_id => $id, code => $field->{code}, value => $field->{value}};
    }

    return $params;
}

1;