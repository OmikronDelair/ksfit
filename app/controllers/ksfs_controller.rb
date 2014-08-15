class KsfsController < ApplicationController
  before_action :get_songs

  def index
  end

  def upload
    uploaded_io = params[:ucs_file]
    numberized_filename = numberize(uploaded_io.original_filename)
    file_location = Rails.root.join('public', 'uploads', numberized_filename)

    File.open(file_location, 'wb') do |file|
      file.write(uploaded_io.read)
    end

    respond_to do |format|
      format.html {redirect_to action: :index}
      format.json {render json: json_response(numberized_filename), content_type: request.format}
    end
  end

  private

  def find_file filename
    result = nil

    @current_songs.each do |song|
      result = [song['ucs_id'],song['title'],song['artist']] if (filename[song['ucs_id']] != nil)
    end

    if result == nil
      ["Song was not found! Select the song that corresponds to your stepchart.", nil]
    else
      ["Song found! " + result[1] + " by " + result[2], result[0]]
    end
  end

  def get_songs
    songs_json = Rails.root.join('app','assets','javascripts','current_songs.json')
    @current_songs = ActiveSupport::JSON.decode(File.open(songs_json))
  end

  def numberize slug
    slug + '-' + Time.now.seconds_since_midnight.round.to_s
  end

  def json_response filename
    {
          files: [
            {
              name: filename,
              url: 'uploads/' + filename,
              message: find_file(filename)
            }
          ]
        }
  end
end
