package KohaSuomiServices::Model::Config;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use FindBin;
use File::Slurp;
use KohaSuomiServices::Model::Exceptions;

has "service";
has exception => sub {KohaSuomiServices::Model::Exceptions->new};

sub load {
    my ($self) = @_;
    my $config = read_file($FindBin::Bin.'/../koha_suomi_services.conf');
    $self->exception->NotFound("No config file found") unless $config;
    $config = eval $config;

    if (defined $self->service) {
        return $config->{services}->{$self->service};
    } else {
        return $config;
    }
    
}

1;