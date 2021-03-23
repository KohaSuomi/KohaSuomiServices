package KohaSuomiServices::Model::Biblio::ExportAuth;
use Mojo::Base -base;

use Modern::Perl;
use utf8;
use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Database::Client;
use KohaSuomiServices::Model::Exception::NotFound;
use KohaSuomiServices::Model::Exception::BadParameter;
use Mojo::JSON qw(from_json);
use Mojo::URL;
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64;

has schema => sub {KohaSuomiServices::Database::Client->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has ua => sub {Mojo::UserAgent->new};
has log => sub {Mojo::Log->new(path => KohaSuomiServices::Model::Config->new->load->{"logs"}, level => KohaSuomiServices::Model::Config->new->load->{"log_level"})};


sub find {
    my ($self, $client, $params) = @_;
    return $client->resultset('AuthUsers')->find($params);
}

sub authorize {
    my ($self, $interface) = @_;

    my $schema = $self->schema->client($self->config);
    my $user = $self->checkAuthUser($schema, undef, $interface->{id});
    my $authentication = $self->interfaceAuthentication($interface, $user, $interface->{method});

    return $authentication;
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
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No authentication user\n") unless $authuser;
    return $authuser->id;
}

sub interfaceAuthentication {
    my ($self, $interface, $authuser, $method) = @_;

    my $schema = $self->schema->client($self->config);
    my $user = $self->find($schema, {id => $authuser});
    my $return;

    return unless $user;
    if ($interface->{auth_url}) {
        my $sign = $self->signIn($interface->{auth_url}, {userid => $user->username, password => decode_base64($user->password)});
        $return = $self->getCookie($interface->{params}, $sign);
    } else {
        $return = $self->getAuthorization($interface->{params}, $user, $method);
    }

    return $return;
}

sub signIn {
    my ($self, $path, $body) = @_;
    my $tx = $self->ua->post($path => form => $body);
    $self->log->debug($tx->res->error->{message}) if $tx->res->error;
    KohaSuomiServices::Model::Exception::BadParameter->throw(error => "Bad authuser parameters\n") if $tx->res->error;
    return from_json($tx->res->body);
}

sub getCookie {
    my ($self, $params, $matcher) = @_;

    my $cookie;
    foreach my $param (@{$params}) {
        if ($param->{type} eq "cookie") {
            my @valuematch = $param->{value} =~ /{(.*?)}/g;
            if (defined $valuematch[0]) {
                if ($matcher->{$valuematch[0]}) {
                    $cookie = {"Cookie: " => $param->{name}."=".$matcher->{$valuematch[0]}};
                }
            }
            last;
        }
    }
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No authorization cookie parameter\n") unless $cookie;
    return $cookie;

}

sub getAuthorization {
    my ($self, $params, $user, $method) = @_;

    my $authorization;
    foreach my $param (@{$params}) {
        if ($param->{type} eq "header" && $param->{name} eq "Authorization") {
            if ($param->{value} eq "Basic") {
                $authorization = $user->username.":".decode_base64($user->password);
            }
            if ($param->{value} eq "Koha") {
                my $date = Mojo::Date->new;
                my $message = join(' ', uc($method), $user->username, $date->to_string);
                my $digest = Digest::SHA::hmac_sha256_hex($message, $user->apikey);
                my $signature = "Koha ".$user->username.":".$digest;
                $authorization = {"Authorization" => $signature, "X-Koha-Date" => $date->to_string};
            }
            last;
        }
    }
    KohaSuomiServices::Model::Exception::NotFound->throw(error => "No authorization header parameter\n") unless $authorization;
    return $authorization;

}

sub basicAuthPath {
    my ($self, $path, $authentication) = @_;

    unless (ref($authentication) eq "HASH") {
        $path = Mojo::URL->new($path)->userinfo($authentication);
        $authentication = undef;
    }

    return ($path, $authentication);
}

1;