package KohaSuomiServices::Database::Biblio::Schema::Result::Matcher;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('matcher');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  interface_id => { data_type => 'integer', is_foreign_key => 1 },
  tag => { data_type => 'varchar', size => 255 },
  code => { data_type => 'varchar', size => 255 },
  value => { data_type => 'varchar', size => 255 },
  type => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/identifier remove mandatory add copy duplicate/]} },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  "interface",
  "KohaSuomiServices::Database::Biblio::Schema::Result::Interface",
  { id => "interface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;
