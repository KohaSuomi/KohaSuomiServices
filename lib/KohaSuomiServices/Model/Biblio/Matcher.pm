package KohaSuomiServices::Model::Biblio::Matcher;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use List::MoreUtils qw(uniq);
use Scalar::Util qw(looks_like_number);

use KohaSuomiServices::Database::Client;
use KohaSuomiServices::Model::Packages::Biblio;

has packages => sub {KohaSuomiServices::Model::Packages::Biblio->new};

sub find {
    my ($self, $client, $id, $type) = @_;
    my @data;
    @data = $client->resultset('Matcher')->search({interface_id => $id, type => $type}, {columns => [qw/tag code value/]});
    my %matchers;
    my @fields;
    my $matcher;
    foreach my $data (@data) {
        if ($type eq "add" || $type eq "copy") {
            my @codes = split(/\|/, $data->code);
            my @values = split(/\|/, $data->value);
            if (scalar(@codes) > 1 && scalar(@values) > 1) {
                $matcher = {ind1 => "", ind2 => ""};
                $matcher->{tag} = $data->tag;
                my $index = 0;
                foreach my $code (@codes) {
                    push @{$matcher->{subfields}}, {code => $code, value => $values[$index]};
                    $index++;
                }
            } else {
                $matcher = {ind1 => "", ind2 => ""};
                $matcher->{tag} = $data->tag;
                push @{$matcher->{subfields}}, {code => $data->code, value => $data->value};
            }
            push @fields, $matcher;
        } else {
            if ($matchers{$data->tag}) {
                my $temp = delete $matchers{$data->tag};
                push (@{$matchers{$data->tag}->{$data->code}}, $temp , $data->value) if $data->value;
                push (@{$matchers{$data->tag}}, $temp , $data->code) if !$data->value;
            } else {
                $matchers{$data->tag}->{$data->code} = $data->value if $data->value;
                $matchers{$data->tag} = $data->code if !$data->value;
            }
        }
    }
    return %matchers if $type ne "add" && $type ne "copy";
    @fields = uniq(@fields);
    return \@fields;
}

sub defaultSearchMatchers {
    #return ("035" => "a", "020" => "a", "024" => "a", "027" => "a", "028" => ["a", "b"]);
    return ("035" => "a", "020" => "a", "024" => "a", "003" => {"" => "FI-BTJ"}, "001" => "");
}
sub fetchMatchers {
    my ($self, $interface_name, $interface_type, $identifier_name) = @_;

    my $schema = $self->packages->schema->client($self->packages->config);
    my $interface = $self->packages->interface->load({name => $interface_name, type => $interface_type});
    return ($interface, $self->find($schema, $interface->{id}, $identifier_name));
}

sub removeMatchers {
    my ($self, $id) = @_;
    my $client = $self->packages->schema->client($self->packages->config);
    return $self->find($client, $id, "remove");
}

sub targetMatchers {
    my ($self, $matchers) = @_;
    
    return unless $matchers;
    
    my $weighted;
    foreach my $matcher (keys %{$matchers}) {
        if($self->weightMatchers($matcher) && (%{$matchers}{$matcher} =~ /\d/ || $matcher eq '035a')) {
            $weighted->{$self->weightMatchers($matcher)} = %{$matchers}{$matcher};
        }
    }
    foreach my $weight (sort keys %{$weighted}) {
        $matchers = {};
        if ($weight eq "1") {
            $matchers->{"035a"} = %{$weighted}{$weight};
            if (ref($matchers->{"035a"}) eq "ARRAY") {
                foreach my $match (@{$matchers->{"035a"}}) {
                    if ($match =~ /FI-MELINDA/) {
                        $matchers->{"035a"} = $match;
                        last;
                    } elsif ($match =~ /FI-BTJ/) {
                        $matchers->{"035a"} = $match;
                        last;
                    } else {
                        delete $matchers->{"035a"};
                        next;
                    }
                }
            }
            elsif ($matchers->{"035a"} !~ /^\(/){
                delete $matchers->{"035a"};
                next;
            }
            last if $matchers->{"035a"};
        }
        elsif ($weight eq "2") {
            $matchers->{"020a"} = %{$weighted}{$weight};
            $matchers->{"020a"} =~ s/\D//g;
            unless (length($matchers->{"020a"}) >= 10){
                delete $matchers->{"020a"};
                next;
            }
            last if $matchers->{"020a"};
        }
        elsif ($weight eq "3") {
            $matchers->{"024a"} = %{$weighted}{$weight};
            $matchers->{"024a"} =~ s/\D//g;
            unless (length($matchers->{"024a"}) >= 10){
                delete $matchers->{"024a"};
                next;
            }
            last if $matchers->{"024a"};
        }
    }

    unless ($matchers->{"001"} && $matchers->{"003"}) {
        delete $matchers->{"001"};
        delete $matchers->{"003"};
    }

    unless ($matchers->{"028a"} && $matchers->{"028b"}) {
        delete $matchers->{"028a"};
        delete $matchers->{"028b"};
    }
    
    return $matchers;
}

sub weightMatchers {
    my ($self, $matcher) = @_;

    if ($matcher eq "035a") {
        return 1;
    }

    if ($matcher eq "020a") {
        return 2;
    }

    if ($matcher eq "024a") {
        return 3;
    }
}

sub modifyFields {
    my ($self, $id, $exporter_id, $data) = @_;

    $data = $self->addFields($id, $exporter_id, $data, "copy");
    $data = $self->addFields($id, $exporter_id, $data, "add");

    #my $fields = $self->packages->compare->sortFields($data->{fields});
    #$data->{fields} = $fields;

    return $data;
}

sub addFields {
    my ($self, $id, $exporter_id, $data, $type) = @_;
    my $client = $self->packages->schema->client($self->packages->config);
    my $fields = $self->find($client, $id, $type);
    return $data unless defined $fields && $fields;
    my $index = 0;
    my @fieldindexes;
    foreach my $field (@{$fields}) {
        foreach my $subfield (@{$field->{subfields}}) {
            my $value = $self->packages->fields->findValue($exporter_id, $field->{tag}, $subfield->{code});
            unless ($value) {
                if ($type eq "copy") {
                    my @copyfields = split(/\|/, $subfield->{value});
                    foreach my $copyfield (@copyfields) {
                        my @fieldcode = $copyfield =~ /{(.*?)}/g;
                        my ($tag, $code) = $self->splitField($fieldcode[0]);
                        my $f = $self->packages->fields->findValue($exporter_id, $tag, $code);
                        $subfield->{value} =~ s/{$fieldcode[0]}/$f/g;
                    }
                    $subfield->{value} =~ tr/|//d;
                }
                push @fieldindexes, $index;
            } else {
                last;
            }
        }
        $index++;
    }
    @fieldindexes = uniq(@fieldindexes);
    foreach my $i (@fieldindexes) {
        my $add = 1;
        my $newfield = @{$fields}[$i];
        foreach my $field (@{$data->{fields}}) {
            if ($newfield->{tag} eq $field->{tag}) {
                $add = $self->compareArrays($newfield->{subfields}, $field->{subfields});
                last unless $add;   
            }
        }
        if ($add) {
            push @{$data->{fields}}, $newfield;
        }
    }
    return $data;
}

sub splitField {
    my ($self, $field) = @_;

    $field =~ /(\d+)/g;
    my $tag = $1;
    $field =~ /(\w+)/g;
    my $code = $1 unless looks_like_number($1);

    return ($tag, $code);

}

sub compareArrays {
    my ($self, $array1, $array2) = @_;

    my $notequal = 1;
    my $arr1string = '';
    my $arr2string = '';

    foreach my $arr1 (@{$array1}) {
        $arr1string .= $arr1->{code};
        $arr1string .= $arr1->{value};
    }

    foreach my $arr2 (@{$array2}) {
        $arr2string .= $arr2->{code};
        $arr2string .= $arr2->{value};
    }

    if ($arr1string eq $arr2string) {
        $notequal = 0;
    }

    return $notequal;
}

1;