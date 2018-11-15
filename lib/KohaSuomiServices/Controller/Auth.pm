package KohaSuomiServices::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;

use Try::Tiny;

sub view {
    my $self = shift;

    $self->render(
        apikey => $self->configs->load->{apikey}, 
        loginpath => $self->configs->load->{auth}->{loginpath},
        baseendpoint => $self->configs->load->{auth}->{baseendpoint}
    );
}

sub login {
    my $self = shift;

    $self->render(
        apikey => $self->configs->load->{apikey}, 
        loginpath => $self->configs->load->{auth}->{loginpath},
        baseendpoint => $self->configs->load->{auth}->{baseendpoint}
    );
}

sub add {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        $c->session(logged_in => $req->{sessionid});
        $c->render(status => 200, openapi => {message => "Success"});
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

sub isLoggedIn {
    my $self = shift;
    return 1 if $self->auth->get($self->session('logged_in'));
    $self->render(template => "auth/login",
        apikey => $self->configs->load->{apikey}, 
        loginpath => $self->configs->load->{auth}->{loginpath},
        baseendpoint => $self->configs->load->{auth}->{baseendpoint} 
    );
    return 0;
}

sub api {
    my $c = shift->openapi->valid_input or return;

    try {
        return 1 if ($c->auth->valid($c->req->headers->authorization));
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
        return 0;
    }
}


1;