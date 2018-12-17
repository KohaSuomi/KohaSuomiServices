package KohaSuomiServices::Model::Biblio::ActiveRecords;
use Mojo::Base -base;

use Modern::Perl;
use utf8;
use Try::Tiny;

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;

has schema => sub {KohaSuomiServices::Database::Client->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};


sub find {
    my ($self, $client, $params) = @_;
    return $self->schema->get_columns($client->resultset('ActiveRecords')->search($params));
}

sub insert {
    my ($self, $client, $params) = @_;
    return $client->resultset('ActiveRecords')->new($params)->insert();
}

sub update {
    my ($self, $client, $id, $params) = @_;
    return $client->resultset('ActiveRecords')->find($id)->update($params);
}


1;