package KohaSuomiServices::Model::Convert;

use Modern::Perl;

use JSON;
use Try::Tiny;

#use Mojo::JSON qw(decode_json encode_json);
#use XML::XML2JSON;

sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;

    return $self;
}

sub convert {
    my ($self, $params) = @_;
    #$params = decode_json($params);
    #my $marcxml = $params->{marcxml};
}

1;