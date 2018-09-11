package KohaSuomiServices::Database::Client;

use Modern::Perl;
use DBIx::RunSQL;
use DBI;

use Cwd;


sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;

    return $self;
}

sub connect {
    my ($self) = @_;
    
    my $user = $self->{config}->{database}->{user};
    my $pw = $self->{config}->{database}->{password};
    my $host = $self->{config}->{database}->{host};
    my $port = $self->{config}->{database}->{port};
    my $schema = $self->{config}->{database}->{schema};

    my $dsn = "dbi:mysql:".$schema.":".$host.":".$port;

    try {
        my $dbh = DBI->connect($dsn, $user, $pw) or die "Could not connect";
        $self->{dbh} = $dbh;
        return $self->{dbh};
    } catch {
        my $e = $_;
        return $e
    }
}

sub create {
    my ($self, $file) = @_;
    warn Data::Dumper::Dumper $self;
    my $cwd = getcwd();
    DBIx::RunSQL->run_sql_file(
        force   => 1,
        verbose => 1,
        dbh     => $self->{dbh},
        sql     => $cwd."/lib/KohaSuomiServices/Database/SQL/".$file,
    );

}

sub check_table {
    my ($self, $table) = @_;

    try {
        my $dbh = $self->{dbh};
        my $sth = $dbh->prepare("SELECT * FROM $table limit 1;");
        my $rv  = $sth->rows;
        return $rv;
    } catch {
        my $e = $_;
        return $e
    }
}

sub get_data {
    my ($self, $tablename, $keyvalues) = @_;

    try {
        my $dbh = $self->{dbh};
        my $query;
        $self->parse_sql($keyvalues, "select");
        my $table = $self->{table};
        my @values;
        if (defined $table) {
            @values = @{$self->{table}->{values}};
            $query = "SELECT * FROM $tablename WHERE ".$table->{count}.";";
        } else {
            $query = "SELECT * FROM $tablename;";
        }
        my $sth = $dbh->prepare($query);
        $sth->execute(@values) or die "Couldn't execute statement: " . $sth->errstr;
        my @arr;
        while (my $rv = $sth->fetchrow_hashref) {
            push @arr, $rv;
        }
        
        return \@arr;
    } catch {
        my $e = $_;
        return $e
    }
}

sub add_data {
    my ($self, $tablename, $keyvalues) = @_;

    try {
        my $dbh = $self->{dbh};
        $self->parse_sql($keyvalues, "insert");
        my $table = $self->{table};
        my @values = @{$self->{table}->{values}};
        my $sth = $dbh->prepare("INSERT INTO $tablename (".$table->{columns}.") VALUES (".$table->{count}.")");
        $sth->execute(@values) or die "Couldn't execute statement: " . $sth->errstr;
        my $rv = {message => "Success"};
        return $rv;
    } catch {
        my $e = $_;
        return $e
    }
}

sub update_data {
    my ($self, $tablename, $keyvalues, $id) = @_;

    try {
        my $dbh = $self->{dbh};
        my $query;
        $self->parse_sql($keyvalues, "update");
        my $table = $self->{table};
        my @values = @{$self->{table}->{values}};
        $query = "UPDATE $tablename set ".$table->{count}." WHERE id = ?;";
        warn Data::Dumper::Dumper $query;
        my $sth = $dbh->prepare($query);
        $sth->execute(@values, $id) or die "Couldn't execute statement: " . $sth->errstr;
        my $rv = {message => "Success"};
        return $rv;
    } catch {
        my $e = $_;
        return $e
    }
}

sub remove_data {
    my ($self, $tablename, $id) = @_;

    try {
        my $dbh = $self->{dbh};
        my $query;
        $query = "DELETE FROM $tablename WHERE id = ?;";
        my $sth = $dbh->prepare($query);
        $sth->execute($id) or die "Couldn't execute statement: " . $sth->errstr;
        my $rv = {message => "Success"};
        return $rv;
    } catch {
        my $e = $_;
        return $e
    }
}

sub parse_sql {
    my ($self, $keyvalues, $type) = @_;

    if (defined $keyvalues) {
        my @keys;
        my @valuecount;
        my @values; 
        my %keyval = %{$keyvalues};
        foreach my $key (keys %keyval) {
            push @keys, $key;
            push @valuecount, "?" if $type eq "insert";
            push @valuecount, $key."=?" if $type eq "select" || $type eq "update";
            push @values, $keyval{$key};
        }

        $self->{table}->{columns} = join(", ", @keys);
        $self->{table}->{count} = $type eq "insert" || $type eq "update" ? join(", ", @valuecount) : join(" and ", @valuecount);
        $self->{table}->{values} = \@values;
    }

    return $self;
}

1;