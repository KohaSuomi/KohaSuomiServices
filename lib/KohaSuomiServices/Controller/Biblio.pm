package KohaSuomiServices::Controller::Biblio;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;

use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);

use KohaSuomiServices::Model::Biblio;
use KohaSuomiServices::Model::Auth;
use KohaSuomiServices::Model::Config;

sub view {
    my $self = shift;
    my $valid = $self->auth->valid($self->cookie('CGISESSID'));
    $self->render(baseendpoint => $self->configs->get("biblio")->{baseendpoint});
}

sub config {
    my $self = shift;
    $self->render(baseendpoint => $self->configs->get("biblio")->{baseendpoint});
}

sub get {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;
        my $schema = $c->schema->client($c->configs->get("biblio"));
        my @rs = $schema->resultset("Exporter")->all();

        my $exports = $c->schema->get_columns(@rs);
        my @data;
        foreach my $export (@{$exports}) {
            my $biblio = $c->biblio->find_local($export->{localnumber});
            $export->{biblio} = decode_json($biblio);
            push @data, $export;
        }
        
        if (length(@data)) {
            $c->render(status => 200, openapi => \@data);
        } else {
            $c->render(status => 404, openapi => {error => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(status => 500, openapi => {message => $e});
    }
    
}

sub export {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        my $schema = $c->schema->client($c->configs->get("biblio"));

        my $data = $c->biblio->export($schema, $req);
        
        if ($schema) {
            $c->render(status => 200, openapi => {message => $data});
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(status => 500, openapi => {message => $e});
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