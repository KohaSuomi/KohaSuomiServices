package KohaSuomiServices::Command::UpdateActiveRecords;
use Mojo::Base 'Mojolicious::Command';

use utf8;

use Mojo::Util 'getopt';

has description => 'Updates active records from host interface';
has usage => <<"USAGE";

$0 UpdateActiveRecords [OPTIONS]
OPTIONS:
  -w, --wait  Define wait time
  -i, --interfaces Define update for certain interfaces, is repeatable.
USAGE

sub run {
  my ($self, @args) = @_;
  my $app = $self->app;

  my $loopcount=0;

  getopt(
    \@args,
    'w|wait=i' => \my $wait,
    'i|interfaces=s' => \my @interfaces,
  );

  while($loopcount < 5) {
    $app->biblio->updateActive(@interfaces);
    sleep $wait if $wait;
  }

}


1;