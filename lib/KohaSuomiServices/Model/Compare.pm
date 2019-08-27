package KohaSuomiServices::Model::Compare;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;

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
    my ($numberpatch, $charpatch) = $self->findMandatory($target, %targetmandatory);
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

        my $fields = $self->sortFields($source->{fields});
        $source->{fields} = $fields;

        foreach my $cfield (@{$charpatch}) {
            push @{$source->{fields}}, $cfield;
        }
    }
}

sub findMandatory {
    my ($self, $target, %mandatory) = @_;

    my ($numberpatch, $charpatch);

    foreach my $field (@{$target->{fields}}) {
        my $tag = $field->{tag};
        if ($mandatory{$field->{tag}} && $field->{tag} =~ s/^[0-9]//g) {
            $field->{tag} = $tag;
            push @{$numberpatch}, $field;
        }

        if ($mandatory{$field->{tag}} && $field->{tag} =~ s/^[A-Za-z]//g) {
            $field->{tag} = $tag;
            push @{$charpatch}, $field;
        }
    }

    return ($numberpatch, $charpatch);
}

sub mandatoryCheck {
    my ($self, $source, $interface_name) = @_;
    my $schema = $self->schema->client($self->config);
    my $interface = $self->interface->load({name => $interface_name, type => "search"});
    my %matchers = $self->matchers->find($schema, $interface->{id}, "mandatory");
    return 1 unless %matchers;
    my ($numberpatch, $charpatch) = $self->findMandatory($source, %matchers);
    return ($numberpatch, $charpatch);
    
}

sub sortFields {
    my ($self, $fields) = @_;

    my $hash;
    my $count = 1;

    foreach my $field (@{$fields}) {
        $hash->{$count} = $field;
        $count++;
    }

    my $sorted; 

    foreach my $key (sort {$hash->{$a}->{'tag'} <=> $hash->{$b}->{'tag'}} keys %$hash) {
        push @{$sorted}, $hash->{$key};
    }

    return $sorted;
}

1;