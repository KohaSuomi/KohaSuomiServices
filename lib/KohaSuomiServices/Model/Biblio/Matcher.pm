package KohaSuomiServices::Model::Biblio::Matcher;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use List::MoreUtils qw(uniq);

use KohaSuomiServices::Database::Client;
use KohaSuomiServices::Model::Config;

has schema => sub {KohaSuomiServices::Database::Client->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has interface => sub {KohaSuomiServices::Model::Biblio::Interface->new};
has fields => sub {KohaSuomiServices::Model::Biblio::Fields->new};

sub find {
    my ($self, $client, $id, $type) = @_;
    my @data;
    @data = $client->resultset('Matcher')->search({interface_id => $id, type => $type}, {columns => [qw/tag code/]}) if $type ne "add";
    @data = $client->resultset('Matcher')->search({interface_id => $id, type => $type}, {columns => [qw/tag code value/]}) if $type eq "add";
    my %matchers;
    my @fields;
    my $matcher;
    foreach my $data (@data) {
        if ($data->value) {
            if ($matcher->{tag} eq $data->tag) {
                push @{$matcher->{subfields}}, {code => $data->code, value => $data->value};
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
    return %matchers if %matchers;
    @fields = uniq(@fields);
    return \@fields;
}

sub defaultSearchMatchers {
    return ("035" => "a", "020" => "a", "024" => "a", "027" => "a", "028" => ["a", "b"]);
}

sub fetchMatchers {
    my ($self, $interface_name, $interface_type, $identifier_name) = @_;

    my $schema = $self->schema->client($self->config);
    my $interface = $self->interface->load({name => $interface_name, type => $interface_type});
    return ($interface, $self->find($schema, $interface->{id}, $identifier_name));
}

sub removeMatchers {
    my ($self, $id) = @_;
    my $client = $self->schema->client($self->config);
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
    my $client = $self->schema->client($self->config);
    my $fields = $self->find($client, $id, "add");
    return $data unless defined $fields && $fields;

    foreach my $field (@{$fields}) {
        foreach my $subfield (@{$field->{subfields}}) {
            my $value = $self->fields->findValue($exporter_id, $field->{tag}, $subfield->{code});
            unless ($value) {
                push @{$data->{fields}}, $field;
            } else {
                last;
            }
        }
    }

    return $data;
}

1;