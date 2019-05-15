package KohaSuomiServices::Database::Biblio::Schema::Result::Interface;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('interface');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 50 },
  interface => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/REST SRU/]} },
  type => { data_type => 'enum', is_enum => 1, extra => { list => [qw/search get add update delete getcomponentparts/]} },
  method => { data_type => 'enum', is_enum => 1, is_nullable => 1, extra => { list => [qw/get post put patch delete/]} },
  format => { data_type => 'enum', is_enum => 1, is_nullable => 1, extra => { list => [qw/json form/]} },
  endpoint_url => { data_type => 'varchar', size => 255 },
  auth_url => { data_type => 'varchar', size => 255 },
  host => {data_type => 'integer', is_boolean  => 1, false_is    => ['0', '-1']},
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint("interface_type", ["name", "type"]);
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;