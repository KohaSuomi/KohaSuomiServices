package KohaSuomiServices::Controller::Config;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;
use utf8;

use Try::Tiny;

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;

use Mojo::JSON qw(decode_json encode_json);

sub get {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;

        my $table = ucfirst $req->{table};
        my $client = $c->schema->client($c->configs->service($req->{service})->load);
        my @rs;
        if (defined $req->{id}) {
            @rs = $client->resultset($table)->search({id => $req->{id}});
        } elsif (defined $req->{interface_id}) {
            @rs = $client->resultset($table)->search({interface_id => $req->{interface_id}});
        } elsif (defined $req->{authuser_id}) {
            @rs = $client->resultset($table)->search({authuser_id => $req->{authuser_id}});
        } else {
            @rs = $client->resultset($table)->all();
        }
        
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
        my $params = $req->{params};
        my $table = ucfirst $req->{table};

        my $client = $c->schema->client($c->configs->service($req->{service})->load);

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
        my $params = $req->{params};
        my $id = $req->{id};
        my $table = ucfirst $req->{table};

        my $client = $c->schema->client($c->configs->service($req->{service})->load);

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
        my $id = $req->{id};
        my $table = ucfirst $req->{table};

        my $client = $c->schema->client($c->configs->service($req->{service})->load);

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