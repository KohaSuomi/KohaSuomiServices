package KohaSuomiServices::Model::Exception::Database::Install;

use Modern::Perl;
use utf8;
use KohaSuomiServices::Model::Exception;

use Exception::Class (
    'KohaSuomiServices::Model::Exception::Database::Install' => {
        isa => 'KohaSuomiServices::Model::Exception::Database',
        description => 'Unable to install database',
    },
);

my $httpStatus = '500';

eval KohaSuomiServices::Model::Exception::generateNew();

1;
