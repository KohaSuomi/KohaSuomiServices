package KohaSuomiServices::Controller::Config;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;

use Try::Tiny;

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;

use Mojo::JSON qw(decode_json encode_json);

sub get {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;
        $c->{app}->{config}->{servicename} = $req->{service};

        my $table = ucfirst $req->{table};
        my $client = $c->schema->client($c->configs->get($req->{service}));
        my @rs = $client->resultset($table)->all();

        my @data = $c->schema->get_columns(@rs);

        if ($client) {
            $c->render(status => 200, openapi => @data);
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
        $c->{app}->{config}->{servicename} = $req->{service};
        my $params = $req->{params};
        my $table = ucfirst $req->{table};

        my $client = $c->schema->client($c->configs->get($req->{service}));

        my $data = $client->resultset($table)->new($params);
        $data->insert();

        if ($client) {
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
        my $req  = $c->req->json;
        $c->{app}->{config}->{servicename} = $req->{service};
        my $params = $req->{params};
        my $id = $req->{id};
        my $table = ucfirst $req->{table};

        my $client = $c->schema->client($c->configs->get($req->{service}));

        my $data = $client->resultset($table)->find($id);
        $data->update($params);

        if ($client) {
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
        $c->{app}->{config}->{servicename} = $req->{service};
        my $id = $req->{id};
        my $table = ucfirst $req->{table};

        my $client = $c->schema->client($c->configs->get($req->{service}));

        my $data = $client->resultset($table)->find($id);
        $data->delete();

        if ($client) {
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