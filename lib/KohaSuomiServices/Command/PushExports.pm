package KohaSuomiServices::Command::PushExports;
use Mojo::Base 'Mojolicious::Command';

use utf8;

use Mojo::Util 'getopt';

has description => 'Pushes pending exports to interfaces';
has usage => <<"USAGE";

$0 PushExports [OPTIONS]
OPTIONS:
  -y, --type  Define wanted export type, available values are update and add
  -c, --componentparts  Define parent record for pushing component parts
Defaults to pushing all exports
USAGE

sub run {
  my ($self, @args) = @_;
  my $app = $self->app;

  getopt(
    \@args,
    't|type=s' => \my $type,
    'c|componentparts' => \my $componentparts,
  );
  
  $app->biblio->pushExport($type, $componentparts);

}

1;