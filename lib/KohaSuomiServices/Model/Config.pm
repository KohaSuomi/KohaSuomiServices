package KohaSuomiServices::Model::Config;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use FindBin;
use File::Slurp;

has "service";

sub load {
    my ($self) = @_;
    my $config = read_file($FindBin::Bin.'/../koha_suomi_services.conf');
    $config = eval $config;
    
    if (defined $self->service) {
        return $config->{newservices}->{$self->service};
    } else {
        return $config;
    }
    
}

1;