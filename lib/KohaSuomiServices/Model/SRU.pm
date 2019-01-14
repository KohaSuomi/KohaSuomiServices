package KohaSuomiServices::Model::SRU;
use Mojo::Base -base;

use Modern::Perl;
use utf8;
use Try::Tiny;
use List::Util qw<first>;

use Mojo::JSON qw(decode_json encode_json);
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use KohaSuomiServices::Model::Exception::NotFound;

has ua => sub {Mojo::UserAgent->new};
has convert => sub {KohaSuomiServices::Model::Convert->new};

sub search {
    my ($self, $params) = @_;

    KohaSuomiServices::Model::Exception::NotFound->throw(error => "SRU query parameter not found") unless $params->{query};
    my $path = $params->{url}."?operation=".$params->{operation}."&query=".$params->{query};
    $path .= defined $params->{version} ? "&version=".$params->{version} : "&version=1.1";
    $path .= defined $params->{maxrecords} ? "&maximumRecords=".$params->{maxrecords} : "&maximumRecords=1";
    my $tx = $self->ua->build_tx(GET => $path);
    $tx = $self->ua->start($tx);
    my $records = $self->getRecords($tx->res->body);
    return $records;
}

sub getRecords {
    my ($self, $res) = @_;

    try {
        #my $hash = $self->convert->xmltohash($res);
        my $fields;
        my @records;
        # my $records = first { m/records/ } keys %{$xml};
        # if ($records) {
        #     my $record = first { m/record/ } keys %{$xml->{$records}};
        #     my $recordData = first { m/recordData/ } keys %{$xml->{$records}->{$record}};
        #     my $marcrecord = first { m/record/ } keys %{$xml->{$records}->{$record}->{$recordData}};
            
        #     if (ref($xml->{$records}->{$record}) eq "HASH") {
        #         my $data = $xml->{$records}->{$record}->{$recordData}->{$marcrecord};
        #         push @records, $self->convert->formatjson($data);
        #     } else {
        #         foreach my $record (@{$xml->{$records}->{$record}}) {
        #             my $data = $record->{$recordData}->{$marcrecord};
        #             push @records, $self->convert->formatjson($data);
        #         }
        #     }
        # }
        push @records, $self->convert->formatjson($res);
        return \@records;
    } catch {
        my $e = $_;
        return $e->{message};
    }
}

1;