#!/usr/bin/perl

use strict;
use warnings;
use autodie;

# ADD SUPPORT FOR ARCHLINUX
# london@archlinux:~
# $ pacman -Ss ncmpcpp
# community/ncmpcpp 0.9.2-3 [installed]
#     Almost exact clone of ncmpc with some new features
# london@archlinux:~
# $ pacman -Ss mpd
# extra/libmpd 11.8.17-5
#     Signal based wrapper around libmpdclient
# extra/libmpdclient 2.19-3 [installed]
#     C library to implement a MPD client
# extra/mpc 0.33-3 [installed]
#     Minimalist command line interface to MPD
# extra/mpd 0.22.9-1 [installed]
#     Flexible, powerful, server-side application for playing music
# extra/mpdecimal 2.5.1-1
#     Package for correctly-rounded arbitrary precision decimal floating
#     point arithmetic
# extra/ncmpc 0.45-1
#     Fully featured MPD client which runs in a terminal
# extra/rtmpdump 1:2.4.r96.fa8646d-6
#     Tool to download rtmp streams
# community/ario 1.6-2
#     A GTK client for MPD inspired by Rhythmbox but much lighter and faster
# community/cantata 2.4.2-1
#     Qt5 client for the music player daemon (MPD)
# community/haskell-libmpd 0.10.0.0-33
#     Client library for MPD, the Music Player Daemon
# community/python-mpd2 3.0.4-1
#     Python library which provides a client interface for the Music Player
#     Daemon
# community/spampd 2.53-3
#     Spamassassin Proxy Daemon
# community/xfmpc 0.3.0-4
#     A graphical GTK+ MPD client focusing on low footprint
# london@archlinux:~





# TO DO
# install with argument --systemd or --x
# --systemd --> current script
# --x       --> :
#
# touch ~/.xinitrc and put into it
# ". /home/london/.xprofile >> ~/.xinitrc"
#
# touch ~/.xprofile and put into it
# #!/bin/sh
# mpd &

#perl -le 'print "true" if grep m|^#!/|, <ARGV>' .xprofile

# $ENV{HOME}/.ncmpcpp/config
my $ncmpcpp_config_heredoc = <<"END"
% egrep -v '^#' .ncmpcpp/config
mpd_music_dir = "$ENV{HOME}/Music/"
visualizer_in_stereo = "yes"
visualizer_fifo_path = "/tmp/mpd.fifo"
visualizer_output_name = "my_fifo"
visualizer_sync_interval = "30"
visualizer_type = "spectrum"
visualizer_look = "◆▋"
#visualizer_look = "+|"
message_delay_time = "3"
playlist_shorten_total_times = "yes"
playlist_display_mode = "columns"
browser_display_mode = "columns"
search_engine_display_mode = "columns"
#search_engine_display_mode = "classic"
playlist_editor_display_mode = "columns"
autocenter_mode = "yes"
centered_cursor = "yes"
user_interface = "alternative"
follow_now_playing_lyrics = "yes"
locked_screen_width_part = "60"
display_bitrate = "yes"
external_editor = "nano"
use_console_editor = "yes"
header_window_color = "cyan"
volume_color = "red"
state_line_color = "yellow"
state_flags_color = "red"
progressbar_color = "yellow"
statusbar_color = "cyan"
visualizer_color = "red"
mpd_host = "$ENV{HOME}/.config/mpd/socket"
#mpd_host = "127.0.0.1"
mpd_port = "6600"
#mpd_port = "6601"
#mouse_list_scroll_whole_page = "yes"
mouse_list_scroll_whole_page = "no"
mouse_support = "no"
lines_scrolled = "1"
#ask_before_clearing_main_playlist = "yes" # make ncmpcpp crash
enable_window_title = "yes"
song_columns_list_format = "(25)[cyan]{a} (40)[]{f} (30)[red]{b} (7f)[green]{l}"
END
;

# $ENV{HOME}/.mpd/mpd.conf
my $mpd_conf_heredoc = <<"END"
music_directory "$ENV{HOME}/Music/"
playlist_directory "$ENV{HOME}/Music/"
db_file "$ENV{HOME}/.mpd/mpd.db"
log_file "$ENV{HOME}/.mpd/mpd.log"
pid_file "$ENV{HOME}/.mpd/mpd.pid"
state_file "$ENV{HOME}/.mpd/mpdstate"
	
audio_output {
	type "pulse"
	name "pulse audio"
}

audio_output {
    type                 "fifo"
    name                 "my_fifo"
    path                 "/tmp/mpd.fifo"
    format               "44100:16:2"
}

bind_to_address          "$ENV{HOME}/.config/mpd/socket"
#bind_to_address          "127.0.0.1"
port                     "6600"
#port                     "6601"
END
;

my $FH;

system qw(sudo apt install mpd mpc ncmpcpp);	# doesn't work for ArchLinux

mkdir "$ENV{HOME}/.mpd";
mkdir "$ENV{HOME}/.ncmpcpp";


my $ncmpcpp_config_path  = "$ENV{HOME}/.ncmpcpp/config";
my $mpd_conf_path        = "$ENV{HOME}/.mpd/mpd.conf";

unless ( -e "$ncmpcpp_config_path" and not -z "$ncmpcpp_config_path" ) {
	open  $FH, ">>", "$ncmpcpp_config_path"; 
	print $FH $ncmpcpp_config_heredoc;
	close $FH;
}

unless ( -e "$mpd_conf_path" and not -z "$mpd_conf_path" ) {
	open  $FH, ">>", "$mpd_conf_path";
	print $FH $mpd_conf_heredoc;
	close $FH;
}

# create 3 files
open $FH, ">>", "$ENV{HOME}/.mpd/mpd.db" ; close $FH;
open $FH, ">>", "$ENV{HOME}/.mpd/mpd.log"; close $FH;
open $FH, ">>", "$ENV{HOME}/.mpd/mpd.pid"; close $FH;

mkdir "$ENV{HOME}/.config/mpd";

open $FH, ">>", "$ENV{HOME}/.config/mpd/socket"; close $FH;

#########################
# for mpc
open  $FH, "+<", "$ENV{HOME}/.bashrc";
my @bashrc = <$FH>;
my $mpd_host = grep {/export \s+ MPD_HOST/x} @bashrc;
my $mpd_port = grep {/export \s+ MPD_PORT/x} @bashrc;

if ( ! $mpd_host ) {	# if bashrc do not already have export MPD_HOST="..."
	print $FH "export MPD_HOST=\"$ENV{HOME}/.config/mpd/socket\"","\n";
	print "export MPD_HOST=\"$ENV{HOME}/.config/mpd/socket\"","\n";
}

if ( ! $mpd_port ) {	# if bashrc do not already have export MPD_PORT="..."
	print $FH "export MPD_PORT=6600","\n";
	print "export MPD_PORT=6600","\n";
}
close $FH;
##########################
# launch mpd
system qw(systemctl --user enable mpd.service)
	or warn "systemctl --user enable mpd.service: $!";
system qw(systemctl --user start mpd.service)
	or warn "systemctl --user start mpd.service: $!";

# not strictly necessary
system qw(xfce4-terminal -e ncmpcpp); # on xfce4 desktop
#system qw(x-terminal-emulator -e ncmpcpp); # other terminal emulator



__END__


OPTIONAL PARAMETERS
       db_file <file>
              This specifies where the db file will be stored.

       log_file <file>
              This  specifies  where the log file should be located. The special value "syslog" makes MPD use the local syslog dae‐
              mon.

       sticker_file <file>
              The location of the sticker database. This is a database which manages dynamic information attached to songs.

       pid_file <file>
              This specifies the file to save mpd's process ID in.

       music_directory <directory>
              This specifies the directory where music is located. If you do not configure this, you can only play streams.

       playlist_directory <directory>
              This specifies the directory where saved playlists are stored.  If  you  do  not  configure  this,  you  cannot  save
              playlists.

       state_file <file>
              This  specifies if a state file is used and where it is located. The state of mpd will be saved to this file when mpd
              is terminated by a TERM signal or by the kill command. When mpd is restarted, it will read the state file and restore
              the state of mpd (including the playlist).

       restore_paused <yes or no>
              Put MPD into pause mode instead of starting playback after startup.

       user <username>
              This  specifies  the  user that MPD will run as, if set. MPD should never run as root, and you may use this option to
              make MPD change its user id after initialization. Do not use this option if you start MPD as an unprivileged user.

       port <port>
              This specifies the port that mpd listens on. The default is 6600.

       log_level <level>
              Suppress all messages below the given threshold.  The following log levels are available:

              • error: errors

              • warning: warnings

              • notice: interesting informational messages

              • info: unimportant informational messages

              • verbose: debug messages (for developers and for troubleshooting)

              The default is notice.

       follow_outside_symlinks <yes or no>
              Control if MPD will follow symbolic links pointing outside the music dir. You must recreate the database after chang‐
              ing this option. The default is "yes".

       follow_inside_symlinks <yes or no>
              Control  if  MPD will follow symbolic links pointing inside the music dir, potentially adding duplicates to the data‐
              base. You must recreate the database after changing this option. The default is "yes".

       zeroconf_enabled <yes or no>
              If yes, and MPD has been compiled with support for Avahi or Bonjour, service information will be published with Zero‐
              conf. The default is yes.

       zeroconf_name <name>
              If  Zeroconf  is  enabled, this is the service name to publish. This name should be unique to your local network, but
              name collisions will be properly dealt with. The default is "Music Player @ %h", where %h will be replaced  with  the
              hostname of the machine running MPD.

       audio_output
              See  DESCRIPTION  and  the  various  AUDIO  OUTPUT PARAMETERS sections for the format of this parameter. Multiple au‐
              dio_output sections may be specified. If no audio_output section is specified, then MPD will scan for a usable  audio
              output.

       replaygain <off or album or track or auto>
              If    specified,    mpd    will    adjust    the    volume    of    songs   played   using   ReplayGain   tags   (see
              https://wiki.hydrogenaud.io/index.php?title=Replaygain).  Setting this to "album" will adjust volume  using  the  al‐
              bum's  ReplayGain  tags,  while setting it to "track" will adjust it using the track ReplayGain tags. "auto" uses the
              track ReplayGain tags if random play is activated otherwise the album ReplayGain tags. Currently only FLAC, Ogg  Vor‐
              bis, Musepack, and MP3 (through ID3v2 ReplayGain tags, not APEv2) are supported.

       replaygain_preamp <-15 to 15>
              This is the gain (in dB) applied to songs with ReplayGain tags.

       volume_normalization <yes or no>
              If yes, mpd will normalize the volume of songs as they play. The default is no.

       filesystem_charset <charset>
              This  specifies the character set used for the filesystem. A list of supported character sets can be obtained by run‐
              ning "iconv -l". The default is determined from the locale when the db was originally created.

       save_absolute_paths_in_playlists <yes or no>
              This specifies whether relative or absolute paths for song filenames are used when saving playlists. The  default  is
              "no".

       auto_update <yes or no>
              This  specifies  the whether to support automatic update of music database when files are changed in music_directory.
              The default is to disable autoupdate of database.

       auto_update_depth <N>
              Limit the depth of the directories being watched, 0 means only watch the music directory itself. There is no limit by
              default.

REQUIRED AUDIO OUTPUT PARAMETERS
       type <type>
              This specifies the audio output type. See the list of supported outputs in mpd --version for possible values.

       name <name>
              This specifies a unique name for the audio output.

OPTIONAL AUDIO OUTPUT PARAMETERS
       format <sample_rate:bits:channels>
              This specifies the sample rate, bits per sample, and number of channels of audio that is sent to the audio output de‐
              vice. See documentation for the audio_output_format parameter for more details. The default is to use whatever  audio
              format  is  passed to the audio output. Any of the three attributes may be an asterisk to specify that this attribute
              should not be enforced

       replay_gain_handler <software, mixer or none>
              Specifies how replay gain is applied. The default is "software", which uses  an  internal  software  volume  control.
              "mixer" uses the configured (hardware) mixer control. "none" disables replay gain on this audio output.

       mixer_type <hardware, software or none>
              Specifies  which mixer should be used for this audio output: the hardware mixer (available for ALSA, OSS and PulseAu‐
              dio), the software mixer or no mixer ("none"). By default, the hardware mixer is used for devices which  support  it,
              and none for the others.


##############################################################################
OPTIONAL PARAMETERS
       db_file <file>
       log_file <file>
       sticker_file <file>
       pid_file <file>
       music_directory <directory>
       playlist_directory <directory>
       state_file <file>
       restore_paused <yes or no>
       user <username>
       port <port>
       log_level <level> (error, warning, notice (default), info, verbose)
       follow_outside_symlinks <yes or no>
       follow_inside_symlinks <yes or no>
       zeroconf_enabled <yes or no>
       zeroconf_name <name>
       audio_output
       replaygain <off or album or track or auto>
       replaygain_preamp <-15 to 15> This is the gain (in dB) applied to songs with ReplayGain tags.
       volume_normalization <yes or no>
       filesystem_charset <charset>
       save_absolute_paths_in_playlists <yes or no>
       auto_update <yes or no>
       auto_update_depth <N>
REQUIRED AUDIO OUTPUT PARAMETERS
       type <type>
       name <name>
OPTIONAL AUDIO OUTPUT PARAMETERS
       format <sample_rate:bits:channels>
       replay_gain_handler <software, mixer or none>
       mixer_type <hardware, software or none>
################################################################################################################

CONFIGURATION
       When  ncmpcpp  starts, it tries to read settings from $XDG_CONFIG_HOME/ncmpcpp/config and $HOME/.ncmpcpp/config files. If no
       configuration is found, ncmpcpp uses its default configuration. An example configuration file containing all default  values
       is provided with ncmpcpp and can be usually found in /usr/share/doc/ncmpcpp (the exact location may depend on your operating
       system or configure prefix).

       Note: Configuration option values can either be enclosed in quotation marks or not.
        - If they are enclosed, the leftmost and the rightmost quotation marks are treated as delimiters, therefore it is not  nec‐
       essary to escape quotation marks you use within the value itself.
        -  If  they  are not, any whitespace characters between = and the first printable character of the value, as well as white‐
       space characters after the last printable character of the value are trimmed.

       Therefore the rule of thumb is: if you need whitespaces at the beginning or at the end of the value, enclose it in quotation
       marks. Otherwise, don't.

       Note: COLOR has to be the name (not a number) of one of colors 1-8 from SONG FORMAT section.

       Supported configuration options:

       ncmpcpp_directory = PATH
       lyrics_directory = PATH
       mpd_host = HOST
       mpd_port = PORT
       mpd_music_dir = PATH
       mpd_connection_timeout = SECONDS
       mpd_crossfade_time = SECONDS
       visualizer_data_source = LOCATION
       visualizer_output_name = NAME
       visualizer_in_stereo = yes/no
       visualizer_type = spectrum/wave/wave_filled/ellipse
       visualizer_look = STRING
       visualizer_color = COLORS
       visualizer_fps = FPS
       visualizer_autoscale = yes/no
       visualizer_spectrum_smooth_look = yes/no
       visualizer_spectrum_dft_size = NUMBER
       visualizer_spectrum_gain = dB
       visualizer_spectrum_hz_min = Hz
       visualizer_spectrum_hz_max = Hz
       system_encoding = ENCODING
       playlist_disable_highlight_delay = SECONDS
       message_delay_time = SECONDS
       song_list_format
       song_status_format
       song_library_format
       alternative_header_first_line_format = TEXT
       alternative_header_second_line_format = TEXT
       current_item_prefix = TEXT
       current_item_suffix = TEXT
       current_item_inactive_column_prefix = TEXT
       current_item_inactive_column_suffix = TEXT
       now_playing_prefix = TEXT
       now_playing_suffix = TEXT
       browser_playlist_prefix = TEXT
       selected_item_prefix = TEXT
       selected_item_suffix = TEXT
       modified_item_prefix = TEXT
       browser_sort_mode
       browser_sort_format
       song_window_title_format
       song_columns_list_format
       execute_on_song_change = COMMAND
       execute_on_player_state_change = COMMAND
       playlist_show_mpd_host = yes/no
       playlist_show_remaining_time = yes/no
       playlist_shorten_total_times = yes/no
       playlist_separate_albums = yes/no
       playlist_display_mode = classic/columns
       browser_display_mode = classic/columns
       search_engine_display_mode = classic/columns
       playlist_editor_display_mode = classic/columns
       discard_colors_if_item_is_selected = yes/no
       show_duplicate_tags = yes/no
       incremental_seeking = yes/no
       seek_time = SECONDS
       volume_change_step = NUMBER
       autocenter_mode = yes/no
       centered_cursor = yes/no
       progressbar_look = TEXT
       default_place_to_search_in = database/playlist
       user_interface = classic/alternative
       data_fetching_delay = yes/no
       media_library_primary_tag = artist/album_artist/date/genre/composer/performer
       media_library_albums_split_by_date = yes/no
       media_library_hide_album_dates = yes/no
       default_find_mode = wrapped/normal
       default_tag_editor_pattern = TEXT
       header_visibility = yes/no
       statusbar_visibility = yes/no
       connected_message_on_startup = yes/no
       titles_visibility = yes/no
       header_text_scrolling = yes/no
       cyclic_scrolling = yes/no
       lyrics_fetchers = FETCHERS
       follow_now_playing_lyrics = yes/no
       fetch_lyrics_for_current_song_in_background = yes/no
       store_lyrics_in_song_dir = yes/no
       generate_win32_compatible_filenames = yes/no
       allow_for_physical_item_deletion = yes/no
       lastfm_preferred_language = ISO 639 alpha-2 language code
       space_add_mode = add_remove/always_add
       show_hidden_files_in_local_browser = yes/no
       screen_switcher_mode = SWITCHER_MODE
       startup_screen = SCREEN_NAME
       startup_slave_screen = SCREEN_NAME
       startup_slave_screen_focus = yes/no
       locked_screen_width_part = 20-80
       ask_for_locked_screen_width_part = yes/no
       jump_to_now_playing_song_at_start = yes/no
       ask_before_clearing_playlists = yes/no
       clock_display_seconds = yes/no
       display_volume_level = yes/no
       display_bitrate = yes/no
       display_remaining_time = yes/no
       regular_expressions = none/basic/extended/perl
       ignore_leading_the = yes/no
       ignore_diacritics = yes/no
       block_search_constraints_change_if_items_found = yes/no
       mouse_support = yes/no
       mouse_list_scroll_whole_page = yes/no
       lines_scrolled = NUMBER
       empty_tag_marker = TEXT
       tags_separator = TEXT
       tag_editor_extended_numeration = yes/no
       media_library_sort_by_mtime = yes/no
       enable_window_title = yes/no
       search_engine_default_search_mode = MODE_NUMBER
       external_editor = PATH
       use_console_editor = yes/no
       colors_enabled = yes/no
       empty_tag_color = COLOR
       header_window_color = COLOR
       volume_color = COLOR
       state_line_color = COLOR
       state_flags_color = COLOR
       main_window_color = COLOR
       color1 = COLOR
       color2 = COLOR
       progressbar_color = COLOR
       progressbar_elapsed_color = COLOR
       statusbar_color = COLOR
       statusbar_time_color = COLOR
       player_state_color = COLOR
       alternative_ui_separator_color = COLOR
       window_border_color = BORDER
       active_window_border = COLOR







