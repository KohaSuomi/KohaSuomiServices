package KohaSuomiServices::Database::Biblio::Schema::Result::Fields;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('fields');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  exporter_id => { data_type => 'integer', is_foreign_key => 1 },
  tag => { data_type => 'varchar', size => 3},
  ind1 => { data_type => 'varchar', size => 1},
  ind2 => { data_type => 'varchar', size => 1},
  value => { data_type => 'varchar', size => 255},
  type => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/leader controlfield datafield /]} },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;