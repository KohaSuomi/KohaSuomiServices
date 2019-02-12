package KohaSuomiServices::Model::Biblio::Response;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);

use KohaSuomiServices::Model::Exception::NotFound;

has schema => sub {KohaSuomiServices::Database::Client->new};
has biblio => sub {KohaSuomiServices::Model::Biblio->new};
has exportauth => sub {KohaSuomiServices::Model::Biblio::ExportAuth->new};
has interface => sub {KohaSuomiServices::Model::Biblio::Interface->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};

sub getAndUpdate {
    my ($self, $interface, $params, $headers, $source_id) = @_;

    my $targetId = $self->parseResponse($interface, $params, $headers);
    return unless $targetId;
    my $schema = $self->schema->client($self->config);
    my $getInterface = $self->interface->load({name => $interface->{name}, type => "get"});
    my $path = $self->biblio->create_path($getInterface, $targetId);
    my $user = $self->exportauth->checkAuthUser($schema, undef, $getInterface->{id});
    my $authentication = $self->exportauth->interfaceAuthentication($getInterface, $user, $getInterface->{method});
    my ($resCode, $resBody, $resHeaders) = $self->biblio->callInterface($getInterface->{method}, $getInterface->{format}, $path, undef, $authentication);
    my $host = $self->interface->host("update");
    my $req = $resBody->{marcxml} ? {marc => $resBody->{marcxml}, source_id => $targetId->{target_id}, target_id => $source_id, interface => $host->{name}} : {marc => $resBody, source_id => $targetId->{target_id}, target_id => $source_id, interface => $host->{name}};
    $self->biblio->log->debug($req);
    $self->biblio->export($req);
}

sub parseResponse {
    my ($self, $interface, $params, $headers) = @_;
    my $match;
    my $identifier = $self->find({interface_id => $interface->{id}})->identifier_name if $self->find({interface_id => $interface->{id}});
    return {target_id => $headers->header($identifier)} if $headers->header($identifier);
    my @keys = %{$params} if (defined $params && ref($params) eq "HASH");
    foreach my $key (@keys) {
        if (ref($key) eq "HASH") {
            $match = $key->{$identifier};
            last if $key->{$identifier};
        }
    }
    return unless $match;
    return {target_id => $match};
}

sub find {
    my ($self, $params) = @_;
    my $client = $self->schema->client($self->config);
    return $client->resultset('Response')->find($params);
}

1;