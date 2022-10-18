package KohaSuomiServices::Model::Auth;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;

use KohaSuomiServices::Model::Config;
use Mojo::JSON qw(decode_json encode_json from_json);
use KohaSuomiServices::Model::Exception::Unauthorized;
use C4::Auth qw( haspermission );
use Mojo::URL;
use Cache::FastMmap;
use Digest::SHA;

has schema => sub {KohaSuomiServices::Database::Client->new};
has ua => sub {Mojo::UserAgent->new};
has config => sub {KohaSuomiServices::Model::Config->new->load};
has session => sub {KohaSuomiServices::Model::Auth::Session->new};
has cache => sub {Cache::FastMmap->new(share_file => '/tmp/ks_sessions', cache_size => '10m', expire_time => '1h')};

sub valid {
    my ($self, $token) = @_;
    KohaSuomiServices::Model::Exception::Unauthorized->throw(error => "Unauthorized access")
        if ! $token or $self->config->{apikey} ne $token;
    return 1;
}

sub login {
    my ($self, $username, $password) = @_;
    my $path = $self->config->{auth}->{internallogin};
    $path = Mojo::URL->new($path)->userinfo($username.':'.$password);
    my $error;
    my $params = {userid => $username};
    my $tx = $self->ua->build_tx(GET => $path => {Accept => 'application/json'} => form => $params);
    $tx = $self->ua->start($tx);
    $error = {code => defined $tx->res->error->{code} && $tx->res->error->{code} ? $tx->res->error->{code} : 500, message => from_json($tx->res->body)} if defined $tx->res->error && $tx->res->error;
    my $user = decode_json($tx->res->body);
    $user = shift @$user;
    my $hash = $self->checkPermissions($user);
    $self->cache->set($hash, $user->{userid}) if $hash;
    return ($hash, $error);
}

sub get {
    my ($self, $sessionid) = @_;
    return $self->cache->get($sessionid);
}

sub delete {
    my ($self, $sessionid) = @_;

    $self->cache->remove($sessionid);
}

sub checkPermissions {
    my ($self, $user) = @_;
    my $haspermission = C4::Auth::haspermission($user->{userid});
    return $self->userHash($user) if $haspermission->{superlibrarian};
    return 0;
}

sub userHash {
    my ($self, $user) = @_;
    my $hash = Digest::SHA::hmac_sha256_hex($user->{userid}.$user->{updated_on});
    return $hash;
}

1;
