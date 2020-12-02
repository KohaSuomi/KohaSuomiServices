package KohaSuomiServices::Model::Biblio::Subfields;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);

has schema => sub {KohaSuomiServices::Database::Client->new};

sub find {
    my ($self, $client, $id) = @_;
    my @data = $client->resultset('Subfields')->search({field_id => $id}, {columns => [qw/code value/]});
    foreach my column ($self->schema->get_columns(@data)) {
        print Data::Dumper::Dumper $column;
    }
    return $self->schema->get_columns(@data);
}

sub findAll {
    my ($self, $client, $id) = @_;
    my @data = $client->resultset('Subfields')->search({field_id => $id});
    return $self->schema->get_columns(@data);
}

sub insert {
    my ($self, $client, $field) = @_;
    my $data = $client->resultset('Subfields')->new($field)->insert();
    return $data;
}

sub update {
    my ($self, $client, $id, $params) = @_;
    return $client->resultset('Subfields')->find($id)->update($params);
}

1;