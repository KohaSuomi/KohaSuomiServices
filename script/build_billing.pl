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
use KohaSuomiServices::Database::Billing::Build;
use Mojolicious::Plugin::Config;
use Mojolicious::Lite;

my $help = 0;
my $delay = 10;
my $maxdays = 360;
my $chunks = 500;
my $page = 1;

GetOptions(
    'h|help'                      => \$help,
    'delay:i'                     => \$delay,
    'maxdays:i'                   => \$maxdays,
    'chunks:i'                   => \$chunks
);

my $usage = <<USAGE;
    Hello there!
USAGE

if ($help) {
    print $usage;
    exit 0;
}

my $params = {
    delay => $delay,
    maxdays => $maxdays,
    chunks => $chunks,
    page => $page
};

my $config = plugin Config => {file => '../koha_suomi_services.conf'};
my $build = KohaSuomiServices::Database::Billing::Build->new({config => $config}); 
$build->build($params);
