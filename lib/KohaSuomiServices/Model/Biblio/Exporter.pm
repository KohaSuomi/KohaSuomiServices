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
    try {
        return $client->resultset('Exporter')->search($params);
    } catch {
        my $e = $_;
        return $e;
    }
}

sub insert {
    my ($self, $client, $params) = @_;
    try {
        return $client->resultset('Exporter')->new($params)->insert();
    } catch {
        my $e = $_;
        return $e;
    }
}

sub getUpdate {
    my ($self) = @_;

    try {
        my $schema = $self->schema->client($self->config);
        my @data = $self->find($schema, {type => "update", status => "pending"});
        return $self->schema->get_columns(@data);
    } catch {
        my $e = $_;
        return $e;
    }

}

sub getAdd {
    my ($self) = @_;

    try {
        my $schema = $self->schema->client($self->config);
        my @data = $self->find($schema, {type => "add", status => "pending"});
        return $self->schema->get_columns(@data);
    } catch {
        my $e = $_;
        return $e;
    }
    
}

1;