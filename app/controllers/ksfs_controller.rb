class KsfsController < ApplicationController
  def index
  end

  def upload
    uploaded_io = params[:ucs_file]
    File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
      file.write(uploaded_io.read)
    end
  end
end
