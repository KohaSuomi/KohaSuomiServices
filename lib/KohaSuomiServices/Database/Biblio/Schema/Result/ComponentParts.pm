package KohaSuomiServices::Database::Biblio::Schema::Result::ComponentParts;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('componentparts');
__PACKAGE__->add_columns(
  source_id => { data_type => 'varchar', size => 50 },
  parent_id => { data_type => 'varchar', size => 50, is_nullable => 1 },
  marc => { data_type => 'longtext', default_value => '' },
  updated => { data_type => 'datetime', is_nullable => 0}
);
__PACKAGE__->set_primary_key('source_id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

sub sqlt_deploy_hook {
  my ($self, $sqlt_table) = @_;

  $sqlt_table->add_index(name => 'parent_index', fields => ['parent_id']);
}

1;