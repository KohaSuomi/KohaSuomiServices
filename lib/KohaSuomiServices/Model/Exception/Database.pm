package KohaSuomiServices::Model::Exception::Database;

use Modern::Perl;
use utf8;
use KohaSuomiServices::Model::Exception;

use Exception::Class (
    'KohaSuomiServices::Model::Exception::Database' => {
        isa => 'KohaSuomiServices::Model::Exception',
        description => "Database exceptions base class",
    },
);

my $httpStatus = '500';
eval KohaSuomiServices::Model::Exception::generateNew();

1;
