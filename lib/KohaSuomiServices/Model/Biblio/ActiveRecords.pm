package KohaSuomiServices::Model::Biblio::ActiveRecords;
use Mojo::Base -base;

use Modern::Perl;
use utf8;
use Try::Tiny;
use POSIX 'strftime';

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;

has schema => sub {KohaSuomiServices::Database::Client->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};


sub find {
    my ($self, $client, $params) = @_;
    return $self->schema->get_columns($client->resultset('ActiveRecords')->search($params));
}

sub findLast {
    my ($self, $client, $params) = @_;
    return $self->schema->get_columns($client->resultset('ActiveRecords')->find($params, {order_by => {-desc => \'CAST(target_id AS int)'}}));
}

sub insert {
    my ($self, $client, $params) = @_;
    return $client->resultset('ActiveRecords')->new($params)->insert();
}

sub update {
    my ($self, $client, $id, $params) = @_;
    return $client->resultset('ActiveRecords')->find($id)->update($params);
}

sub updateActiveRecords {
    my ($self, $id) = @_;

    my $schema = $self->schema->client($self->config);
    my $now = strftime "%Y-%m-%d %H:%M:%S", ( localtime(time + 5*60) );
    $self->update($schema, $id, {updated => $now});
}


1;