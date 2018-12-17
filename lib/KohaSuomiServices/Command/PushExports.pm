package KohaSuomiServices::Command::PushExports;
use Mojo::Base 'Mojolicious::Command';

use utf8;

has description => 'Pushes pending exports to interfaces';
has usage => <<"USAGE";
Run this to push pending exports to interfaces.
USAGE

sub run {
  my ($self) = @_;
  my $app = $self->app;

  $app->biblio->push();

}

1;