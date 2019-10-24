package KohaSuomiServices::Database::Biblio::Schema::Result::Subfields;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('subfields');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  field_id => { data_type => 'integer', is_foreign_key => 1 },
  code => { data_type => 'varchar'},
  value => { data_type => 'text'}
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;