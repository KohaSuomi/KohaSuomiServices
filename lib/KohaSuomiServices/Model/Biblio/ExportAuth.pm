package KohaSuomiServices::Model::Biblio::ExportAuth;
use Mojo::Base -base;

use Modern::Perl;

sub find {
    my ($self, $client, $params) = @_;
    return $client->resultset('ExportAuth')->search($params);
}

sub insert {
    my ($self, $client, $params) = @_;
    return $client->resultset('ExportAuth')->new($params)->insert();
}

sub findUserFromLink {
    my ($self, $client, $username, $interface_id) = @_;
    my $link = $client->resultset('UserLinks')->search({interface_id => $interface_id, username => $username})->next();
    return 0 unless $link;
    return $client->resultset('AuthUsers')->search({interface_id => $interface_id, id => $link->authuser_id})->next();
}

sub findFirstUser {
    my ($self, $client, $interface_id) = @_;
    return $client->resultset('AuthUsers')->search({interface_id => $interface_id})->next();
}

sub checkAuthUser {
    my ($self, $client, $username, $interface_id) = @_;
    my $authuser = $self->findUserFromLink($client, $username, $interface_id) ? $self->findUserFromLink($client, $username, $interface_id) : $self->findFirstUser($client, $interface_id);
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No authentication user") unless $authuser;
    return $authuser->id;
}

1;