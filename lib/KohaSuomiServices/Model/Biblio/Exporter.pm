package KohaSuomiServices::Model::Biblio::Exporter;
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


sub find {
    my ($self, $client, $params) = @_;
    return $client->resultset('Exporter')->search($params);
}

sub insert {
    my ($self, $client, $params) = @_;
    return $client->resultset('Exporter')->new($params)->insert();
}

sub getUpdate {
    my ($self) = @_;

    my $schema = $self->schema->client($self->config);
    my @data = $self->find($schema, {type => "update", status => "pending"});
    return $self->schema->get_columns(@data);

}

sub getAdd {
    my ($self) = @_;

    my $schema = $self->schema->client($self->config);
    my @data = $self->find($schema, {type => "add", status => "pending"});
    return $self->schema->get_columns(@data);
    
}

1;