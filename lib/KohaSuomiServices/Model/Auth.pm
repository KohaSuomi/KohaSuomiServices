package KohaSuomiServices::Model::Auth;

use Modern::Perl;

use JSON;
use Try::Tiny;

use Mojo::JSON qw(decode_json encode_json);

sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;

    return $self;
}

sub get {
    my ($self, $params) = @_;

    try {
        
        my $path = $self->{config}->{koha_basepath}.'/api/v1/auth/session';
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(POST => $path => form => $params);
        $tx = $ua->start($tx);
        my $res = decode_json($tx->res->body);
        return $res->{sessionid};
    } catch {
        my $e = $_;
        return $e;
    }
}

1;