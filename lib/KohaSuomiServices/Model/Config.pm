package KohaSuomiServices::Model::Config;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;

sub get {
    my ($self, $name) = @_;
    my $return;
    foreach my $config (@{$self->{config}->{services}}) {
        if ($config->{route} eq $name) {
            $return = $config;
            last;
        }
    }
    return $return;
}

1;