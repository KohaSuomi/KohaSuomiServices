package KohaSuomiServices::Model::Compare;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use Scalar::Util qw(looks_like_number);

has schema => sub {KohaSuomiServices::Database::Client->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has matchers => sub {KohaSuomiServices::Model::Biblio::Matcher->new};
has interface => sub {KohaSuomiServices::Model::Biblio::Interface->new};

sub getMandatory {
    my ($self, $source, $target) = @_;

    ############################### 
    # Mandatory for Aleph 
    # https://www.kiwi.fi/x/qYH9Ag
    my %targetmandatory = ("CAT" => 1, "LOW" => 1, "SID" => 1, "HLI" => 1, "DEL" => 1, "LDR" => 1, "STA" => 1, "COR" => 1);
    ###############################
    my ($numberpatch, $charpatch) = $self->findMatchingField($target, %targetmandatory, "mandatory");
    my $sorted;
    if ($numberpatch || $charpatch) {

        foreach my $nfield (@{$numberpatch}) {
            my $valid = $nfield;
            foreach my $f (@{$source->{fields}}) {
                if ($nfield->{tag} eq $f->{tag}) {
                    $valid = undef;
                }
            }
            push @{$source->{fields}}, $valid if ($valid);
        }
        
        #my $fields = $self->sortFields($source->{fields});
        #$source->{fields} = $fields;

        foreach my $cfield (@{$charpatch}) {
            push @{$source->{fields}}, $cfield;
        }
    }
}

sub findMatchingField {
    my ($self, $target, %matching_field) = @_;

    my ($numberpatch, $charpatch);

    foreach my $field (@{$target->{fields}}) {
        my $tag = $field->{tag};
        if ($matching_field{$field->{tag}} && $field->{tag} =~ s/^[0-9]//g) {
            $field->{tag} = $tag;
            my $match = $self->findMatchingSubfield($field, $matching_field{$field->{tag}});
            if($match) {
                push @{$numberpatch}, $field;
            }
        }

        if ($matching_field{$field->{tag}} && $field->{tag} =~ s/^[A-Za-z]//g) {
            $field->{tag} = $tag;
            my $match = $self->findMatchingSubfield($field, $matching_field{$field->{tag}});
            if($match) {
                push @{$charpatch}, $field;
            }
        }
    }

    return ($numberpatch, $charpatch);
}

sub findMatchingSubfield {
    my ($self, $field, $matching_subfield) = @_;
    my $match = 1;
    if (ref($matching_subfield) eq "HASH") {
        foreach my $subfield (@{$field->{subfields}}) {
            if ($matching_subfield->{$subfield->{code}} eq $subfield->{value}) {
                last;
            } else {
                $match = 0;
            }
        }
    }
    return $match;
}

sub matchingFieldCheck {
    my ($self, $source, $interface_name, $type) = @_;
    my $schema = $self->schema->client($self->config);
    my $interface = $self->interface->load({name => $interface_name, type => "search"});
    my %matchers = $self->matchers->find($schema, $interface->{id}, $type);
    return 1 unless %matchers;
    my ($numberpatch, $charpatch) = $self->findMatchingField($source, %matchers);
    return ($numberpatch, $charpatch);
    
}

sub sortFields {
    my ($self, $fields) = @_;

    my $hash;
    my $charhash;
    my $count = 1;

    foreach my $field (@{$fields}) {
        if (looks_like_number($field->{tag})) {
            $hash->{$count} = $field;
        } else {
            $charhash->{$count} = $field;
        }
        $count++;
    }

    my $sorted; 

    foreach my $key (sort {$hash->{$a}->{'tag'} <=> $hash->{$b}->{'tag'}} keys %$hash) {
        $hash->{$key}->{tag} = "".$hash->{$key}->{tag};
        push @{$sorted}, $hash->{$key};
    }

    foreach my $key (sort {$charhash->{$a} <=> $charhash->{$b}} keys %$charhash) {
        push @{$sorted}, $charhash->{$key};
    }

    return $sorted;
}

sub intCompare {
    my ($self, $export_value, $remote_value) = @_;

    my $abort = 0;
    if (int($export_value) < int($remote_value)) {
        $abort = 1;   
    }

    return $abort;

}

1;