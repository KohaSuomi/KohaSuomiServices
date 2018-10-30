package KohaSuomiServices::Model::Config;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use FindBin;
use File::Slurp;
use KohaSuomiServices::Model::Exception::NotFound;

has "service";

sub load {
    my ($self) = @_;
    my $config = read_file($FindBin::Bin.'/../koha_suomi_services.conf');
    KohaSuomiServices::Model::Exception::NotFound(error => "No config file found") unless $config;
    $config = eval $config;

    if (defined $self->service) {
        return $config->{services}->{$self->service};
    } else {
        return $config;
    }
    
}

1;