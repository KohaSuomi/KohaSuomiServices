package KohaSuomiServices::Database::Client;
use Mojo::Base -base;

use Modern::Perl;
use DBIx::RunSQL;
use DBI;

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Biblio::Schema;
use KohaSuomiServices::Database::Billing::Schema;
use KohaSuomiServices::Model::Exceptions;

has exception => sub {KohaSuomiServices::Model::Exceptions->new};

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

    try {
        my $s = $schemapath->connect($dsn, $user, $pw) or die "Could not connect";
        return $s;
    } catch {
        my $e = $_;
        return $e
    }
}

sub client {
    my ($self, $service) = @_;
    $self->exception->NotFound("No database config found") unless $service;
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

sub billing {
    return "KohaSuomiServices::Database::Billing::Schema";
}

1;