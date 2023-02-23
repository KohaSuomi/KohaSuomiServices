package KohaSuomiServices::Database::Build;
use Mojo::Base -base;

use Modern::Perl;
use Try::Tiny;
use DBI;
use DBIx::Class::Migration;

use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;

use KohaSuomiServices::Model::Exception::Database::Upgrade;
use KohaSuomiServices::Model::Exception::Database::Install;

has schema => sub {KohaSuomiServices::Database::Client->new};

sub migrate {
    my ($self, $service) = @_;

    my $dbVersion;
    my $config = KohaSuomiServices::Model::Config->new->service($service)->load;
    my $version = $config->{database}->{version};
    my $schema = $self->schema->client($config);
    my $path = $config->{database}->{sharebase}."share/".$service."-schema/";

    my $migration = DBIx::Class::Migration->new(schema => $schema, target_dir => $path);
    if ($migration->dbic_dh->version_storage_is_installed()) {
        $dbVersion = $migration->dbic_dh->database_version();
        if ($dbVersion < $version) {
            try {
                $migration->prepare;
                $migration->upgrade();
                print "Database upgraded from version '$dbVersion' to version '$version'";
            } catch {
                KohaSuomiServices::Model::Exception::Database::Upgrade->throw(error => "Installed database version is '$dbVersion'. Unable to upgrade it to version '$version' automatically, error:\n  $_\nTry upgrading with 'dbic-migrate'");
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
            KohaSuomiServices::Model::Exception::Database::Install->throw(error => "Unable to install it automatically, error:\n  $_\nTry installing with 'dbic-migrate'");
        }
    }
}

1;
