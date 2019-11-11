package KohaSuomiServices::Model::Biblio::Matcher;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use List::MoreUtils qw(uniq);

use KohaSuomiServices::Database::Client;
use KohaSuomiServices::Model::Packages::Biblio;

has packages => sub {KohaSuomiServices::Model::Packages::Biblio->new};

sub find {
    my ($self, $client, $id, $type) = @_;
    my @data;
    @data = $client->resultset('Matcher')->search({interface_id => $id, type => $type}, {columns => [qw/tag code/]}) if $type ne "add" && $type ne "copy";
    @data = $client->resultset('Matcher')->search({interface_id => $id, type => $type}, {columns => [qw/tag code value/]}) if $type eq "add" || $type eq "copy";
    my %matchers;
    my @fields;
    my $matcher;
    foreach my $data (@data) {
        if ($data->value) {
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
                push @{$matchers{$data->tag}}, $temp , $data->code;
            } else {
                $matchers{$data->tag} = $data->code;
            }
        }
    }
    return %matchers if $type ne "add" && $type ne "copy";
    @fields = uniq(@fields);
    return \@fields;
}

sub defaultSearchMatchers {
    return ("035" => "a", "020" => "a", "024" => "a", "027" => "a", "028" => ["a", "b"]);
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

    foreach my $weight (keys %{$weighted}) {
        $matchers = {};
        if ($weight eq "3") {
            $matchers->{"035a"} = %{$weighted}{$weight};
            unless ($matchers->{"035a"} =~ /^\(/){
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
        elsif ($weight eq "1") {
            $matchers->{"024a"} = %{$weighted}{$weight};
            $matchers->{"024a"} =~ s/\D//g;
            unless (length($matchers->{"024a"}) >= 10){
                delete $matchers->{"024a"};
                next;
            }
            last if $matchers->{"024a"};
        }
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
        return 3;
    }

    if ($matcher eq "020a") {
        return 2;
    }

    if ($matcher eq "024a") {
        return 1;
    }
}

sub addFields {
    my ($self, $id, $exporter_id, $data) = @_;
    my $client = $self->packages->schema->client($self->packages->config);
    my $fields = $self->find($client, $id, "add");
    return $data unless defined $fields && $fields;
    my $index = 0;
    my @fieldindexes;
    foreach my $field (@{$fields}) {
        foreach my $subfield (@{$field->{subfields}}) {
            my $value = $self->packages->fields->findValue($exporter_id, $field->{tag}, $subfield->{code});
            unless ($value) {
                push @fieldindexes, $index;
            } else {
                last;
            }
        }
        $index++;
    }
    @fieldindexes = uniq(@fieldindexes);
    foreach my $i (@fieldindexes) {
        push @{$data->{fields}}, @{$fields}[$i];
    }
    return $data;
}

1;