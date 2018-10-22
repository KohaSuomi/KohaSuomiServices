package KohaSuomiServices::Model::SRU;
use Mojo::Base -base;

use Modern::Perl;
use Try::Tiny;

use Mojo::JSON qw(decode_json encode_json);

has "convert";

sub search {
    my ($self, $params) = @_;

    try {

        my $path = $params->{url}."?operation=".$params->{operation}."&query=".$params->{query};
        $path .= defined $params->{maxrecords} ? "&version=".$params->{version} : "&version=1.1";
        $path .= defined $params->{maxrecords} ? "&maximumRecords=".$params->{maxrecords} : "&maximumRecords=1";
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(GET => $path);
        $tx = $ua->start($tx);
        my $records = $self->getRecords($tx->res->body);
        return $records;
        
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