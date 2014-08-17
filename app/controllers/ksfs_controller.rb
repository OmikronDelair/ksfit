class KsfsController < ApplicationController
  before_action :get_songs

 require 'rubygems'
 require 'zip'

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

  def ksf_it
    ksf_file = ucs_to_ksf params[:song][:ucs_id], params[:file][:name]
    zip_simfile ksf_file, params[:song][:ucs_id]
  end

  private

  def ucs_to_ksf ucs_id, filename
    ksf = numberize(ucs_id) + ".ksf"
    rq_file = filename
    file_location = Rails.root.join('public', 'uploads', rq_file)
    ksf_file = File.open(Rails.root.join('public', 'uploads', ksf), 'wb')
    ksf_file.write("#TITLE:"+ucs_id+";\r\n")
    line_index = 0

    File.open(file_location).each_line do |line|
      ksf_file.write(parse_line line,line_index)
      line_index += 1
    end

    ksf_file.write("2222222222222")
    ksf_file.close

    return ksf
  end

  def zip_simfile ksf_name, ucs_id
    filename = ksf_name.gsub('.ksf','.zip')
    temp_file = Tempfile.new(filename)

    begin
      Zip::OutputStream.open(temp_file) { |zos| }

      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
        zip.add(ucs_id+".ksf", Rails.root.join('public', 'uploads', ksf_name))
        zip.add("Song.mp3", Rails.root.join('public', 'audios', ucs_id+".mp3"))
      end

      zip_data = File.read(temp_file.path)

      send_data(zip_data, :type => 'application/zip', :filename => filename)
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def parse_line line,line_index
    if line[":Format="] || line[":Mode="] || line[":Beat="]

      line = ""

    elsif line[":BPM="]

      if line_index > 7
        line[":BPM="] = "|B"
        line["\r\n"] = "|\r\n"
      else
        line[":BPM="] = "#BPM:"
        line["\r\n"] = ";\r\n"
      end

    elsif line[":Delay="]

      if line_index > 7
        line = ""
      else
        line[":Delay="] = "#STARTTIME:"
        line["\r\n"] = ";\r\n"
      end

    elsif line[":Split="]

      @split = line.gsub(":Split=","")
      @split["\r\n"] = ""
      @first_block = 0

      if line_index > 7
        line = "|T"+@split+"|\r\n"
      else
        line = "#TICKCOUNT:"+@split+";\r\n#STEP:\r\n"
        @first_block = @split.to_i/2
      end

    elsif ['.','X','M','H','W'].include? line[0]

      if @first_block != 0
        line = ""
        @first_block -= 1
      else
        for i in 1..line.length do
          line['.'] ? line['.'] = "0" : nil
          line['X'] ? line['X'] = "1" : nil
          line['M'] ? line['M'] = "4" : nil
          line['H'] ? line['H'] = "4" : nil
          line['W'] ? line['W'] = "4" : nil
        end
      end

      if line.length < 8 && line != ""
        line["\r\n"] ? line["\r\n"] = '' : nil
        line = line + ("00000000\r\n")
      end

    end

    line
  end

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
              message: find_file(filename)
            }
          ]
        }
  end
end
