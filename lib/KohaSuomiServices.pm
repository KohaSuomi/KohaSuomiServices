package KohaSuomiServices;
use Mojo::Base 'Mojolicious';

use KohaSuomiServices::Database::Client;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');
  my $log = Mojo::Log->new(path => $config->{logs}, level => $config->{log_level});

  $self->plugin(OpenAPI => {spec => $self->static->file("api.yaml")->path});
  # Router
  my $r = $self->routes;

  # Normal route to controller
  foreach my $service (@{$config->{services}}) {
    $self->plugin(OpenAPI => {spec => $self->static->file($service->{route}.".yaml")->path});
    $r->get('/'.$service->{route})->to($service->{route}.'#view');
    $r->get('/'.$service->{route}.'/config')->to($service->{route}.'#config');
  }
}

1;
