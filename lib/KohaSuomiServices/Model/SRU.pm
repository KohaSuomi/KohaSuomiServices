package KohaSuomiServices::Model::SRU;
use Mojo::Base -base;

use Modern::Perl;
use Try::Tiny;

use Mojo::JSON qw(decode_json encode_json);
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;

has ua => sub {Mojo::UserAgent->new};
has convert => sub {KohaSuomiServices::Model::Convert->new};

sub search {
    my ($self, $params) = @_;

    try {

        my $path = $params->{url}."?operation=".$params->{operation}."&query=".$params->{query};
        $path .= defined $params->{version} ? "&version=".$params->{version} : "&version=1.1";
        $path .= defined $params->{maxrecords} ? "&maximumRecords=".$params->{maxrecords} : "&maximumRecords=1";
        my $tx = $self->ua->build_tx(GET => $path);
        $tx = $self->ua->start($tx);
        my $records = $self->getRecords($tx->res->body);
        return $records;
        
    } catch {
        my $e = $_;
        return $e;
    }
}

sub explain {
    my ($self, $params) = @_;

    try {

        my $path = $params->{url}."?operation=explain";
        $path .= defined $params->{version} ? "&version=".$params->{version} : "&version=1.1";
        my $tx = $self->ua->build_tx(GET => $path);
        $tx = $self->ua->start($tx);
        my $xml = $self->convert->xmltohash($tx->res->body);
        return $xml;
        
    } catch {
        my $e = $_;
        return $e;
    }
}

sub getRecords {
    my ($self, $res) = @_;
    try {
        my $xml = $self->convert->xmltohash($res);
        my $fields;
        my @records;
        if (ref($xml->{"zs:records"}->{"zs:record"}) eq "HASH") {
            my $data = $xml->{"zs:records"}->{"zs:record"}->{"zs:recordData"}->{"record"};
            push @records, $self->convert->formatjson($data);
        } else {
            foreach my $record (@{$xml->{"zs:records"}->{"zs:record"}}) {
                my $data = $record->{"zs:recordData"}->{"record"};
                push @records, $self->convert->formatjson($data);
            }
        }

        return \@records;
    } catch {
        my $e = $_;
        return $e->{message};
    }
}

1;