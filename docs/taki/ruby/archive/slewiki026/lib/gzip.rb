# $Id: gzip.rb 162 2005-12-17 06:21:28Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

module SleWiki

module Gzip

  def Gzip::exec?(cgi)
    if /gzip/ =~ cgi.accept_encoding and
      Config[:gzip_transfer] and
        true
    else
        false
    end
  end

  def Gzip::write(cgi, page)

    begin
      require 'zlib'

      gz = Zlib::GzipWriter.new(STDOUT, Zlib::BEST_SPEED)
      gz.write page
      gz.close

    rescue
      print page
    end
  end
end
end