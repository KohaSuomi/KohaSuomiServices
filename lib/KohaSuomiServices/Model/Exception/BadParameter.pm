package KohaSuomiServices::Model::Exception::BadParameter;

use Modern::Perl;
use utf8;
use KohaSuomiServices::Model::Exception;

use Exception::Class (
    'KohaSuomiServices::Model::Exception::BadParameter' => {
        isa => 'KohaSuomiServices::Model::Exception',
        description => 'Bad parameter',
    },
);

my $httpStatus = '400';

eval KohaSuomiServices::Model::Exception::generateNew();

1;