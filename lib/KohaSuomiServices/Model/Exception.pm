package KohaSuomiServices::Model::Exception;

use Modern::Perl;
use Scalar::Util qw( blessed );

use Exception::Class (
    'KohaSuomiServices::Model::Exception' => {
        description => 'KohaSuomiServices exceptions base class',
        fields => ['httpStatus'],
    },
);

sub generateNew {
  return 'sub new {
    my $class = shift;
    push(@_, httpStatus => $httpStatus) unless (List::Util::first {$_ eq "httpStatus"} @_);
    my $self = $class->SUPER::new(@_);
  }';
}

sub newFromDie {
    my ($class, $die) = @_;
    return KohaSuomiServices::Model::Exception->new(error => "$die");
}

sub handleDefaults {
  my ($e) = @_;

  return (status => 500, openapi => $e) unless blessed($e);
  return (status => 500, openapi => { message => toTextMojo($e)}) if $e->isa('Mojo::Exception');
  return (status => 500, openapi => { message => "Something went wrong!"}) if ref($e) eq 'KohaSuomiServices::Model::Exception'; #If this is THE 'Hetula::Exception', then handle it here
  return (status => $e->{httpStatus} || 500, openapi => { message => $e->{message}} || { message => "Something went wrong!"}) if $e->isa('KohaSuomiServices::Model::Exception'); #If this is a subclass of 'Hetula::Exception', then handle it here, the status|text can be later overridden
}

sub toTextMojo {
    my ($e) = @_;
    return $e->verbose(1)->to_string;
}

return 1;