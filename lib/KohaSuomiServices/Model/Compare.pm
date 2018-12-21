package KohaSuomiServices::Model::Compare;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use JSON::Patch qw(diff patch);

sub jsonPatch {
    my ($self, $source, $target) = @_;

    my $diff = diff($source, $target);
    my $patch;
    foreach my $d (@{$diff}) {
        push @{$patch}, $d if $d->{op} eq "add";
    }
    patch ($source, $patch);
}

1;