package KohaSuomiServices::Controller::Billing;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::UserAgent;

use JSON;
use Try::Tiny;
use Koha::Checkouts;

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

    my $start = '2018-01-01';
    my $end   = '2018-01-07';
    my $branchcode = 'MLI_PK';

    my $checkouts = Koha::Checkouts->search({
        date_due => { '-between' => [$start, $end] },
        branchcode => $branchcode
    });
    
    $c->render(status => 200, openapi => $checkouts);
  } catch {
    $c->render(status => 501, openapi => {message => "Failure"});
  }

}

1;