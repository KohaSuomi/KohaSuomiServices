package KohaSuomiServices::Model::Exception::Unauthorized;

use Modern::Perl;
use utf8;
use KohaSuomiServices::Model::Exception;

use Exception::Class (
    'KohaSuomiServices::Model::Exception::Unauthorized' => {
        isa => 'KohaSuomiServices::Model::Exception',
        description => 'Unauthorized',
    },
);

my $httpStatus = '401';

eval KohaSuomiServices::Model::Exception::generateNew();

1;