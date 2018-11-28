package KohaSuomiServices::Database::Billing::Schema;

use KohaSuomiServices::Model::Config;

our $VERSION = defined KohaSuomiServices::Model::Config->new->service("billing")->load ? KohaSuomiServices::Model::Config->new->service("billing")->load->{database}->{version} : 1;

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces();

1;