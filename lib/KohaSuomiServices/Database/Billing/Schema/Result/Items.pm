package KohaSuomiServices::Database::Billing::Schema::Result::Items;
use base qw/DBIx::Class::Core/;


##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('items');
__PACKAGE__->add_columns(
  id => { data_type => 'integer',  is_auto_increment => 1 },
  itemnumber => { data_type => 'integer'},
  homebranch => { data_type => 'varchar', size => 10 },
  title => { data_type => 'varchar', size => 255 },
  author => { data_type => 'varchar', size => 255 },
  barcode => { data_type => 'varchar', size => 255 },
  replacementprice => { data_type => 'float' },
  publicationyear => { data_type => 'varchar', size => 255 },
);
__PACKAGE__->set_primary_key('id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

1;