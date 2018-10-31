package KohaSuomiServices::Database::Biblio::Schema;

use KohaSuomiServices::Model::Config;

our $VERSION = KohaSuomiServices::Model::Config->new->service("biblio")->load->{database}->{version};

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces();


1;