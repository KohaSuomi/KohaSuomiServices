package KohaSuomiServices::Model::Biblio::ActiveRecords;
use Mojo::Base -base;

use Modern::Perl;
use utf8;
use Try::Tiny;
use POSIX 'strftime';

use KohaSuomiServices::Model::Packages::Biblio;

has packages => sub {KohaSuomiServices::Model::Packages::Biblio->new};


sub find {
    my ($self, $client, $params) = @_;
    return $self->packages->schema->get_columns($client->resultset('ActiveRecords')->search($params));
}

sub findLast {
    my ($self, $client, $params) = @_;
    return $client->resultset('ActiveRecords')->search($params, {order_by => {-desc => 'created'}, {rows => 1}})->first();
}

sub insert {
    my ($self, $client, $params) = @_;
    return $client->resultset('ActiveRecords')->new($params)->insert();
}

sub update {
    my ($self, $client, $id, $params) = @_;
    return $client->resultset('ActiveRecords')->find($id)->update($params);
}

sub delete {
    my ($self, $client, $id) = @_;
    return $client->resultset('ActiveRecords')->find($id)->delete;
}

sub updateActiveRecords {
    my ($self, $id) = @_;

    my $schema = $self->packages->schema->client($self->packages->config);
    my $now = strftime "%Y-%m-%d %H:%M:%S", ( localtime(time + 5*60) );
    $self->update($schema, $id, {updated => $now});
}

sub checkActiveRecord {
    my ($self, $interface_name, $target_id, $id) = @_;
    my $interface = $self->packages->interface->load({name => $interface_name, type => "get"});
    my $path = $self->packages->biblio->search->create_path($interface, {source_id => $target_id});
    my $authentication = $self->packages->exportauth->authorize($interface);
    my $reqHeaders = $self->packages->biblio->search->create_headers($interface->{params});
    my ($resCode, $resBody, $resHeaders) = $self->packages->biblio->search->callInterface($interface->{method}, $interface->{format}, $path, undef, $authentication, $reqHeaders);
    if ($resCode eq '200') {
        return 1;
    } else {
        $self->packages->log->info("Failed to check active record from ". $interface_name.": ".$resHeaders);
        return 0;
    }
    

}

1;
