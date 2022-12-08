package KohaSuomiServices::Controller::Config;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;
use utf8;
use MIME::Base64;

use Try::Tiny;

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;

use KohaSuomiServices::Model::Exception;

use Mojo::JSON qw(decode_json encode_json);

use Mojo::UserAgent;
use Mojo::URL;

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
        } elsif (defined $req->{interface_name}) {
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
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
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
        if ($params->{password}) {
            $params->{password} = encode_base64($params->{password});
        }
        my $data = $client->resultset($table)->new($params);
        $data->insert();

        if ($client) {
            $c->render(status => 200, openapi => {data => $data});
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
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
        if ($params->{password}) {
            $params->{password} = encode_base64($params->{password});
        }
        $data->update($params);

        if ($client) {
            $c->render(status => 200, openapi => {data => $data});
        } else {
            $c->render(status => 404, openapi => {message => "Not found"});
        }
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
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
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

sub checkAuth {
    my $c = shift->openapi->valid_input or return;

    try {
        my $req  = $c->req->params->to_hash;

        my $table = ucfirst $req->{table};
        my $config = $c->configs->service($req->{service})->load;
        my $client = $c->schema->client($config);
        my $data = $client->resultset($table)->search({id => $req->{id}})->next;
        my $interface = $client->resultset("Interface")->search({id => $data->interface_id})->next;
        my $getinterface = $client->resultset("Interface")->search({name => $interface->name, interface => 'REST', type => 'get'})->next;
        unless ($getinterface) {
            $c->render(status => 404, openapi => {message => "Define get interface for $interface->{name}"});
        } else {
            my $error;
            if ($getinterface->auth_url) { 
                $c->render(status => 404, openapi => {message => "auth_url not implemented yet"});
            } else {
                my $path = $getinterface->endpoint_url;
                $path =~ s/{target_id}/$config->{testbiblio}/g;
                $path =~ s/{source_id}/$config->{testbiblio}/g;
                $c->biblio->log->debug($path);
                my $authentication = $data->username.":".decode_base64($data->password);
                my $ua = Mojo::UserAgent->new;
                $path = Mojo::URL->new($path)->userinfo($authentication);
                my $tx = $ua->get($path => {Accept => 'application/json'});
                $error = $tx->error if $tx->error;
                if ($error) {
                    $c->render(status => 401, openapi => $error);
                } else {
                    $c->render(status => 200, openapi => {message => "Success"});
                }
            }
            
        }
    } catch {
        my $e = $_;
        $c->render(KohaSuomiServices::Model::Exception::handleDefaults($e));
    }
}

1;
