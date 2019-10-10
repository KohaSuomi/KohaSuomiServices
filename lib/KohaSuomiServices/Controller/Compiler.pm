package KohaSuomiServices::Controller::Compiler;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;
use utf8;

use Try::Tiny;

sub run {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req = $c->req->json;
        my $response = $c->compiler->run($req);
        $c->render(status => 200, openapi => $response);
    } catch {
        my $e = $_;
        $c->render(status => 500, openapi => {error => $e});
    }
}

1;