package KohaSuomiServices::Model::Auth;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;

use KohaSuomiServices::Model::Config;
use Mojo::JSON qw(decode_json encode_json from_json);
use KohaSuomiServices::Model::Exception::Unauthorized;

has schema => sub {KohaSuomiServices::Database::Client->new};
has ua => sub {Mojo::UserAgent->new};
has config => sub {KohaSuomiServices::Model::Config->new->load};
has session => sub {KohaSuomiServices::Model::Auth::Session->new};

sub valid {
    my ($self, $token) = @_;
    KohaSuomiServices::Model::Exception::Unauthorized->throw(error => "Unauthorized access") unless ($self->config->{apikey} eq $token);
    return 1;
}

sub login {
    my ($self, $username, $password) = @_;
    my $path = $self->config->{auth}->{loginpath};
    my $error;
    my $params = {userid => $username, password => $password};
    my $tx = $self->ua->build_tx(POST => $path => {Accept => 'application/x-www-form-urlencoded'} => form => $params);
    $tx = $self->ua->start($tx);
    $error = {code => defined $tx->res->error->{code} ? $tx->res->error->{code} : 500, message => from_json($tx->res->body)} if defined $tx->res->error && $tx->res->error;
    return ($self->checkPermissions(decode_json($tx->res->body)), $error);
}

sub get {
    my ($self, $sessionid) = @_;

    my $path = $self->config->{auth}->{internallogin};
    my $params = {sessionid => $sessionid};
    my $tx = $self->ua->build_tx(GET => $path => {Accept => 'application/json', "Cookie: " => "CGISESSID=".$sessionid} => json => $params);
    $tx = $self->ua->start($tx);
    return $self->checkPermissions(decode_json($tx->res->body));
}

sub delete {
    my ($self, $sessionid) = @_;

    my $path = $self->config->{auth}->{internallogin};
    my $params = {sessionid => $sessionid};
    my $tx = $self->ua->build_tx(DELETE => $path => {Accept => 'application/json'} => json => $params);
    $tx = $self->ua->start($tx);
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