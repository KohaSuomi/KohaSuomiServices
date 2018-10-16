package KohaSuomiServices::Database::Biblio::Schema::Result::Merge;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('merge');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  localnumber => { data_type => 'integer' },
  remotenumber => { data_type => 'integer' },
  type => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/new update/]} },
  timestamp => { data_type => 'datetime', set_on_create => 1 },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;