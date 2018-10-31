package KohaSuomiServices::Database::Build;
use Mojo::Base -base;

use Modern::Perl;
use DBIx::RunSQL;
use DBI;
use DBIx::Class::Migration;

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;

has schema => sub {KohaSuomiServices::Database::Client->new};

sub migrate {
    my ($self, $service) = @_;

    my $dbVersion;
    my $config = KohaSuomiServices::Model::Config->new->service($service)->load;
    my $version = $config->{database}->{version};
    my $schema = $self->schema->client($config);
    my $path = "share/".$service."-schema/";

    my $migration = DBIx::Class::Migration->new(schema => $schema, target_dir => $path);
    if ($migration->dbic_dh->version_storage_is_installed()) {
        $dbVersion = $migration->dbic_dh->database_version();
        if ($dbVersion < $version) {
            try {
                $migration->upgrade();
                print "Database upgraded from version '$dbVersion' to version '$version'";
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