package KohaSuomiServices::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;

use Try::Tiny;

sub login {
    my $self = shift;
    $self->render();
}

sub add {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        my $login = $c->auth->login($req);
        $c->render(status => 200, openapi => {message => "Success"});
    } catch {
        my $e = $_;
        $c->render(status => 500, openapi => {message => $e});
    }
}

sub api {
    my $c = shift->openapi->valid_input or return;

    my $authStatus;

    if ($c->auth->valid($c->req->headers->authorization)) {
        $authStatus = 1;
    } else {
        $authStatus = 0;
        $c->render(status => 401, openapi => {message => "Unauthorized"});
    
    }
    return $authStatus;
}


1;