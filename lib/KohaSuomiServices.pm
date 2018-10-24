package KohaSuomiServices;
use Mojo::Base 'Mojolicious';

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;
use KohaSuomiServices::Model::Convert;
use KohaSuomiServices::Model::SRU;
use KohaSuomiServices::Model::Biblio;
use KohaSuomiServices::Model::Billing;
use KohaSuomiServices::Model::Auth;
use KohaSuomiServices::Model::Biblio::Interface;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Configurations
  my $config = $self->plugin('Config');
  my $log = Mojo::Log->new(path => $config->{logs}, level => $config->{log_level});

  # Models
  $self->helper(
    configs => sub { my $configs = KohaSuomiServices::Model::Config->new(config => $config) });

  $self->helper(
    auth => sub { state $auth = KohaSuomiServices::Model::Auth->new() });
  
  $self->helper(
    schema => sub { my $schema = KohaSuomiServices::Database::Client->new() });
  
  $self->helper(
    convert => sub { state $convert = KohaSuomiServices::Model::Convert->new() });
    
  $self->helper(
    sru => sub { state $sru = KohaSuomiServices::Model::SRU->new() });
    
  $self->helper(
    biblio => sub { state $biblio = KohaSuomiServices::Model::Biblio->new(schema => shift->schema) });

  $self->helper(
    billing => sub { state $billing = KohaSuomiServices::Model::Billing->new() });

  $self->plugin(OpenAPI => {spec => $self->static->file("api.yaml")->path});


  # Routers
  my $r = $self->routes;

  $r->get('/login')->to('auth#login');

  foreach my $service (keys %{$config->{services}}) {
    $self->plugin(OpenAPI => {spec => $self->static->file($service.".yaml")->path});
    $r->get('/'.$service)->to($service.'#view');
    $r->get('/'.$service.'/config')->to($service.'#config');
  }
}

1;
