package KohaSuomiServices::Database::Biblio::Schema::Result::UserLinks;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('userlinks');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  interface_id => { data_type => 'integer', is_foreign_key => 1 },
  authuser_id => { data_type => 'integer', is_foreign_key => 1 },
  username => { data_type => 'varchar', size => 30 }
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################
1;