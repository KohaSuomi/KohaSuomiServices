package KohaSuomiServices::Database::Biblio::Schema::Result::Fields;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('fields');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  exporter_id => { data_type => 'integer', is_foreign_key => 1 },
  tag => { data_type => 'varchar', size => 3, default_value => ''},
  ind1 => { data_type => 'varchar', size => 1, default_value => ''},
  ind2 => { data_type => 'varchar', size => 1, default_value => ''},
  value => { data_type => 'varchar', size => 255, default_value => ''},
  type => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/leader controlfield datafield /]} },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

sub sqlt_deploy_hook {
  my ($self, $sqlt_table) = @_;

  $sqlt_table->add_index(name => 'exporter_index', fields => ['exporter_id']);
}

1;
