package KohaSuomiServices::Model::Biblio::Interface;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);
use KohaSuomiServices::Model::Biblio::Parameter;

use KohaSuomiServices::Model::Exception::NotFound;

has schema => sub {KohaSuomiServices::Database::Client->new};
has parameter => sub {KohaSuomiServices::Model::Biblio::Parameter->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has exportauth => sub {KohaSuomiServices::Model::Biblio::ExportAuth->new};
has ua => sub {Mojo::UserAgent->new};

sub load {
    my ($self, $params, $force) = @_;

    my $client = $self->schema->client($self->config);
    my $localInterface = $client->resultset("Interface")->search($params)->next;
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No ".$params->{type}." interface defined for ".$params->{name}) unless $localInterface;
    my $interfaceParams = defined $force && $force ? $self->parameter->find({interface_id => $localInterface->id}) : $self->parameter->find({interface_id => $localInterface->id, force_tag => 0});
    return $self->parse($localInterface, $interfaceParams);
}

sub find {
    my ($self, $params) = @_;

    my $client = $self->schema->client($self->config);
    my @localInterface = $client->resultset("Interface")->search($params);
    return $self->schema->get_columns(@localInterface);
}

sub parse {
    my ($self, $interface, $params) = @_;

    my $res->{id} = $interface->id;
    $res->{name} = $interface->name;
    $res->{endpoint_url} = $interface->endpoint_url;
    $res->{interface} = $interface->interface;
    $res->{type} = $interface->type;
    $res->{auth_url} = $interface->auth_url;
    $res->{method} = $interface->method;
    $res->{format} = $interface->format;
    $res->{params} = $params;

    return $res;
}

sub host {
    my ($self, $type) = @_;
    return $self->load({host => 1, type => $type});
}

sub buildTX {
    my ($self, $method, $format, $path, $body, $authentication, $headers) = @_;

    ($path, $authentication) = $self->exportauth->basicAuthPath($path, $authentication);
    if ($headers && ref($headers) eq 'HASH') {
        $headers = {%$headers, %$authentication};
    } else if (!$headers && $authentication){
        $headers = $authentication;
    } else {
        $headers = {};
    }
    
    if (defined $format && ($format eq "json" || $format eq "form")) {
        return $self->ua->inactivity_timeout($self->config->{inactivitytimeout})->$method($path => $headers => $format => $body) if defined $body && $body;
        return $self->ua->inactivity_timeout($self->config->{inactivitytimeout})->$method($path => $headers);
    }

    return $self->ua->inactivity_timeout($self->config->{inactivitytimeout})->$method($path => $headers => $body) if defined $body && $body;
    return $self->ua->inactivity_timeout($self->config->{inactivitytimeout})->$method($path => $headers);
}

1;