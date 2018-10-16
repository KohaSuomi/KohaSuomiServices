package KohaSuomiServices::Database::Biblio::Schema::Result::Interface;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('interface');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 255 },
  interface => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/REST SRU/]} },
  type => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/search get add update delete/]} },
  endpoint_url => { data_type => 'varchar', size => 255 },
  local => { data_type => 'integer', is_boolean => 1 },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;