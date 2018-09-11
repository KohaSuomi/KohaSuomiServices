package KohaSuomiServices::Model::Biblio;

use Modern::Perl;

use JSON;
use Try::Tiny;
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);

sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;

    return $self;
}

sub find {
    my ($self, $biblionumber, $sessionid) = @_;

    try {
        
        my $path = $self->{config}->{koha_basepath}.'/api/v1/records/'.$biblionumber;
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(GET => $path);
        $tx->req->cookies({ name => 'CGISESSID', value => $sessionid });
        $tx = $ua->start($tx);
        return $tx->res->body;
    } catch {
        my $e = $_;
        return $e;
    }
    
}

sub search {
    my ($self, $params) = @_;

    try {
        
        my $path = $self->{config}->{koha_basepath}.'/api/v1/reports/batchOverlays/records';
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(GET => $path => form => $params);
        $tx = $ua->start($tx);
        return $tx->res->body;
    } catch {
        my $e = $_;
        return $e;
    }
}

sub get {
    my ($self, $interface, $id) = @_;
    
    try {
        my $path;
        if ($id) {
            $path = $interface->{url}.'/'.$id;
        } else {
            $path = $interface->{url};
        }
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(GET => $path);
        $tx = $ua->start($tx);
        return $tx->res->body;
    } catch {
        my $e = $_;
        return $e;
    }
    
}

sub update_remote {
    my ($self, $res) = @_;

}

sub add_remote {
    my ($self, $res) = @_;

}

1;