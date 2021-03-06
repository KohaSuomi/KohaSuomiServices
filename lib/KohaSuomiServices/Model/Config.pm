package KohaSuomiServices::Model::Config;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use FindBin;
use File::Slurp;
use Digest::SHA qw(hmac_sha256_hex);
use KohaSuomiServices::Model::Exception::NotFound;

has "service";

sub load {
    my ($self) = @_;
    my $config = read_file($FindBin::Bin.'/../koha_suomi_services.conf');
    KohaSuomiServices::Model::Exception::NotFound(error => "No config file found") unless $config;
    $config = eval $config;

    if ($config->{apikey}) {
        $config->{apikey} = Digest::SHA::hmac_sha256_hex($config->{apikey});
    }

    if (defined $self->service) {
        return $config->{services}->{$self->service};
    } else {
        return $config;
    }
    
}

sub loadCompilerMapper {
    my ($self, $mappername) = @_;

    my $mapper = read_file($FindBin::Bin.'/../lib/KohaSuomiServices/Model/Compilers/Mappers/'.$mappername);
    KohaSuomiServices::Model::Exception::NotFound(error => "No mapper file found") unless $mapper;

    return eval $mapper;
}

1;