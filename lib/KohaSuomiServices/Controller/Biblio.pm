package KohaSuomiServices::Controller::Biblio;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;

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
        $c->render(status => 200, openapi => $response);
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
    
}

sub check {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;
        my $response;
        my $biblio = $c->convert->formatjson($req->{marcxml});
        my $remote = $c->biblio->searchTarget($req->{interface}, $biblio);
        $remote = shift @{$remote};
        my $target_id = $c->biblio->getTargetId($req->{interface}, $remote);

        my $data;
        my $message;
        if ($remote) {
            $data = $remote;
            $message = "Match found";
        } else {
            $message = "Export";
        }
        $response = {target_id => $target_id, targetrecord => $data, sourcerecord => $biblio};
        
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

# sub add {
#     my $c = shift->openapi->valid_input or return;

#     try {
#         my $biblionumber = $c->validation->param('biblionumber');
#         my $params  = $c->req->params->to_hash;

#         my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
#         my $config = $service->get('biblio');

#         my $auth = KohaSuomiServices::Model::Auth->new({config => $config});
#         my $sessionid = $auth->get;

#         my $biblio = KohaSuomiServices::Model::Biblio->new({config => $config});
#         my $res = $biblio->find($biblionumber, $sessionid);
#         $biblio->add_remote($res);
#         $c->render(status => 200, openapi => {message => "Success"});
#     } catch {
#         $c->render(status => 500, openapi => {message => $_});
#     }
# }

# sub update {
#     my $c = shift->openapi->valid_input or return;

#     try {
#         my $biblionumber = $c->validation->param('biblionumber');
#         my $params  = $c->req->params->to_hash;

#         my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
#         my $config = $service->get('biblio');

#         my $auth = KohaSuomiServices::Model::Auth->new({config => $config});
#         my $sessionid = $auth->get;

#         my $biblio = KohaSuomiServices::Model::Biblio->new({config => $config});
#         my $res = $biblio->find($biblionumber, $sessionid);
#         $biblio->update_remote($res);
        
#         $c->render(status => 200, openapi => {message => "Success"});
#     } catch {
#         $c->render(status => 500, openapi => {message => $_});
#     }
# }

1;