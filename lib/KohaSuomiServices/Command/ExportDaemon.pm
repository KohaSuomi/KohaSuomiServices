package KohaSuomiServices::Command::ExportDaemon;
use Mojo::Base 'Mojolicious::Command';

use utf8;

use Mojo::Util 'getopt';

has description => 'Pushes pending exports to interfaces';
has usage => <<"USAGE";

$0 ExportDaemon [OPTIONS]
OPTIONS:
  -w, --wait  Define wanted export type, available values are update and add
Defaults to pushing all exports
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
    $app->biblio->pushExport("update");
    $app->biblio->pushExport("add");
    sleep $wait if $wait;
  }

}

1;