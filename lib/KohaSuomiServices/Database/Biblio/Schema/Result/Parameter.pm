package KohaSuomiServices::Database::Biblio::Schema::Result::Parameter;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('parameter');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  interface_id => { data_type => 'integer', is_foreign_key => 1 },
  name => { data_type => 'varchar', size => 255 },
  type => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/query path body cookie header/]} },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;