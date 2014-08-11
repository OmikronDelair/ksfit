class KsfsController < ApplicationController
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
      format.json {render json: '[{"file_location" : "' + numberized_filename + '"}]'}
    end
  end

  private

  def numberize slug
    slug + '-' + Time.now.seconds_since_midnight.round.to_s
  end
end
