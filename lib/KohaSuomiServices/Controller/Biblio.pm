package KohaSuomiServices::Controller::Biblio;
use Mojo::Base 'Mojolicious::Controller';

use Modern::Perl;

use JSON;
use Try::Tiny;

use KohaSuomiServices::Model::Biblio;
use KohaSuomiServices::Model::Auth;
use KohaSuomiServices::Model::Config;

# sub view {
#   my $self = shift;

# #   my $db = KohaSuomiServices::Database::Client->new({config => $self->{app}->{config}});
  
# #   my $config = $self->stash('config');
# #   my $dbh = $db->connect($config->{schema});

#   #my $check = $db->check_table($config->{schema}, "instances");
#   #$self->render(msg => 'YAY!! GIMME BIBLIOS!');
# }

sub get {
    my $c = shift->openapi->valid_input or return;

    try {
        my $params  = $c->req->params->to_hash;
        my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
        my $config = $service->get('biblio');

        my $biblio = KohaSuomiServices::Model::Biblio->new({config => $config});
        my $parsed;

        my $host = decode_json($params->{"host"});
        my $record = $biblio->search($params);
        $record = decode_json($record);
        my $db = KohaSuomiServices::Database::Client->new({config => $config});
        my $dbh = $db->connect();
        my $row = {name => $host->{servername}, type => "get"};
        my $interface = $db->get_data('interface', $row);
        my $data = $biblio->get($interface->[0], $record->{"controlnumber"});
        if (defined $data) {
            $c->render(status => 200, openapi => $data);
        } else {
            $c->render(status => 404, openapi => {error => "Not found"});
        }
    } catch {
        $c->render(status => 500, openapi => {message => "Failure"});
    }
    
}

sub add {
    my $c = shift->openapi->valid_input or return;

    try {
        my $biblionumber = $c->validation->param('biblionumber');
        my $params  = $c->req->params->to_hash;

        my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
        my $config = $service->get('biblio');

        my $auth = KohaSuomiServices::Model::Auth->new({config => $config});
        my $sessionid = $auth->get($params);

        my $biblio = KohaSuomiServices::Model::Biblio->new({config => $config});
        my $res = $biblio->find($biblionumber, $sessionid);
        $biblio->add_remote($res);
        $c->render(status => 200, openapi => {message => "Success"});
    } catch {
        $c->render(status => 500, openapi => {message => $_});
    }
}

sub update {
    my $c = shift->openapi->valid_input or return;

    try {
        my $biblionumber = $c->validation->param('biblionumber');
        my $params  = $c->req->params->to_hash;

        my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
        my $config = $service->get('biblio');

        my $auth = KohaSuomiServices::Model::Auth->new({config => $config});
        my $sessionid = $auth->get($params);

        my $biblio = KohaSuomiServices::Model::Biblio->new({config => $config});
        my $res = $biblio->find($biblionumber, $sessionid);
        $biblio->update_remote($res);
        
        $c->render(status => 200, openapi => {message => "Success"});
    } catch {
        $c->render(status => 500, openapi => {message => $_});
    }
}

1;