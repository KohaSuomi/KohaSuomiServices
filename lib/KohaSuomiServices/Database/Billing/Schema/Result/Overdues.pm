package KohaSuomiServices::Database::Billing::Schema::Result::Overdues;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('overdues');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  patron_id => { data_type => 'integer', is_foreign_key => 1 },
  item_id => { data_type => 'integer', is_foreign_key => 1 },
  issuebranch => { data_type => 'varchar', size => 10 },
  itembranch => { data_type => 'varchar', size => 10 },
  issue_id => { data_type => 'integer', is_unique => 1 },
  duedate => { data_type => 'datetime', set_on_update => 1 },
  timestamp => { data_type => 'datetime', set_on_create => 1 },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;