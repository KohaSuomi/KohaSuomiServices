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

    try {
        my $client = $self->schema->client($self->config);
        my $leader = $self->insert($client, {exporter_id => $exporter_id, type => "leader", value => $record->{leader}});
        foreach my $field (@{$record->{fields}}) {
            my $data = $self->insert($client, $self->parse($exporter_id, $field));
            foreach my $subfield (@{$field->{subfields}}) {
                $self->subfields->insert($client, $self->parse($data->id, $subfield));
            }
        }
    } catch {
        my $e = $_;
        warn Data::Dumper::Dumper $e->{message};
        return $e;
    }
}

sub insert {
    my ($self, $client, $field) = @_;

    try {
        return $client->resultset('Fields')->new($field)->insert();
    } catch {
        my $e = $_;
        return $e;
    }
}

sub parse {
    my ($self, $id, $field) = @_;
    my $params;
    if (defined $field->{value}) {
        $params = {exporter_id => $id, tag => $field->{tag}, value => $field->{value}, type => "controlfield"};
    } else {
        $params = {exporter_id => $id, tag => $field->{tag}, ind1 => $field->{ind1}, ind2 => $field->{ind2}, type => "datafield"};
    }
    if ($field->{code}) {
        $params = {field_id => $id, code => $field->{code}, value => $field->{value}};
    }

    return $params;
}

1;