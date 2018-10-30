package KohaSuomiServices::Model::Biblio::Subfields;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);

has schema => sub {KohaSuomiServices::Database::Client->new};

sub find {
    my ($self, $client, $id) = @_;

    try {
        my @data = $client->resultset('Subfields')->search({field_id => $id}, {columns => [qw/code value/]});
        return $self->schema->get_columns(@data);
    } catch {
        my $e = $_;
        return $e;
    }
}

sub insert {
    my ($self, $client, $field) = @_;

    try {
        my $data = $client->resultset('Subfields')->new($field)->insert();
        return $data;
    } catch {
        my $e = $_;
        return $e;
    }
}

1;