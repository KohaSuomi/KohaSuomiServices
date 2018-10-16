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
        my $db = KohaSuomiServices::Database::Client->new({config => $c->{app}->{config}});
        my $schema = $db->client();
        my @rs = $schema->resultset($table)->all();

        my @data = $db->get_columns(@rs);

        if ($schema) {
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

        my $db = KohaSuomiServices::Database::Client->new({config => $c->{app}->{config}});
        my $schema = $db->client();

        my $data = $schema->resultset($table)->new($params);
        $data->insert();

        if ($schema) {
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
        $c->{app}->{config}->{servicename} = $req->{service};
        my $params = $req->{params};
        my $id = $req->{id};
        my $table = ucfirst $req->{table};

        my $db = KohaSuomiServices::Database::Client->new({config => $c->{app}->{config}});
        my $schema = $db->client();

        my $data = $schema->resultset($table)->find($id);
        $data->update($params);

        if ($schema) {
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

        my $db = KohaSuomiServices::Database::Client->new({config => $c->{app}->{config}});
        my $schema = $db->client();

        my $data = $schema->resultset($table)->find($id);
        $data->delete();

        if ($schema) {
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