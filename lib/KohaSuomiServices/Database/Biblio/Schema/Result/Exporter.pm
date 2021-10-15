package KohaSuomiServices::Database::Biblio::Schema::Result::Exporter;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('exporter');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  interface_id => { data_type => 'integer', is_foreign_key => 1 },
  authuser_id => { data_type => 'integer', is_foreign_key => 1 },
  activerecord_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
  source_id => { data_type => 'varchar', size => 30, is_nullable => 1 },
  target_id => { data_type => 'varchar', size => 30, is_nullable => 1 },
  type => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/add update delete/]} },
  status => { data_type => 'varchar', is_enum => 1, extra => { list => [qw/pending success failed waiting/]} },
  errorstatus => { data_type => 'text' },
  parent_id => {data_type => 'varchar', size => 30, is_nullable => 1},
  force_tag => {data_type => 'integer', is_boolean  => 1, default_value => 0, false_is    => ['0', '-1']},
  componentparts => {data_type => 'integer', is_boolean  => 1, default_value => 0, false_is    => ['0', '-1']},
  componentparts_count => { data_type => 'integer', is_nullable => 1 },
  broadcast_record => {data_type => 'integer', is_boolean  => 1, default_value => 0, false_is    => ['0', '-1']},
  fetch_interface => { data_type => 'varchar', size => 30, is_nullable => 1 },
  diff => { data_type => 'longtext', default_value => '' },
  timestamp => { data_type => 'datetime', default_value => \"current_timestamp", is_nullable => 0 },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;