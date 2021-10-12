package KohaSuomiServices::Database::Biblio::Schema::Result::ComponentParts;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('componentparts');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  source_id => { data_type => 'varchar', size => 50, is_nullable => 1 },
  parent_id => { data_type => 'varchar', size => 50, is_nullable => 1 },
  marc => { data_type => 'longtext', default_value => '' },
  pushed => {data_type => 'integer', is_boolean  => 1, default_value => 0, false_is    => ['0', '-1']},
  created => { data_type => 'datetime', default_value => \"current_timestamp", is_nullable => 0},
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;