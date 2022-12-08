package KohaSuomiServices::Model::Exception::NotFound;

use Modern::Perl;
use utf8;
use KohaSuomiServices::Model::Exception;

use Exception::Class (
    'KohaSuomiServices::Model::Exception::NotFound' => {
        isa => 'KohaSuomiServices::Model::Exception',
        description => 'Not found',
    },
);

my $httpStatus = '404';

eval KohaSuomiServices::Model::Exception::generateNew();

1;
