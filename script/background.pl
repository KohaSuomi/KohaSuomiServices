#!/usr/bin/perl

# Copyright 2019 KohaSuomi
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
use Getopt::Long qw(:config no_ignore_case);
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
use KohaSuomiServices::Model::Config;

my $print = 0;

GetOptions(
    'p|print'                     => \$print,
);

my $config = KohaSuomiServices::Model::Config->new->load->{background};
if (defined $config && $config) {
    my @arr = @{$config};
    foreach my $c (@arr) {
        my $string =  "perl $FindBin::Bin/koha_suomi_services $c";
        if ($print) {
            print "$string\n";
        } else {
            $string .= " > /dev/null 2>&1 &";
            system($string);
        }
        
    }
}