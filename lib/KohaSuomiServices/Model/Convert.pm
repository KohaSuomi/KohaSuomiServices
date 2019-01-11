package KohaSuomiServices::Model::Convert;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use XML::Simple;
use XML::LibXML;
use Unicode::Map;



sub xmltohash {
    my ($self, $res) = @_;
    my $xml = eval { XML::LibXML->load_xml(string => $res)};
    my @leader = $xml->getElementsByTagName('leader');
    my @controlfields = $xml->getElementsByTagName('controlfield');
    my @datafields = $xml->getElementsByTagName('datafield');
    my $hash;
    if ($leader[0])
        $hash->{leader} = $leader[0]->textContent;
        
        my @cf;
        foreach my $controlfield (@controlfields) {
            push @cf, {tag => $controlfield->getAttribute("tag"), content => $controlfield->textContent}
        }
        $hash->{controlfield} = \@cf;
        
        my @df;
        foreach my $datafield (@datafields) {
            my @subfields = $datafield->getElementsByTagName("subfield");
            my @sf;
            foreach my $subfield (@subfields){
                push @sf, {code => $subfield->getAttribute("code"), content => $subfield->textContent};
            }
            push @df, {tag => $datafield->getAttribute("tag"), ind1 => $datafield->getAttribute("ind1"), ind2 => $datafield->getAttribute("ind2"), subfield => \@sf}
        }
        $hash->{datafield} = \@df;
    }

    return $hash;
}

sub xmlescape {
    my ($self, $string) = @_;
    return XML::Simple->new()->escape_value($string);
}


sub formatjson {
    my ($self, $marcxml) = @_;

    my $data;
    if (ref($marcxml) eq "HASH") {
        $data = $marcxml;
    } else {
        $data = $self->xmltohash($marcxml);
    }
    my $format;
    $format->{leader} = $data->{"leader"};
    $format->{fields} = $self->formatfields($data->{"controlfield"}, $data->{"datafield"});
    return $format;

}

sub formatxml {
    my ($self, $marcjson) = @_;

    my $format = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    $format .= "<record>\n";
    $format .= "\t<leader>".$marcjson->{leader}."</leader>\n" if ($marcjson->{leader});
    foreach my $field (@{$marcjson->{fields}}) {
        if (defined $field->{value}) {
            $format .= "\t<controlfield tag=\"".$field->{tag}."\">".$self->xmlescape($field->{value})."</controlfield>\n";
        } else {
            $format .= "\t<datafield tag=\"".$field->{tag}."\" ind1=\"".$field->{ind1}."\" ind2=\"".$field->{ind2}."\">\n";
            foreach my $subfield (@{$field->{subfields}}) {
                $format .= "\t\t<subfield code=\"".$subfield->{code}."\">".$self->xmlescape($subfield->{value})."</subfield>\n";
            }
            $format .= "\t</datafield>\n";
        }
    }
    $format .= "</record>";

    return $format;

}

sub formatfields {
    my ($self, $controlfields, $datafields) = @_;

    my @fields;
    my %filters;# = ("999" => "1", "942" => 1, "852" => 1);
    foreach my $controlfield (@{$controlfields}) {
        if (!$filters{$controlfield->{"tag"}}) {
            my $formated;
            $formated->{tag} = $controlfield->{"tag"};
            $formated->{value} = $controlfield->{"content"};
            push @fields, $formated;
        }
    }

    foreach my $datafield (@{$datafields}) {
        my $formated;
        my @subfields;
        if (!$filters{$datafield->{"tag"}}) {
            $formated->{tag} = $datafield->{"tag"};
            $formated->{ind1} = $datafield->{"ind1"};
            $formated->{ind2} = $datafield->{"ind2"};
            if (ref($datafield->{"subfield"}) eq "HASH"){
                push @subfields, {code => $datafield->{"subfield"}->{"code"}, value => $datafield->{"subfield"}->{"content"}}
            } else {
                foreach my $subfield (@{$datafield->{"subfield"}}) {
                    push @subfields, {code => $subfield->{"code"}, value => $subfield->{"content"}}
                }
            }
            $formated->{subfields} = \@subfields;
            push @fields, $formated;
        }
    }

    return \@fields;
}

1;