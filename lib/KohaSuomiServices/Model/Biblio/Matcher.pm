package KohaSuomiServices::Model::Biblio::Matcher;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;

sub find {
    my ($self, $client, $id, $type) = @_;
    my @data = $client->resultset('Matcher')->search({interface_id => $id, type => $type}, {columns => [qw/tag code/]});
    my %matchers;
    foreach my $data (@data) {
        $matchers{$data->tag} = $data->code;
    }
    return %matchers;
}

sub defaultSearchMatchers {
    return ("020" => "a", "024" => "a", "027" => "a", "028" => "a", "028" => "b");
}

1;