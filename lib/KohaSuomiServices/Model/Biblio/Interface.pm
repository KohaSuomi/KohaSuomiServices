package KohaSuomiServices::Model::Biblio::Interface;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);
use KohaSuomiServices::Model::Biblio::Parameter;

use KohaSuomiServices::Model::Exception::NotFound;

has schema => sub {KohaSuomiServices::Database::Client->new};
has parameter => sub {KohaSuomiServices::Model::Biblio::Parameter->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};

sub load {
    my ($self, $params) = @_;

    my $client = $self->schema->client($self->config);
    my $localInterface = $client->resultset("Interface")->search($params)->next;
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No ".$params->{type}." interface defined for ".$params->{name}) unless $localInterface;
    my $interfaceParams = $self->parameter->find({interface_id => $localInterface->id});
    my $interface = $self->parse($localInterface, $interfaceParams);
    return $interface;
}

sub parse {
    my ($self, $interface, $params) = @_;

    my $res->{id} = $interface->id;
    $res->{endpoint_url} = $interface->endpoint_url;
    $res->{interface} = $interface->interface;
    $res->{type} = $interface->type;
    $res->{params} = $params;

    return $res;
}

1;