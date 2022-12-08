package KohaSuomiServices::Command::CopyInterface;
use Mojo::Base 'Mojolicious::Command';

use utf8;

use Mojo::Util 'getopt';

has description => 'Create duplicate interface from existing one';
has usage => <<"USAGE";

$0 CopyInterface [OPTIONS]
OPTIONS:
  -i, --interface  The name of the copied interface
  -c, --copy    The name of the new copy
  -t, --type  The interface type; search, get, add, update, delete, getcomponentparts
USAGE

sub run {
  my ($self, @args) = @_;
  my $app = $self->app;

  getopt(
    \@args,
    'i|interface=s' => \my $interface,
    'c|copy=s' => \my $copy,
    't|type=s' => \my $type,
  );
  unless ($interface && $copy && $type) {
      print "Define all parameters\n";
      print $self->usage;
  } else {
      $app->biblio->copyInterface($interface, $copy, $type);
  }

}

1;
