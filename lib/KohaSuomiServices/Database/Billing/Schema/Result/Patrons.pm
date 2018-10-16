package KohaSuomiServices::Database::Billing::Schema::Result::Patrons;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('patrons');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  borrowernumber => { data_type => 'integer', is_unique => 1 },
  cardnumber => { data_type => 'varchar', size => 225 },
  ssn => { data_type => 'varchar', size => 225 },
  child => { data_type => 'integer', is_boolean => 1 },
  parentnumber => { data_type => 'integer', is_unique => 1 },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;