package KohaSuomiServices::Model::Exception;

use Modern::Perl;
use utf8;
use Scalar::Util qw( blessed );
use KohaSuomiServices::Model::Config;

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
  my $log = Mojo::Log->new(path => KohaSuomiServices::Model::Config->new->load->{"logs"}, level => KohaSuomiServices::Model::Config->new->load->{"log_level"});
  $log->debug($e);
  return (status => 500, openapi => { error => "Something went wrong!"}) unless blessed($e);
  return (status => 500, openapi => { error => "Something went wrong!"}) if $e->isa('Mojo::Exception');
  return (status => 500, openapi => { error => "Something went wrong!"}) if ref($e) eq 'KohaSuomiServices::Model::Exception'; #If this is THE 'Hetula::Exception', then handle it here
  return (status => $e->{httpStatus} || 500, openapi => { error => $e->{message}} || { error => "Something went wrong!"}) if $e->isa('KohaSuomiServices::Model::Exception'); #If this is a subclass of 'KohaSuomiServices::Model::Exception', then handle it here, the status|text can be later overridden
}

sub toTextMojo {
    my ($e) = @_;
    return $e->verbose(1)->to_string;
}

1;
