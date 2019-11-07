package KohaSuomiServices::Model::Packages::Biblio;
use Mojo::Base -base;

use Modern::Perl;
use utf8;

use Try::Tiny;
use POSIX 'strftime';
use Mojo::UserAgent;
use Mojo::Log;
use Mojo::URL;
use KohaSuomiServices::Model::Convert;
use Mojo::JSON qw(decode_json encode_json from_json to_json);
use KohaSuomiServices::Model::Exception::NotFound;
use KohaSuomiServices::Model::Exception::BadParameter;
use KohaSuomiServices::Model::Biblio::Interface;
use KohaSuomiServices::Model::Biblio::Fields;
use KohaSuomiServices::Model::Biblio::Matcher;
use KohaSuomiServices::Model::Biblio::ActiveRecords;
use KohaSuomiServices::Model::Config;
use KohaSuomiServices::Model::Biblio::Exporter;
use KohaSuomiServices::Model::Biblio::ExportAuth;
use KohaSuomiServices::Model::Biblio::Response;
use KohaSuomiServices::Model::Biblio::Search;
use KohaSuomiServices::Model::Biblio;

has biblio => sub {KohaSuomiServices::Model::Biblio->new};
has schema => sub {KohaSuomiServices::Database::Client->new};
has search => sub {KohaSuomiServices::Model::Biblio::Search->new};
has sru => sub {KohaSuomiServices::Model::SRU->new};
has interface => sub {KohaSuomiServices::Model::Biblio::Interface->new};
has fields => sub {KohaSuomiServices::Model::Biblio::Fields->new};
has matchers => sub {KohaSuomiServices::Model::Biblio::Matcher->new};
has active => sub {KohaSuomiServices::Model::Biblio::ActiveRecords->new};
has exporter => sub {KohaSuomiServices::Model::Biblio::Exporter->new};
has exportauth => sub {KohaSuomiServices::Model::Biblio::ExportAuth->new};
has response => sub {KohaSuomiServices::Model::Biblio::Response->new};
has convert => sub {KohaSuomiServices::Model::Convert->new};
has compare => sub {KohaSuomiServices::Model::Compare->new};
has config => sub {KohaSuomiServices::Model::Config->new->service("biblio")->load};
has log => sub {Mojo::Log->new(path => KohaSuomiServices::Model::Config->new->load->{"logs"}, level => KohaSuomiServices::Model::Config->new->load->{"log_level"})};

1;