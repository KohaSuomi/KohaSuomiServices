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

sub list {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req = $c->req->params->to_hash;
        my $page = $req->{page} if $req->{page};
        delete $req->{page} if $req->{page};
        my $limit = $req->{limit} if $req->{limit};
        delete $req->{limit} if $req->{limit};
        my $data = $c->biblio->list($req, $page, $limit);
        $c->render(status => 200, openapi => $data);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
    
}

sub get {
    my $c = shift->openapi->valid_input or return;

    try {
        my $id = $c->validation->param('id');
        my $data;
        push @{$data}, @{$c->biblio->list({source_id => $id})->{results}}, @{$c->biblio->list({target_id => $id})->{results}};
        $c->render(status => 200, openapi => $data);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
    
}

sub report {
    my $c = shift->openapi->valid_input or return;

    try {
        my $interface_name = $c->validation->param('interface_name');
        my $req = $c->req->params->to_hash;
        my $page;
        my $limit;
        my $status;
        if ($req) {
            $page = $req->{page} if $req->{page};
            $limit = $req->{limit} if $req->{limit};
            $status = $req->{status} if $req->{status};
        }
        my $data = $c->biblio->interfaceReport($interface_name, $status, $page, $limit);
        $c->render(status => 200, openapi => $data);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
    
}

sub record {
    my $c = shift->openapi->valid_input or return;

    try {
        my $id = $c->validation->param('id');
        my $data = $c->biblio->getRecord($id);
        $c->render(status => 200, openapi => $data);
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
        my ($mandatorynum, $mandatorychar) = $c->compare->matchingFieldCheck($biblio, $req->{interface}, "mandatory");
        my $componentparts;

        my ($data, $target_id) = $c->biblio->search->remoteValues($req->{interface}, $biblio, undef, undef);
        my ($duplicatenum, $duplicatechar) = $c->compare->matchingFieldCheck($data, $req->{interface}, "duplicate");
        my $encoding_level;
        if ($data) {
            $encoding_level = $c->compare->encodingLevelCompare($biblio->{leader}, $data->{leader});
            $mandatorynum = 1 if $encoding_level eq 'greater';
        }
        $response = ((!$mandatorynum && $data) || ($encoding_level eq 'lower' && $data) || (ref($duplicatenum) eq "ARRAY" || ref($duplicatechar) eq "ARRAY")) ? {source_id => $target_id, targetrecord => $data, sourcerecord => $biblio, targetcomponentparts => $componentparts} : {target_id => $target_id, targetrecord => $data, sourcerecord => $biblio, targetcomponentparts => $componentparts};
        
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

sub activateIdentifier {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        my $response = $c->biblio->addActiveIdentifier($req);
        $c->render(status => 200, openapi => $response);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

sub lastrecord {
    my $c = shift->openapi->valid_input or return;

    try {
        my $interface = $c->validation->param('interface');
        my $response = $c->biblio->getLastActive($interface);
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

sub force {
    my $c = shift->openapi->valid_input or return;

    try {
        my $id = $c->validation->param('id');
        my $response = $c->biblio->forceExport($id);
        $c->render(status => 200, openapi => $response);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
    
}

sub getActiveRecord {
    my $c = shift->openapi->valid_input or return;

    try {
        my $interface = $c->validation->param('interface');
        my $id = $c->validation->param('target_id');
        my $response = $c->biblio->getActiveRecord($interface, $id);
        if ($response) {
            $c->render(status => 200, openapi => $response);
        } else {
            $c->render(status => 404, openapi => {error => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

sub updateActiveRecord {
    my $c = shift->openapi->valid_input or return;

    try {
        my $id = $c->validation->param('id');
        my $identifier_field = $c->validation->param('identifier_field');
        my $identifier = $c->validation->param('identifier');
        my $response = $c->biblio->updateActiveRecord($id, $identifier_field, $identifier);
        $c->render(status => 200, openapi => $response);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

sub deleteActiveRecord {
    my $c = shift->openapi->valid_input or return;

    try {
        my $id = $c->validation->param('id');
        my $response = $c->biblio->deleteActiveRecord($id);
        $c->render(status => 200, openapi => $response);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

1;