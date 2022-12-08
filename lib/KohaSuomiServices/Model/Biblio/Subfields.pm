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
    my @return;
    foreach my $columns ($self->schema->get_columns(@data)) {
        my @modified;
        foreach my $column (@{$columns}) {
            if ($column->{value} eq ''){
                delete $column->{value}
            }
            push @modified, $column;
        }
        push @return, @modified;
    }

    return \@return;
}

sub findAll {
    my ($self, $client, $id) = @_;
    my @data = $client->resultset('Subfields')->search({field_id => $id});
    return $self->schema->get_columns(@data);
}

sub insert {
    my ($self, $client, $field) = @_;
    my $data = $client->resultset('Subfields')->create($field);
    return $data;
}

sub update {
    my ($self, $client, $id, $params) = @_;
    return $client->resultset('Subfields')->find($id)->update($params);
}

1;
