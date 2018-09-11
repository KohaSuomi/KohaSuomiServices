package KohaSuomiServices::Model::Config;

use Modern::Perl;

use JSON;
use Try::Tiny;

sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;

    return $self;
}

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