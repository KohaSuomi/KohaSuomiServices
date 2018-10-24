package KohaSuomiServices::Model::Biblio::Interface;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);

has schema => sub {KohaSuomiServices::Database::Client->new};

sub load {
    my ($self, $params) = @_;

    try {
        my $client = $self->schema->client("biblio");
        my $localInterface = $client->resultset("Interface")->search($params)->next;
        my @p = $client->resultset("Parameter")->search({interface_id => $localInterface->id});
        my $interfaceParams = $self->schema->get_columns(@p);
        my $interface->{endpoint_url} = $localInterface->endpoint_url;
        $interface->{interface} = $localInterface->interface;
        $interface->{type} = $localInterface->type;
        $interface->{params} = $interfaceParams;
        return $interface;
    } catch {
        my $e = $_;
        warn Data::Dumper::Dumper $e->{message};
        return $e;
    }
}

1;