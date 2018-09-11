# Koha Suomi Services

Koha Suomi services for different interfaces

## Getting Started

Clone this repo to your server and set up configuration file koha_suomi_services.conf to the root.

### Prerequisites

Install these CPAN packages to your environment. There is also a script in scripts/installdeps.sh for automating this. 

```
Try::Tiny
Modern::Perl
Mojolicious
Mojolicious::Plugin::OpenAPI
JSON
```

### Config file

Add config file to root directory. Decide which services you want to use and add configurations to them. There are two services available at the moment, biblio and billing.

```
{
  services => [
    { 
      route => 'biblio',
      koha_basepath => 'http://example.com',
      database => {
        host => '0.0.0.0',
        user => 'user',
        password => 'pass',
        port => '3306',
        schema => 'biblioservice'
      }
    }, 
    { 
      route => 'billing',
      database => {
        host => '0.0.0.0',
        user => 'user',
        password => 'pass',
        port => '3306',
        schema => 'billingservice'
      }
  }]
}


```

### Create databases

You can use same database user as Koha uses, remember to grant permissions.

```
mysql -u root -p
CREATE DATABASE <databasename>
GRANT ALL ON <databasename>.* TO 'kohaadmin'@'localhost' IDENTIFIED BY '{koha user password}';
FLUSH PRIVILEGES;
QUIT
```