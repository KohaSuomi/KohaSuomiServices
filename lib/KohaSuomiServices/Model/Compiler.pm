package KohaSuomiServices::Model::Compiler;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;

use KohaSuomiServices::Model::Convert;
use KohaSuomiServices::Model::Compilers::RDA;
use KohaSuomiServices::Model::Exception::BadParameter;

has rda => sub {KohaSuomiServices::Model::Compilers::RDA->new};
has convert => sub {KohaSuomiServices::Model::Convert->new};

sub run {
    my ($self, $params) = @_;
     
    KohaSuomiServices::Model::Exception::BadParameter->throw(error => "Bad parameters") unless $params;

    my $exportCompiler = $params->{export_format};
    my $exportModel = $params->{import_format};
    $params->{marc} = $self->convert->formatjson($params->{marc});

    my $result = $self->$exportCompiler->$exportModel($params->{language}, $params->{marc});

    return $result;

}

1;