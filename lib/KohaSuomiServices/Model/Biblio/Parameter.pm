package KohaSuomiServices::Model::Biblio::Parameter;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);

has schema => sub {KohaSuomiServices::Database::Client->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};

sub find {
    my ($self, $params) = @_;

    my $client = $self->schema->client($self->config);
    my @p = $client->resultset("Parameter")->search($params);
    my $interfaceParams = $self->schema->get_columns(@p);
    return $interfaceParams;
}

1;