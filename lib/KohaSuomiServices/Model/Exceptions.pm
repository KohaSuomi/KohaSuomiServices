package KohaSuomiServices::Model::Exceptions;
use Mojo::Base -base;

use Modern::Perl;
use Mojo::Exception;

sub NotFound {
    my ($self, $message) = @_;
    return $message ? Mojo::Exception->throw($message) : Mojo::Exception->throw('Not Found');
}

sub BadParameter {
    my ($self, $message) = @_;
    return $message ? Mojo::Exception->throw($message) : Mojo::Exception->throw('Bad Parameter');
}

sub InternalError {
    my ($self, $message) = @_;
    return $message ? Mojo::Exception->throw($message) : Mojo::Exception->throw('Something went wrong!');
}

1;