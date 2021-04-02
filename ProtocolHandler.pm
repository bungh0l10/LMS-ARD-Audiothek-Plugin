package Plugins::ARDAudiothek::ProtocolHandler;

# Protocolhandler for ardaudiothek:// URLS

use strict;

use base qw(Slim::Player::Protocols::HTTPS);

use Slim::Utils::Log;
use Plugins::ARDAudiothek::Plugin;
use Plugins::ARDAudiothek::API;

my $log = logger('plugin.ardaudiothek');

use constant PLAYLIST_LIMIT => 1000;

sub scanUrl {
    my ($class, $uri, $args) = @_;

    $log->info($uri);

    my $id = _itemIdFromUri($uri);

    Plugins::ARDAudiothek::API->getItem(sub{
            my $episode = Plugins::ARDAudiothek::Plugin::episodeDetails(shift);
            my $url = $episode->{url};

            Slim::Utils::Scanner::Remote->scanURL($url, $args);

            my $client = $args->{client}->master;
            my $image = Plugins::ARDAudiothek::Plugin::selectImageFormat($episode->{image});

            $client->playingSong->pluginData( wmaMeta => {
                    icon   => $image,
                    cover  => $image,
                    artist => $episode->{show},
                    title  => $episode->{title}
                }
            );

            Slim::Control::Request::notifyFromArray( $client, [ 'newmetadata' ] );
        },{
            id => $id
        }
    );

    return;
}

sub explodePlaylist {
    my ($class, $client, $uri, $callback) = @_;

    if($uri =~ /ardaudiothek:\/\/episode\/[0-9]+/) {
        $callback->([$uri]);
    }
    elsif($uri =~ /ardaudiothek:\/\/programset\/[0-9]+/) {
        my $id = _itemIdFromUri($uri);

        Plugins::ARDAudiothek::API->getProgramSet(
            sub {
                my $content = shift;
                my @episodeUris;

                for my $episode (@{$content->{_embedded}->{"mt:items"}}) {
                    push(@episodeUris, 'ardaudiothek://episode/' . $episode->{id});
                }
                
                $callback->([@episodeUris]);
            },{
                programSetID => $id,
                offset => 0,
                limit => PLAYLIST_LIMIT
            }
        );
    } 
    elsif($uri =~ /ardaudiothek:\/\/collection\/[0-9]+/) {
        my $id = _itemIdFromUri($uri);

        Plugins::ARDAudiothek::API->getCollectionContent(
            sub {
                my $content = shift;
                my @episodeUris;

                for my $episode (@{$content->{_embedded}->{"mt:items"}}) {
                    push(@episodeUris, 'ardaudiothek://episode/' . $episode->{id});
                }
                
                $callback->([@episodeUris]);
            },{
                collectionID => $id,
                offset => 0,
                limit => PLAYLIST_LIMIT
            }
        );
    }
    else {
        $callback->([]);
    }
}

sub getMetadataFor {
    my ($class, $client, $uri) = @_;

    my $content = Plugins::ARDAudiothek::API::getItemFromCache(_itemIdFromUri($uri)); 
    my $episode = Plugins::ARDAudiothek::Plugin::episodeDetails($content);

    my $image = Plugins::ARDAudiothek::Plugin::selectImageFormat($episode->{image});

    return {
        icon => $image,
        cover => $image,
        title => $episode->{title},
        artist => $episode->{show},
        duration => $episode->{duration},
        description => $episode->{description}
    };
}

sub _itemIdFromUri {
    my $uri = shift;
    
    my $id = $uri;
    $id =~ s/\D//g;
    
    return $id;
}

1;
