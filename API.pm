package Plugins::ARDAudiothek::API;

use strict;

use JSON::XS::VersionOneAndTwo;

use Slim::Utils::Log;

use constant API_URL => 'https://api.ardaudiothek.de/';
use constant TIMEOUT_S => 20;

my $log = logger('plugin.ardaudiothek');

sub search {
    my ($class, $callback, $args) = @_;

    my $url = API_URL . "search/items?query=$args->{search}&offset=$args->{offset}&limit=$args->{limit}";

    $log->info("$url");

    _call($url, $callback);
}

sub _call {
    my ($url, $callback) = @_;
    
    Slim::Networking::SimpleAsyncHTTP->new(
        sub {
            my $response = shift;

            my $content = eval { from_json($response->content) };

            $callback->($content);
        },
        sub {
            $log->error("An error occured.");
        },
        { timeout => TIMEOUT_S }
    )->get($url);
}

1;
