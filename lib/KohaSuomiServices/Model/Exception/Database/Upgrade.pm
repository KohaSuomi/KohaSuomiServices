package KohaSuomiServices::Model::Exception::Database::Upgrade;

use Modern::Perl;
use utf8;
use KohaSuomiServices::Model::Exception;

use Exception::Class (
    'KohaSuomiServices::Model::Exception::Database::Upgrade' => {
        isa => 'KohaSuomiServices::Model::Exception::Database',
        description => 'Database upgrade failed',
    },
);

my $httpStatus = '500';

eval KohaSuomiServices::Model::Exception::generateNew();

1;