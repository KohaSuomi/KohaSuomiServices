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
    $self->render(baseendpoint => $self->configs->service("biblio")->load->{baseendpoint});
}

sub config {
    my $self = shift;
    $self->render(baseendpoint => $self->configs->service("biblio")->load->{baseendpoint});
}

sub get {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;
        my $schema = $c->schema->client($c->configs->service($req->{service})->load);
        my @rs = $schema->resultset("Exporter")->all();

        my $exports = $c->schema->get_columns(@rs);
        my $interface = $c->bibliointerface->load({local => 1, type => "get"});

        my @data;
        foreach my $export (@{$exports}) {
            my $biblio = $c->biblio->find($interface, $export->{localnumber});
            $export->{biblio} = decode_json($biblio);
            push @data, $export;
        }
        
        if (scalar(@data)) {
            $c->render(status => 200, openapi => \@data);
        } else {
            $c->render(status => 404, openapi => {error => "Not found"});
        }
    } catch {
        my $e = $_;
        warn Data::Dumper::Dumper $e;
        $c->render(status => 500, openapi => {message => $e});
    }
    
}

sub export {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->json;
        my $response;
        # my $xml = $c->convert->formatxml($req->{marc});
        # warn Data::Dumper::Dumper $xml;
        $response = $c->biblio->export($req);
        #$response = {message => "Success"};
        if ($req) {
            $c->render(status => 200, openapi => $response);
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        warn Data::Dumper::Dumper $e->{message};
        $c->render(status => 500, openapi => {message => $e->{message}});
    }
    
}

sub check {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;
        my $response;
        my $biblio = $c->convert->formatjson($req->{marcxml});
        my $remote = $c->biblio->search_remote($req->{interface}, $biblio);
        warn Data::Dumper::Dumper $remote;
        my $data;
        my $message;
        if (scalar(@$remote)) {
            $data = $remote;
            $message = "Match found";
        } else {
            $message = "Export";
        }
        $response = {record => $data, localrecord => $biblio, message => $message};
        
        if ($req) {
            $c->render(status => 200, openapi => $response);
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        warn Data::Dumper::Dumper $e->{message};
        $c->render(status => 500, openapi => {message => $e->{message}});
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