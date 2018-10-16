package KohaSuomiServices::Controller::Billing;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::UserAgent;

use Try::Tiny;
use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Model::Billing;
use Mojo::JSON qw(decode_json encode_json);

# This action will render a template
sub view {
  my $self = shift;
  # Render template "example/welcome.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub list {
  my $c = shift->openapi->valid_input or return;

  try {
    my $body =  $c->req->body;

    my $params  = $c->req->params->to_hash;
    my $service = KohaSuomiServices::Model::Config->new({config => $c->{app}->{config}});
    my $config = $service->get('billing');

    my $billing = KohaSuomiServices::Model::Billing->new({config => $config});
    my $checkouts = $billing->search($params);

    $c->render(status => 200, openapi => $checkouts);
  } catch {
    $c->render(status => 500, openapi => {message => $_});
  }

}

1;