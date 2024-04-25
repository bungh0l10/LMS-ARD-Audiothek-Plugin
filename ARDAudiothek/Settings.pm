package Plugins::ARDAudiothek::Settings;

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Strings qw (string);
use Slim::Utils::Misc;
use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $prefs = preferences('plugin.ardaudiothek');
my $log = logger('plugin.ardaudiothek');

sub name { Slim::Web::HTTP::CSRF->protectName('PLUGIN_ARDAUDIOTHEK_NAME') }

sub page { Slim::Web::HTTP::CSRF->protectURI('plugins/ARDAudiothek/settings/basic.html') }

1;
