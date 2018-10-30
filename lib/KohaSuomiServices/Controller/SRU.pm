package KohaSuomiServices::Controller::SRU;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;

use Try::Tiny;

sub get {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;
        my @data = $c->sru->search($req);
        if (length(@data)) {
            $c->render(status => 200, openapi => @data);
        } else {
            $c->render(status => 404, openapi => {error => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(status => 500, openapi => {error => $e});
    }
}

1;