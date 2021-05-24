package KohaSuomiServices::Model::Biblio::Exporter;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use KohaSuomiServices::Model::Packages::Biblio;

has packages => sub {KohaSuomiServices::Model::Packages::Biblio->new};


sub find {
    my ($self, $client, $params, $conditions) = @_;
    return $client->resultset('Exporter')->search($params, $conditions);
}

sub count {
    my ($self, $client, $params) = @_;
    return $client->resultset('Exporter')->search($params)->count;
}

sub insert {
    my ($self, $client, $params) = @_;
    return $client->resultset('Exporter')->new($params)->insert();
}

sub update {
    my ($self, $id, $params) = @_;
    my $client = $self->packages->schema->client($self->packages->config);
    return $client->resultset('Exporter')->find($id)->update($params);
}

sub getExports {
    my ($self, $type, $components) = @_;

    my $params = {type => $type, status => "pending", parent_id => undef};
    $params = {type => $type, status => "pending", parent_id => {'!=', undef}} if defined $components && $components;
    my $order = defined $components && $components ? {order_by => { -asc => [qw/parent_id source_id/] }} : undef;
    my $schema = $self->packages->schema->client($self->packages->config);
    my @data = $self->find($schema, $params, $order);
    return $self->schema->packages->get_columns(@data);

}

sub setExporterParams {
    my ($self, $interface, $type, $status, $source_id, $target_id, $authuser, $parent_id, $force, $componentparts, $fetch_interface, $activerecord_id, $errorstatus, $componentparts_count) = @_;

    my $exporter->{status} = $status;
    $exporter->{type} = $type;
    $exporter->{source_id} = $source_id;
    $exporter->{target_id} = $target_id if (defined $target_id);
    $exporter->{interface_id} = $interface->{id};
    $exporter->{authuser_id} = $authuser;
    $exporter->{parent_id} = $parent_id;
    $force = 0 unless (defined $force && $force);
    $exporter->{force_tag} = $force;
    $exporter->{componentparts} = defined $componentparts && $componentparts ? $componentparts : 0;
    $exporter->{fetch_interface} = $fetch_interface;
    $exporter->{activerecord_id} = $activerecord_id;
    $exporter->{errorstatus} = $errorstatus;
    $exporter->{componentparts_count} = $componentparts_count;

    return $exporter;
}

sub abortOldExports {
    my ($self, $type, $interface_id, $source_id) = @_;
    my $client = $self->packages->schema->client($self->packages->config);
    my @export = $self->find($client, {type => $type, interface_id => $interface_id, source_id => $source_id, -or => [status => 'waiting', status => 'pending']}, undef);
    return unless @export;
    foreach my $export (@{$self->packages->schema->get_columns(@export)}) {
        $self->packages->log->info("Aborting ".$export->{id}.", newer export record added");
        $self->update($export->{id}, {status => 'failed', errorstatus => 'Aborting! Newer export added'});
    }
}

1;