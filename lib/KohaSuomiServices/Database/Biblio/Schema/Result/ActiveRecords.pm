package KohaSuomiServices::Database::Biblio::Schema::Result::ActiveRecords;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('activerecords');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  interface_name => { data_type => 'varchar'},
  identifier => { data_type => 'varchar' },
  identifier_field => { data_type => 'varchar' },
  target_id => { data_type => 'varchar' },
  updated => { data_type => 'datetime', is_nullable => 1},
  created => { data_type => 'datetime', default_value => \"current_timestamp", is_nullable => 0},
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;