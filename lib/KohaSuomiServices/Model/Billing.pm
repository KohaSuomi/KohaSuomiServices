package KohaSuomiServices::Model::Billing;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use Koha::Checkouts;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use KohaSuomiServices::Model::Auth;
use KohaSuomiServices::Database::Billing::Schema;
use DBIx::Class::ResultSet;

has "billing";

sub search {
    my ($self, $params) = @_;

    try {
        my $start = $params->{start};
        my $end   = $params->{end};
        my $page   = $params->{page} || 1;
        my $rows = $params->{rows} || 20;
        my $branchcode = $params->{branchcode};
        my $branchtype = $params->{branchtype};
        my $db = KohaSuomiServices::Database::Client->new({config => $self->{config}});
        my $schema = $db->connect();
        my @checkouts = $schema->resultset('Overdues')->search({
            duedate => { '-between' => [$start, $end] },
            $params->{branchtype} => $branchcode,
        },
        {   
            page => $params->{page},
            rows => $params->{chunks}
        }
        );

        my @data;
        foreach my $checkout (@checkouts) {
            my $cols = { $checkout->get_columns };
            my $patron = $schema->resultset('Patrons')->search({id => $checkout->patron_id})->next;
            my $item = $schema->resultset('Items')->search({id => $checkout->item_id})->next;
            $cols->{patron} = { $patron->get_columns };
            $cols->{item} = { $item->get_columns };
            push @data, $cols;
        }
        return \@data;
        
    } catch {
        my $e = $_;
        warn Data::Dumper::Dumper $e;
        return $e;
    }
}

sub get_borrower {
    my ($self, $borrowernumber, $sessionid) = @_;

    try {
        my $path = $self->{config}->{kohabasepath}.'/api/v1/patrons/'.$borrowernumber;
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(GET => $path);
        $tx->req->cookies({ name => 'CGISESSID', value => $sessionid });
        $tx = $ua->start($tx);
        return decode_json($tx->res->body);
        
    } catch {
        my $e = $_;
        return $e;
    }
}

sub get_item  {
    my ($self, $itemnumber) = @_;

    try {
        my $path = $self->{config}->{kohabasepath}.'/api/v1/items/'.$itemnumber;
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(GET => $path);
        $tx = $ua->start($tx);
        return decode_json($tx->res->body);
        
    } catch {
        my $e = $_;
        return $e;
    }
}

sub get_biblio  {
    my ($self, $biblionumber) = @_;

    try {
        my $path = $self->{config}->{kohabasepath}.'/api/v1/items/'.$biblionumber;
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(GET => $path);
        $tx = $ua->start($tx);
        return decode_json($tx->res->body);
        
    } catch {
        my $e = $_;
        return $e;
    }
}

1;


