#!/usr/bin/perl

# Copyright 2018 KohaSuomi
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
use Carp;
use Getopt::Long qw(:config no_ignore_case);
use Mojolicious::Plugin::Config;
use Mojolicious::Lite;
use KohaSuomiServices::Database::Biblio::Schema;
use KohaSuomiServices::Database::Billing::Schema;

my $config = plugin Config => {file => '../koha_suomi_services.conf'};

foreach my $service (@{$config->{services}}) {
    my $db = KohaSuomiServices::Database::Client->new({config => $config});
    my $route = $service->{route};
    my $schemapath = $db->$route;
    my $path = "share/".$route."-schema/";
    $config->{service} = $route;
    my $schema = $db->client($service);
    $schemapath->build($schema, $path);
}
