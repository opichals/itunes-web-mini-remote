# Gems to install: sinatra, appscript
# Before starting up, make sure that all songs in your whole song
# collection are shown in the main window. Otherwise, when you select
# a song, only that song will be played.

require 'rubygems'
require 'appscript'
require 'sinatra'

# Just make a quick test to see if iTunes is running
itunes = Appscript.app('ITunes')
begin
  itunes.name
rescue
  puts 'You need to start iTunes'
  exit
end

puts "Remember to select 'All genres', 'All artists', 'All albums' in iTunes, or you'll get annoyed sooner or later..."

# Organize and cache the whole music collection.
# (Ugly code...)
album_struct = Hash.new
itunes.sources.get.each do |source|
  puts "Loading source...  " + source.name.get
  source.playlists['Music'].tracks.get.each do |track|
      album = track.album.get
      album_struct[album] ||= []
      album_struct[album] << track
  end
  break
end

album_struct.each_value {|tracks| tracks.sort_by {|track| track.track_number.get }}
album_id = 0
albums = Hash.new
Album = Struct.new(:id, :title, :artist, :tracks)
album_struct.each_key do |title|
  album_id += 1
  albums[album_id] = Album.new(album_id, title, album_struct[title][0].artist.get, album_struct[title])
end
puts "Done loading sources"

# Helper method, to be used later
def get_and_back(url)
  get url do
    yield
    redirect '/'
  end
end

# Main page
get '/' do
  @headline = 'Stopped'
  if (itunes.player_state.get.to_s != 'stopped')
    track = itunes.current_track
    name, artist, album = track.name.get, track.artist.get, track.album.get
    @headline = "#{name} (#{artist}, from #{album}): #{track.time.get}"
  end
  erb <<END
<html>
  <body>
    <h3><%= @headline %></h3>
    <table>
      <tr><td>Track:</td><td><a href="prev">previous</a></td><td><a href="next">next</a></td></tr>
      <tr><td>Volume:</td><td><a href="down">down</a></td><td><a href="up">up</a></td></tr>
      <tr><td>Playback:</td><td><a href="pause">pause</a></td><td><a href="play">play</a></td></tr>
      <tr><td colspan="3"><a href="albums?sort=title">Albums by title</a>
                          <a href="albums?sort=artist">Albums by artist</a></td></tr>
    </table>
  </body>
</html>
END
end

# List of albums, sorted by any given attribute (defaults to 'title')
get '/albums' do
  order_by = params[:sort] || 'title'
  @sorted_albums = albums.values.sort_by {|album| album.send order_by }
  erb <<END
<html>
  <body>
    <p><a href="/">Back</a></p>
    <table>
      <tr><td>Album</td><td>Artist</td></tr>
      <% for album in @sorted_albums do %>
        <tr><td><a href="/albums/<%= album.id %>"><%= album.title %></a></td>
            <td><a href="/albums/<%= album.id %>"><%= album.artist %></a></td></tr>
      <% end %>
    </table>
  </body>
</html>
END
end

# Contents of a single album
get '/albums/:id' do
  @album = albums[params[:id].to_i]
  erb <<END
<html>
  <body>
    <p><a href="/">Back</a></p>
    <table>
      <tr><td>Track</td><td>Length</td></tr>
      <% @album.tracks.each_with_index do |track, number| %>
        <tr><td><a href="/albums/<%= @album.id %>/<%= number %>"><%= track.name.get %></a></td>
            <td><a href="/albums/<%= @album.id %>/<%= number %>"><%= track.time.get %></a></td>
      <% end %>
    </table>
  </body>
</html>
END
end

# Starts playing a specific track
get '/albums/:album_id/:track_number' do
  album_id = params[:album_id].to_i
  track_number = params[:track_number].to_i

  # The following line works in Tiger, but not Leopard (damn Apple!)
  albums[album_id].tracks[track_number].play(:once => false)
  # ...so we'll do this instead:
  #system "osascript -e 'tell application \"iTunes\" to play (tracks of (playlist \"Music\") whose database ID is #{albums[album_id].tracks[track_number].database_id})'"

  redirect '/'
end

# Basic controls from the main page
get_and_back('/next') { itunes.next_track }
get_and_back('/prev') { itunes.previous_track }
get_and_back('/up') { itunes.sound_volume.set(itunes.sound_volume.get + 5) }
get_and_back('/down') { itunes.sound_volume.set(itunes.sound_volume.get - 5) }
get_and_back('/pause') { itunes.pause }
get_and_back('/play') { itunes.play }
