package KohaSuomiServices::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;
use utf8;

use Try::Tiny;

sub view {
    my $self = shift;

    $self->render(
        baseendpoint => $self->configs->load->{auth}->{baseendpoint}
    );
}

sub login {
    my $self = shift;

    if ($self->session('logged_in')) {
        $self->auth->delete($self->session('logged_in'));
        $self->session(expires => 1);
    }
    
    $self->render(
        baseendpoint => $self->configs->load->{auth}->{baseendpoint}
    );
}

sub setSession {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        my ($session, $error) = $c->auth->login($req->{username}, $req->{password});
        if ($error) {
            $c->render(status => $error->{code}, openapi => $error->{message});
            return 0;
        }
        $c->session(logged_in => $session);
        $c->render(status => 200, openapi => {message => "Success"});
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

sub isLoggedIn {
    my $self = shift;
    return 1 if $self->session('logged_in') && $self->auth->get($self->session('logged_in'));
    $self->render(template => "auth/login",
        baseendpoint => $self->configs->load->{auth}->{baseendpoint} 
    );
    return 0;
}

sub api {
    my $c = shift->openapi->valid_input or return;

    if ($c->req->method eq 'OPTIONS') {
        return 1;
    }

    try {
        return 1 if ($c->auth->valid($c->req->headers->authorization));
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
        return 0;
    }
}

1;
