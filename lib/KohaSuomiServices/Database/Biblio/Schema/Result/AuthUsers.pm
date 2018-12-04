package KohaSuomiServices::Database::Biblio::Schema::Result::AuthUsers;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('authusers');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  interface_id => { data_type => 'integer', is_foreign_key => 1 },
  username => { data_type => 'varchar', size => 20 },
  password => { data_type => 'varchar', size => 255 },
  apikey => { data_type => 'varchar', size => 255 }
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;