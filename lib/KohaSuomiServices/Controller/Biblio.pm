package KohaSuomiServices::Controller::Biblio;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;
use utf8;

use Try::Tiny;

use Mojo::JSON qw(decode_json encode_json);

use KohaSuomiServices::Model::Biblio;
use KohaSuomiServices::Model::Auth;
use KohaSuomiServices::Model::Config;

use KohaSuomiServices::Model::Exception;

sub view {
    my $self = shift;
    $self->render(apikey => $self->configs->load->{apikey}, baseendpoint => $self->configs->service("biblio")->load->{baseendpoint});
}

sub config {
    my $self = shift;
    $self->render(apikey => $self->configs->load->{apikey}, baseendpoint => $self->configs->service("biblio")->load->{baseendpoint});
}

sub get {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req = $c->req->params->to_hash;
        my @data = $c->biblio->list($req);
        $c->render(status => 200, openapi => @data);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
    
}

sub export {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        my $response = $c->biblio->export($req);
        if (defined $response && $response->{message} eq "Success" && $c->configs->service("biblio")->load->{export} eq "automatic") {
            $c->biblio->pushExport("update");
            $c->biblio->pushExport("add");
        }
        $c->render(status => 200, openapi => $response);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
    
}

sub check {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        my $response;
        my $biblio = $c->convert->formatjson($req->{marcxml});
        my $data;
        my ($mandatorynum, $mandatorychar) = $c->compare->mandatoryCheck($biblio, $req->{interface});
        my $remote = $c->biblio->searchTarget($req->{interface}, $biblio);

        my $target_id;
        if ($remote) {
            $remote = shift @{$remote};
            $target_id = $c->biblio->getTargetId($req->{interface}, $remote);
            $c->compare->getMandatory($biblio, $remote);
            $data = $remote;
        } 

        $response = (!$mandatorynum && $data) ? {source_id => $target_id, targetrecord => $data, sourcerecord => $biblio} : {target_id => $target_id, targetrecord => $data, sourcerecord => $biblio};
        
        if ($req) {
            $c->render(status => 200, openapi => $response);
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
    
}

sub activate {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        my $response = $c->biblio->addActive($req);
        $c->render(status => 200, openapi => $response);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

sub broadcast {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        $req->{marc} = $c->convert->formatjson($req->{marcxml});
        delete $req->{marcxml};
        my $response = $c->biblio->broadcast($req);
        $c->render(status => 200, openapi => $response);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

1;