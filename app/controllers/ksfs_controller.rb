class KsfsController < ApplicationController
  before_action :get_songs

 require 'rubygems'
 require 'zip'

  def index
  end

  def upload
    uploaded_io = params[:ucs_file]
    numberized_filename = numberize(uploaded_io.original_filename)
    file_body = uploaded_io.read

    respond_to do |format|
      format.html {redirect_to action: :index}
      format.json {render json: json_response(numberized_filename, file_body), content_type: request.format}
    end
  end

  def ksf_it
    ksf_file = ucs_to_ksf params[:ucs]
    zip_simfile ksf_file, params[:ucs]
  end

  private

  def ucs_to_ksf ucs_info
    ucs_body, line_index, @ksf_body = ucs_info[:body],
                                      0,
                                      "#TITLE:"+ucs_info[:title]+";\r\n"

    ucs_body.each_line do |line|
      @ksf_body += parse_line line, line_index
      line_index += 1
    end

    @ksf_body += "2222222222222"
  end

  def zip_simfile ksf_name, ucs_info
    filename = ucs_info[:title]+'.zip'
    temp_file = Tempfile.new(filename)

    begin
      Zip::OutputStream.open(temp_file) { |zos| }

      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
        zip.add(ucs_info[:id]+".ksf", Rails.root.join('public', 'uploads', ksf_name))
        zip.add("Song.mp3", Rails.root.join('app/assets', 'audios', ucs_info[:id]+".mp3"))
      end

      zip_data = File.read(temp_file.path)

      send_data(zip_data, :type => 'application/zip', :filename => filename)
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def parse_line line,line_index
    if line[":Format="] || line[":Mode="]

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

    elsif line[":Beat="]

      if line_index < 7
        @beat = line.gsub(":Beat=","")
        @beat["\r\n"] = ""
      end

      line = ""

    elsif line[":Split="]

      @split = line.gsub(":Split=","")
      @split["\r\n"] = ""
      @first_block = 0

      if line_index > 7
        line = "|T"+@split+"|\r\n"
      else
        line = "#TICKCOUNT:"+@split+";\r\n#STEP:\r\n"

        if @beat.to_i >= 8
          @first_block = @split.to_i
        else
          @first_block = @split.to_i/2
        end

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

  def json_response filename, file_body
    {
          files: [
            {
              name: filename,
              message: find_file(filename),
              file_body: file_body
            }
          ]
        }
  end
end
