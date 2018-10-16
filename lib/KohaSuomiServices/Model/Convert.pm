package KohaSuomiServices::Model::Convert;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use XML::Simple;


sub xmltohash {
    my ($self, $res) = @_;

    my $parser = XML::Simple->new();
    my $xml = $parser->XMLin($res, KeyAttr => []);

    return $xml;
}

sub formatdatafields {
    my ($self, $res) = @_;

    my %tags;
    foreach my $datafield (@{$res}) {
        my $tag = $datafield->{"tag"};
        if (ref($datafield->{"subfield"}) eq "HASH"){
            if( exists $tags{$tag} ) { 
                my $newtag = {
                    subfields => {$datafield->{"subfield"}->{"code"} => $datafield->{"subfield"}->{"content"}},
                    ind1 => $datafield->{"ind1"},
                    ind2 => $datafield->{"ind2"}
                };
                if (ref($tags{$tag}) eq "ARRAY") {
                    push @{ $tags{$tag} }, $newtag;
                } else {
                    my $temp = delete $tags{$tag};
                    push @{ $tags{$tag} }, $temp , $newtag;
                }
            } else {
                $tags{$tag} = {
                    subfields => {$datafield->{"subfield"}->{"code"} => $datafield->{"subfield"}->{"content"}},
                    ind1 => $datafield->{"ind1"},
                    ind2 => $datafield->{"ind2"}
                };
            }

        } else {
            my %f;
            foreach my $subfield (@{$datafield->{"subfield"}}) {
                if( exists $f{$subfield->{"code"}} ) {
                    if (ref($f{$subfield->{"code"}}) eq "ARRAY") {
                        push @{ $f{$subfield->{"code"}} }, $subfield->{"content"};
                    } else {
                        my $temp = delete $f{$subfield->{"code"}};
                        push @{ $f{$subfield->{"code"}} }, $temp , $subfield->{"content"};
                    }
                } else {
                    $f{$subfield->{"code"}} = $subfield->{"content"};
                }
            }

            if( exists $tags{$tag} ) { 
                my $newtag = {
                    subfields => \%f,
                    ind1 => $datafield->{"ind1"},
                    ind2 => $datafield->{"ind2"}
                };
                if (ref($tags{$tag}) eq "ARRAY") {
                    push @{ $tags{$tag} }, $newtag;
                } else {
                    my $temp = delete $tags{$tag};
                    push @{ $tags{$tag} }, $temp , $newtag;
                }
            } else {
                $tags{$tag} = {
                    subfields => \%f,
                    ind1 => $datafield->{"ind1"},
                    ind2 => $datafield->{"ind2"} 
                };
            }
        }
    }
    return \%tags;
}

sub formatcontrolfields {
    my ($self, $res) = @_;
    my $formated;
    my %tags;
    foreach my $controlfield (@{$res}) {
        my $tag = $controlfield->{"tag"};
        if( exists $tags{$tag} ) { 
            if (ref($tags{$tag}) eq "ARRAY") {
                push @{ $tags{$tag} }, $controlfield->{"content"};
            } else {
                my $temp = delete $tags{$tag};
                push @{ $tags{$tag} }, $temp , $controlfield->{"content"};
            }
        } else {
            $tags{$tag} = $controlfield->{"content"};
        }
    }
    return \%tags;
}

1;