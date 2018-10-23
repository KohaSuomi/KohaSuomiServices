package KohaSuomiServices;
use Mojo::Base 'Mojolicious';

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;
use KohaSuomiServices::Model::Convert;
use KohaSuomiServices::Model::SRU;
use KohaSuomiServices::Model::Biblio;
use KohaSuomiServices::Model::Billing;
use KohaSuomiServices::Model::Auth;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Configurations
  my $config = $self->plugin('Config');
  my $log = Mojo::Log->new(path => $config->{logs}, level => $config->{log_level});

  # Models
  $self->helper(
    configs => sub { state $configs = KohaSuomiServices::Model::Config->new(config => $config) });

  $self->helper(
    auth => sub { state $auth = KohaSuomiServices::Model::Auth->new(config => $config) });
  
  $self->helper(
    schema => sub { state $schema = KohaSuomiServices::Database::Client->new(config => $config) });
  
  $self->helper(
    convert => sub { state $convert = KohaSuomiServices::Model::Convert->new(config => $config) });
    
  $self->helper(
    sru => sub { state $sru = KohaSuomiServices::Model::SRU->new() });
    
  $self->helper(
    biblio => sub { state $biblio = KohaSuomiServices::Model::Biblio->new(config => $self->configs->get("biblio"), schema => shift->schema) });

  $self->helper(
    billing => sub { state $billing = KohaSuomiServices::Model::Billing->new(config => $self->configs->get("billing")) });

  $self->plugin(OpenAPI => {spec => $self->static->file("api.yaml")->path});


  # Routers
  my $r = $self->routes;

  $r->get('/login')->to('auth#login');

  foreach my $service (@{$config->{services}}) {
    $self->plugin(OpenAPI => {spec => $self->static->file($service->{route}.".yaml")->path});
    $r->get('/'.$service->{route})->to($service->{route}.'#view');
    $r->get('/'.$service->{route}.'/config')->to($service->{route}.'#config');
  }
}

1;
