package KohaSuomiServices::Database::Biblio::Schema::Result::Exporter;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('exporter');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  interface_id => { data_type => 'integer', is_foreign_key => 1 },
  authuser_id => { data_type => 'integer', is_foreign_key => 1 },
  target_id => { data_type => 'varchar' },
  type => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/add update delete/]} },
  status => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/pending success fail/]} },
  timestamp => { data_type => 'datetime', default_value => \"current_timestamp", is_nullable => 0 },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;