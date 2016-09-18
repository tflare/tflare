# $Id: search.rb 162 2005-12-17 06:21:28Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

module SleWiki
# class Search
#  definition a Search
#
class Search
  class FilereadError < StandardError; end

  def Search.search(search_word)
    return Msg["no_serch_word"] if search_word == ""

    result = Msg["serch_result"]
    match_flag = false
    separator = "<br>"

    Page.index do |filename|
      cgi = CGI.new

      content = PageStore.new(cgi, Format::page_title(filename)).read

      begin
        null   = %r!^.*#{search_word}.*$!
      rescue RegexpError
        search_word = Regexp.escape(search_word)
      end

      serach_regexp = /^.*#{search_word}.*/i
      if serach_regexp =~ content

        result << "<p>"
        result << Format::make_link(filename)
        result << "<br>"

        content_array = content.split(separator)
        content_array.delete_if do |line|
          !(serach_regexp =~ line)
        end

        result  <<  content_array.join(separator)

        result << "</p>"
        match_flag = true

      end
    end

    unless match_flag
      result << Msg["no_match"]
    end

    return result
  end
end
end