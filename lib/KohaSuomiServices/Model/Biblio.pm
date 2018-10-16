package KohaSuomiServices::Model::Biblio;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);

has "sru";

sub export {
    my ($self, $schema, $params) = @_;

    try {
        my $interface_id = $self->get_inteface($schema, $params->{interface}, $params->{type});
        delete $params->{interface};
        $params->{interface_id} = $interface_id;
        $params->{status} = "pending";
        my $data = $schema->resultset('Exporter')->new($params);
        $data->insert();
        return "Success";
    } catch {
        my $e = $_;
        return $e;
    }
    
}

sub get_inteface {
    my ($self, $schema, $name, $type) = @_;
    my $params = {name => $name, type => $type};
    my $data = $schema->resultset("Interface")->search($params)->next;
    return $data->id;
    
}

sub find_local {
    my ($self, $biblionumber) = @_;

    try {
        my $path = $self->{config}->{kohabasepath}.'/api/v1/biblios/'.$biblionumber;
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(GET => $path);
        $tx = $ua->start($tx);
        return $tx->res->body;
    } catch {
        my $e = $_;
        return $e;
    }
    
}

sub find_remote {
    my ($self, $biblionumber, $sessionid) = @_;

    try {
        
        my $path = $self->{config}->{kohabasepath}.'/api/v1/records/'.$biblionumber;
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


sub update {
    my ($self, $res) = @_;

}

sub add {
    my ($self, $res) = @_;

}

1;