package KohaSuomiServices::Model::Auth;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;

use KohaSuomiServices::Model::Config;
use Mojo::JSON qw(decode_json encode_json);
use KohaSuomiServices::Model::Exception::Unauthorized;

has schema => sub {KohaSuomiServices::Database::Client->new};
has config => sub {KohaSuomiServices::Model::Config->new->load};
has session => sub {KohaSuomiServices::Model::Auth::Session->new};

sub valid {
    my ($self, $token) = @_;
    KohaSuomiServices::Model::Exception::Unauthorized->throw(error => "Unauthorized access") unless ($self->config->{apikey} eq $token);
    return 1;
}

sub get {
    my ($self, $sessionid) = @_;

    try {
        my $path = $self->config->{auth}->{loginpath};
        my $ua = Mojo::UserAgent->new;
        my $params = {sessionid => $sessionid};
        my $tx = $ua->build_tx(GET => $path => {Accept => 'application/json'} => json => $params);
        $tx = $ua->start($tx);
        my $res = decode_json($tx->res->body);
        return $self->checkPermissions($res);
    } catch {
        my $e = $_;
        return $e;
    }
}

sub checkPermissions {
    my ($self, $params) = @_;
    
    foreach my $permission (@{$self->config->{auth}->{permissions}}) {
        if ($permission ~~ @{$params->{permissions}}) {
            return $params->{sessionid};
        }
    }
    return 0;
}

1;