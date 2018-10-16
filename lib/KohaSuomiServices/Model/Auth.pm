package KohaSuomiServices::Model::Auth;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;

use Mojo::JSON qw(decode_json encode_json);

sub valid {
    my ($self, $sessionid) = @_;
    my $valid = undef;
    if (defined $sessionid && $sessionid eq $self->get($sessionid)) {
        $valid = 1;
    }

    return $valid;
}

sub get {
    my ($self, $sessionid) = @_;

    try {
        my $path = $self->{config}->{kohabasepath}.'/api/v1/auth/session';
        my $ua = Mojo::UserAgent->new;
        my $params = {sessionid => $sessionid};
        my $tx = $ua->build_tx(GET => $path => {Accept => 'application/json'} => json => $params);
        $tx = $ua->start($tx);
        my $res = decode_json($tx->res->body);
        return $res->{sessionid};
    } catch {
        my $e = $_;
        return $e;
    }
}

sub login {
    my ($self, $params) = @_;

    try {
        my $path = $self->{config}->{kohabasepath}.'/api/v1/auth/session';
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