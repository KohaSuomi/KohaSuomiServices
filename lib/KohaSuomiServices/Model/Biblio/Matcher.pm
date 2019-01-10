package KohaSuomiServices::Model::Biblio::Matcher;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;

use KohaSuomiServices::Database::Client;
use KohaSuomiServices::Model::Config;

has schema => sub {KohaSuomiServices::Database::Client->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};

sub find {
    my ($self, $client, $id, $type) = @_;
    my @data = $client->resultset('Matcher')->search({interface_id => $id, type => $type}, {columns => [qw/tag code/]});
    my %matchers;
    foreach my $data (@data) {
        if ($matchers{$data->tag}) {
            my $temp = delete $matchers{$data->tag};
            push @{$matchers{$data->tag}}, $temp , $data->code;
        } else {
            $matchers{$data->tag} = $data->code;
        }
    }
    return %matchers;
}

sub defaultSearchMatchers {
    return ("020" => "a", "024" => "a", "027" => "a", "028" => ["a", "b"]);
}

sub removeMatchers {
    my ($self, $id) = @_;
    my $client = $self->schema->client($self->config);
    return $self->find($client, $id, "remove");
}

1;