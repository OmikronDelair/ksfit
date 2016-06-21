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
    ucs_to_ksf params[:ucs]
    zip_simfile params[:ucs][:id]
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

  def zip_simfile ucs_id
    filename = ucs_id << '.zip'
    temp_file = Tempfile.new(filename)
    ksf_tmp_file = Tempfile.new(ucs_id)
    ksf_new_file = File.open(ksf_tmp_file, 'wb')

    ksf_new_file.write(@ksf_body)

    begin
      Zip::OutputStream.open(temp_file) { |zos| }

      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
        zip.add(ucs_id+".ksf", ksf_new_file)
        zip.add("Song.mp3", Rails.root.join('app/assets', 'audios', ucs_id+".mp3"))
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
      end

    elsif ['.','X','M','H','W'].include? line[0]

      if @first_block != 0
        line = ""
        @first_block -= 1
      else
        line.each do
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
