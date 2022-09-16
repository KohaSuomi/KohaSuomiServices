package KohaSuomiServices::Database::Client;
use Mojo::Base -base;

use Modern::Perl;
use DBI;

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Biblio::Schema;


use KohaSuomiServices::Model::Exception::NotFound;

sub connect {
    my ($self) = @_;
    
    my $user = $self->{config}->{database}->{user};
    my $pw = $self->{config}->{database}->{password};
    my $host = $self->{config}->{database}->{host};
    my $port = $self->{config}->{database}->{port};
    my $schema = $self->{config}->{database}->{schema};
    my $service = $self->{config}->{route};

    my $dsn = "dbi:mysql:".$schema.":".$host.":".$port;
    my $schemapath = $self->$service;

    my ( %encoding_attr, $encoding_query, $tz_query );
    my $tz = $ENV{TZ};
    %encoding_attr = ( mysql_enable_utf8 => 1 );
    $encoding_query = "set NAMES 'utf8'";
    $tz_query = qq(SET time_zone = "$tz") if $tz;

    try {
        my $s = $schemapath->connect(
            {
                dsn => $dsn,
                user => $user,
                password => $pw,
                %encoding_attr,
                unsafe => 1,
                quote_names => 1,
                on_connect_do => [
                    $encoding_query || (),
                    $tz_query || (),
                ]
            }
        ) or die "Could not connect";
        return $s;
    } catch {
        my $e = $_;
        return $e
    }
}

sub client {
    my ($self, $service) = @_;
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No database config found") unless $service;
    $self->{config} = $service;
    my $schema = $self->connect();
    return $schema;
}


sub get_columns {
    my ($self, @rs) = @_;

    my @data;

    foreach my $rs (@rs) {
        my $cols = { $rs->get_columns };
        push @data, $cols;
    }

    return \@data;
}

sub biblio {
    return "KohaSuomiServices::Database::Biblio::Schema";
}

1;