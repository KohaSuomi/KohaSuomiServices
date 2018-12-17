package KohaSuomiServices::Command::UpdateActiveRecords;
use Mojo::Base 'Mojolicious::Command';

use utf8;

has description => 'Updates active records from host interface';
has usage => <<"USAGE";
Host interface has to be defined on configurations.
Run this to update active records from host.
USAGE

sub run {
  my ($self) = @_;
  my $app = $self->app;

  $app->biblio->updateActive();

}

1;