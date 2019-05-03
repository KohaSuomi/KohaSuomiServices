package KohaSuomiServices::Command::UpdateActiveRecords;
use Mojo::Base 'Mojolicious::Command';

use utf8;

has description => 'Updates active records from host interface';
has usage => <<"USAGE";

$0 UpdateActiveRecords [OPTIONS]
OPTIONS:
  -w, --wait  Define wait time
USAGE

sub run {
  my ($self, @args) = @_;
  my $app = $self->app;

  my $loopcount=0;

  getopt(
    \@args,
    'w|wait=i' => \my $wait,
  );

  while($loopcount < 5) {
    $app->biblio->updateActive();
    sleep $wait if $wait;
  }

}


1;