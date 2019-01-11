package KohaSuomiServices::Model::Compare;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use JSON::Patch qw(diff patch);

sub getMandatory {
    my ($self, $source, $target) = @_;

    
    my $targetpatch = $self->findMandatory($target);
    my $sorted;
    if ($targetpatch) {
        my $fields = $self->sortFields($source->{fields});
        $source->{fields} = $fields;
        foreach my $tfield (@{$targetpatch}) {
            push @{$source->{fields}}, $tfield;
        }
    }
}

sub findMandatory {
    my ($self, $target) = @_;

    my %mandatory = ("CAT" => 1);

    my $patch;

    foreach my $field (@{$target->{fields}}) {
        if ($mandatory{$field->{tag}}) {
            push @{$patch}, $field;
        }
    }

    return $patch;
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