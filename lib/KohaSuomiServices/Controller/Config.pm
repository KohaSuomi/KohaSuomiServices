package KohaSuomiServices::Controller::Config;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;

use JSON;
use Try::Tiny;

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;

use Mojo::JSON qw(decode_json encode_json);

sub get {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;
        my $servicename = $req->{service};
        my $params;
        if (defined $req->{params}) {
           $params = decode_json($req->{params});
        }

        my $table = $req->{table};
        my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
        my $config = $service->get($servicename);
        my $db = KohaSuomiServices::Database::Client->new({config => $config});
        my $dbh = $db->connect();
        
        my $data = $db->get_data($table, $params);
        if ($config) {
            $c->render(status => 200, openapi => $data);
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(status => 500, openapi => {message => $e});
    }
}

sub add {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->body;
        $req = decode_json($req);
        my $servicename = $req->{service};
        my $params = $req->{params};
        my $table = $req->{table};
        my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
        my $config = $service->get($servicename);
        my $db = KohaSuomiServices::Database::Client->new({config => $config});
        my $dbh = $db->connect();


        my $data = $db->add_data($table, $params);
        if ($config) {
            $c->render(status => 200, openapi => {data => $data});
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(status => 500, openapi => {message => $e});
    }
}

sub update {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->body;
        $req = decode_json($req);
        my $servicename = $req->{service};
        my $params = $req->{params};
        my $id = $req->{id};
        my $table = $req->{table};
        my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
        my $config = $service->get($servicename);
        my $db = KohaSuomiServices::Database::Client->new({config => $config});
        my $dbh = $db->connect();


        my $data = $db->update_data($table, $params, $id);
        if ($config) {
            $c->render(status => 200, openapi => {data => $data});
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(status => 500, openapi => {message => $e});
    }
}

sub delete {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;
        my $servicename = $req->{service};
        my $id = $req->{id};
        my $table = $req->{table};
        my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
        my $config = $service->get($servicename);
        my $db = KohaSuomiServices::Database::Client->new({config => $config});
        my $dbh = $db->connect();


        my $data = $db->remove_data($table, $id);
        if ($config) {
            $c->render(status => 200, openapi => {data => $data});
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(status => 500, openapi => {message => $e});
    }
}

1;