package KohaSuomiServices::Model::Auth;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use Digest::SHA qw(hmac_sha256_hex);
use KohaSuomiServices::Model::Config;
use Mojo::JSON qw(decode_json encode_json);
use KohaSuomiServices::Model::Exception::Unauthorized;

has config => sub {KohaSuomiServices::Model::Config->new->load};

sub valid {
    my ($self, $token) = @_;

    my $apikey = Digest::SHA::hmac_sha256_hex($self->config->{apikey});
    KohaSuomiServices::Model::Exception::Unauthorized->throw(error => "Unauthorized access") unless ($apikey eq $token);
}

sub get {
    my ($self, $sessionid) = @_;

    try {
        my $path = $self->config->{kohabasepath}.'/api/v1/auth/session';
        my $ua = Mojo::UserAgent->new;
        my $params = {sessionid => $sessionid};
        my $tx = $ua->build_tx(GET => $path => {Accept => 'application/json'} => json => $params);
        $tx = $ua->start($tx);
        my $res = decode_json($tx->res->body);
        return $res->{sessionid};
    } catch {
        my $e = $_;
        return $e;
    }
}

sub login {
    my ($self, $params) = @_;

    try {
        my $path = $self->config->{internalloginpath};
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(POST => $path => form => $params);
        $tx = $ua->start($tx);
        my $res = decode_json($tx->res->body);
        return $res->{sessionid};
    } catch {
        my $e = $_;
        return $e;
    }
}

sub api_auth {
    my ($self, $local, $method) = @_;
    
    # TODO ADD THIS TO INTERFACES
    if ($local eq "local") {
        my $date = Mojo::Date->new;
        my $message = join(' ', uc($method), $self->config->{apiuserid}, $date->to_string);
        my $digest = Digest::SHA::hmac_sha256_hex($message, $self->config->{apikey});
        my $signature = "Koha ".$self->config->{apiuserid}.":".$digest;
        return {"Authorization" => $signature, "X-Koha-Date" => $date->to_string};
    } else {
        return;
    }
}

1;