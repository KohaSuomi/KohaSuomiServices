package KohaSuomiServices::Model::Biblio;
use Mojo::Base -base;

use Modern::Perl;

use Try::Tiny;
use Mojo::UserAgent;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json);

has "schema";

sub export {
    my ($self, $schema, $params) = @_;

    try {
        my $interface_id = $self->get_inteface($schema, $params->{interface}, $params->{type});
        delete $params->{interface};
        $params->{interface_id} = $interface_id;
        $params->{status} = "pending";
        my $data = $schema->resultset('Exporter')->new($params);
        $data->insert();
        return "Success";
    } catch {
        my $e = $_;
        return $e;
    }
    
}

sub get_inteface {
    my ($self, $schema, $name, $type) = @_;
    my $params = {name => $name, type => $type};
    my $data = $schema->resultset("Interface")->search($params)->next;
    return $data->id;
    
}

sub find {
    my ($self, $auth, $interface, $params) = @_;
    
    try {
        my $path = $self->create_path($interface, $params);
        $auth = $auth->api_auth("local", "GET");
        my $ua = Mojo::UserAgent->new;
        my $tx = $ua->build_tx(GET => $path => $auth);
        $tx = $ua->start($tx);
        return decode_json($tx->res->body);
    } catch {
        my $e = $_;
        return $e;
    }
    
}

sub create_path {
    my ($self, $interface, $params) = @_;
    my @matches = $interface->{endpoint_url} =~ /{(.*?)}/g;

    foreach my $match (@matches) {
        my $m = $params->{$match};
        $interface->{endpoint_url} =~ s/{$match}/$m/g;
    }
    return $interface->{endpoint_url};
}

sub load_interface {
    my ($self, $schema, $local, $type) = @_;

    try {
        $local = $local eq "local" ? 1 : 0;
        my $localInterface = $schema->resultset("Interface")->search({local => $local, type => $type})->next;
        my @p = $schema->resultset("Parameter")->search({interface_id => $localInterface->id});
        my $interfaceParams = $self->schema->get_columns(@p);
        my $interface->{endpoint_url} = $localInterface->endpoint_url;
        $interface->{params} = $interfaceParams;
        return $interface;
    } catch {
        my $e = $_;
        warn Data::Dumper::Dumper $e;
        return $e;
    }
}


sub update {
    my ($self, $res) = @_;

}

sub add {
    my ($self, $res) = @_;

}

1;