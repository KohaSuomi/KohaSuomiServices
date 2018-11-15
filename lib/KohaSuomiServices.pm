package KohaSuomiServices;
use Mojo::Base 'Mojolicious';

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;
use KohaSuomiServices::Database::Build;
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
  $self->secrets($config->{secrets});
  $self->app->sessions->cookie_name('KSSESSION');
  $self->app->sessions->cookie_path('/');
  $self->app->sessions->default_expiration('600');
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

  $self->plugin(OpenAPI => {
    #route => $self->routes->under("/api")->to("auth#api"),
    spec => $self->static->file("api.yaml")->path
  });


  # Routers
  my $r = $self->routes;

  my $auth = $r->under('/')->to('auth#isLoggedIn');
  $auth->get('/')->to('auth#view');
  $r->get('/login')->to('auth#login');

  foreach my $service (keys %{$config->{services}}) {
    KohaSuomiServices::Database::Build->new()->migrate($service);
    $self->plugin(OpenAPI => {
      route => $self->routes->under("/api")->to("auth#api"),
      spec => $self->static->file($service.".yaml")->path}
    );
    $auth->get('/'.$service)->to($service.'#view');
    $auth->get('/'.$service.'/config')->to($service.'#config');
  }

  $self->hook(before_dispatch => sub {
    my ($c) = @_;
    my $tx = $c->tx;

    #This is actually really bad. Forcibly disabling CORS origin security. Origin is not always set, but should be set by the browser when doing CORS that needs preflight.
    #Instead a whitelist configuration should be made. This can be added if trouble arises.
    if ($tx->req->headers->origin) {
      $tx->res->headers->header( 'Access-Control-Allow-Origin' => $tx->req->headers->origin );
      $tx->res->headers->header( 'Access-Control-Allow-Credentials' => 'true' );
    }
    else {
      $tx->res->headers->header( 'Access-Control-Allow-Origin' => '*' );
      #$tx->res->headers->header( 'Access-Control-Allow-Credentials' => 'true' ); #Never set this header at all if it should be false
    }
    $tx->res->headers->header( 'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS' );
    $tx->res->headers->header( 'Access-Control-Max-Age' => 3600 );
    $tx->res->headers->header( 'Access-Control-Allow-Headers' => 'Content-Type, X-Requested-With, X-CSRF-Token, Authorization' );
    $tx->res->headers->header( 'Access-Control-Expose-Headers' => 'X-CSRF-Token' );
  });

}

1;
