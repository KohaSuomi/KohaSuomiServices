package KohaSuomiServices::Database::Biblio::Schema;

use KohaSuomiServices::Model::Config;

our $VERSION = defined KohaSuomiServices::Model::Config->new->service("biblio")->load ? KohaSuomiServices::Model::Config->new->service("biblio")->load->{database}->{version} : 1;

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces();

1;
