package KohaSuomiServices::Database::Billing::Schema;

use KohaSuomiServices::Model::Config;

our $VERSION = KohaSuomiServices::Model::Config->new->service("billing")->load->{database}->{version};

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces();

1;