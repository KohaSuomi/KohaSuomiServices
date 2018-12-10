package KohaSuomiServices::Model::Auth;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;

use KohaSuomiServices::Model::Config;
use Mojo::JSON qw(decode_json encode_json);
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