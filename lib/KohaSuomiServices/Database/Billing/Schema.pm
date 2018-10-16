package KohaSuomiServices::Database::Billing::Schema;

our $VERSION = 1;

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces();

sub build {
    my ($self, $schema, $path) = @_;
    my $dbVersion;

    my $migration = DBIx::Class::Migration->new(schema => $schema, target_dir => $path);
    if ($migration->dbic_dh->version_storage_is_installed()) {
        $dbVersion = $migration->dbic_dh->database_version();
        if ($dbVersion < $VERSION) {
            try {
                $migration->upgrade();
                print "Database upgraded from version '$dbVersion' to version '$VERSION'";
            } catch {
                my $e = $_;
                return $e
            }
        }
    }
    else {
        try {
            $migration->prepare;
            $migration->install_if_needed;
            $dbVersion = $migration->dbic_dh->database_version();
            print "Database version '$dbVersion' installed";
        } catch {
            my $e = $_;
            return $e
        }
    }
}

1;