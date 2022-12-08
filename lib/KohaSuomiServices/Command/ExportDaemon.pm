package KohaSuomiServices::Command::ExportDaemon;
use Mojo::Base 'Mojolicious::Command';

use utf8;

use Mojo::Util 'getopt';

has description => 'Pushes pending exports to interfaces with daemonized loop';
has usage => <<"USAGE";

$0 ExportDaemon [OPTIONS]
OPTIONS:
  -y, --type  Define wanted export type, available values are update and add
  -c, --componentparts  Define wanted export type, available values are update and add
  -b, --broadcastrecord  Define if sending broadcast records
  -w, --wait  Define sleep time
Defaults to pushing all exports
USAGE

sub run {
  my ($self, @args) = @_;
  my $app = $self->app;

  my $loopcount=0;
  my $broadcastrecord = 0;

  getopt(
    \@args,
    'w|wait=i' => \my $wait,
    't|type=s' => \my $type,
    'c|componentparts' => \my $componentparts,
    'b|broadcastrecord' => \$broadcastrecord,
  );

  while($loopcount < 5) {
    $app->biblio->pushExport($type, $componentparts, $broadcastrecord);
    sleep $wait if $wait;
  }

}

1;
