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

Add config file to root directory. Copy koha_suomi_services.conf.example to koha_suomi_services.conf and change values to match your system.

### Apache proxy pass

Add proxy pass to Apache to access the service. Change port to match your Mojolicious port.

```
ProxyPass /service http://localhost:3000 keepalive=On
ProxyPassReverse /service http://localhost:3000
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