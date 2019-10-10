package KohaSuomiServices::Model::Compilers::RDA;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use XML::Simple;
use XML::LibXML;
use Encode;

has mapper => sub {KohaSuomiServices::Model::Config->new->loadCompilerMapper("isbd_to_rda.conf")};

sub isbd {
    my ($self, $record) = @_;
    warn Data::Dumper::Dumper $self->mapper->{biblio};

    return {message => "Success"};
    
}

1;