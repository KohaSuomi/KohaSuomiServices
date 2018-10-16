package KohaSuomiServices::Database::Billing::Build;

use Modern::Perl;
use DBI;
use C4::Context;
use Date::Manip;
use Koha::Checkouts;

use KohaSuomiServices::Database::Client;
use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Billing::Schema;

sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;

    return $self;
}

sub build {
    my ($self, $params) = @_;

    my $end = DateCalc(ParseDate("today"), ParseDateDelta('- '.$params->{delay}.' days'));
    my $start = DateCalc(ParseDate($end), ParseDateDelta('- '.$params->{maxdays}.' days'));
    $params->{end} = UnixDate( $end, ( '%Y-%m-%d' ) );
    $params->{start} = UnixDate( $start, ( '%Y-%m-%d' ) );

    my $service = KohaSuomiServices::Model::Config->new({config => $self->{config}});
    my $config = $service->get("billing");
    my $db = KohaSuomiServices::Database::Client->new({config => $config});
    my $schema = $db->connect();
    my $page = 1;
    while ($page >= $params->{page}) {
        my $checkouts = $self->overdues($params);
        my $count = 0;
        foreach my $checkout (@{$checkouts}) {

            my $row = {issue_id => $checkout->{issue_id}};
            my $check = $schema->resultset('Overdues')->search($row)->next;
            if (defined $check) {
                next;
            }

            my $p;
            my $borrower = $self->patrons($checkout->{borrowernumber}, $schema);
            my ($item, $homebranch) = $self->items($checkout->{itemnumber}, $schema);
            $p->{issuebranch} = $checkout->{branchcode};
            $p->{itembranch} = $homebranch;
            $p->{patron_id} = $borrower;
            $p->{item_id} = $item;
            $p->{duedate} = $checkout->{date_due};
            $p->{issue_id} = $checkout->{issue_id};
            my $newdata = $schema->resultset('Overdues')->new($p);
            $newdata->insert();
            $count++;

        }
        print "$count overdues built!\n";
        if ($count eq $params->{chunks}) {
            $page++;
            $params->{page} = $page;
        } else {
            $page = 0;
        }
    }
}

sub overdues {
    my ($self, $params) = @_;
    print "Starting building page $params->{page}!\n";
    my $start = $params->{start};
    my $end = $params->{end};
    my $checkouts = Koha::Checkouts->search({
        date_due => { '-between' => [$start, $end] },
    },
    {   
        page => $params->{page},
        rows => $params->{chunks}
    }
    )->unblessed;

    return $checkouts;
    
}

sub patrons {
    my ($self, $borrowernumber, $schema) = @_;

    my $row = {borrowernumber => $borrowernumber};
    my $check = $schema->resultset('Patrons')->search($row)->next;
    if (defined $check) {
        return $check->id;
    }
    
    my $patron = Koha::Patrons->find($borrowernumber)->unblessed;
    my $params = {
        borrowernumber => $patron->{borrowernumber},
        cardnumber => $patron->{cardnumber}
    };
    if ($patron->{guarantorid}) {
        $params->{parentnumber} = $patron->{guarantorid};
        $params->{child} = 1;
    }
    my $newdata = $schema->resultset('Patrons')->new($params);
    $newdata->insert();
    return $newdata->id;  
}

sub items {
    my ($self, $itemnumber, $schema) = @_;

    my $row = {itemnumber => $itemnumber};
    my $check = $schema->resultset('Items')->search($row)->next;
    if (defined $check) {
        return ($check->id, $check->homebranch);
    }
    
    my $item = Koha::Items->find($itemnumber)->unblessed;
    my $params = {
        itemnumber => $item->{itemnumber},
        barcode => $item->{barcode},
        replacementprice => $item->{replacementprice},
        homebranch => $item->{homebranch}
    };
    
    my $biblio = Koha::Biblios->find($item->{biblionumber})->unblessed;
    $params->{author} = $biblio->{author};
    $params->{title} = $biblio->{title};
    $params->{publicationyear} = $biblio->{publicationyear};
    my $newdata = $schema->resultset('Items')->new($params);
    $newdata->insert();
    return ($newdata->id, $newdata->homebranch);

}

1;