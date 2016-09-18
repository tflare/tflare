# $Id: utils.rb 162 2005-12-17 06:21:28Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

#
# class CGI
#  enhanced CGI class.
#

class CGI
  def valid?(name)
    self.params[name] and self.params[name][0]
  end

  def escape_param(param)
    if param = self.params["#{param}"][0]
      CGI::escapeHTML(param)
    else
      nil
    end
  end
end

def erb(path)

  ERB::new(File::open("#{SleWiki::Config[:templatepath]}/" + path).read.untaint, nil , 2).result(binding)
end

def end_line(file)

  end_line = open(file.untaint, "r").read.scan(/^/).size
end

class Time

  def format_date
    youbi = %w(日 月 火 水 木 金 土)
    strftime("%Y/%m/%d(#{youbi[self.wday]}) %H:%M:%S JST")
  end
end


unless [].respond_to?(:sort_by) 
  class Array
    def sort_by
      self.collect {|i| [yield(i), i] }.
         sort {|a,b| a[0] <=> b[0] }.
         collect! {|i| i[1]}
    end
  end
end


module Auth
  class AuthError < StandardError; end;
  class UnauthorizedError < AuthError; end;
  class RegistError < AuthError; end;

  module_function

  def simple_auth(cgi)
    return true if SleWiki::Config[:auth] == "public"

    user, pass = user_pass(cgi)

    if user != nil and pass != nil

      if user == SleWiki::Config[:auth_user] and Digest::SHA256.hexdigest(pass) == SleWiki::Config[:auth_pass]
        user_regist(cgi, user, pass)
        return true
      end
    end

    user_regist_delete(cgi)
    raise UnauthorizedError

  end

  def user_pass(cgi)
    user = pass = ''

    begin
      session = CGI::Session.new(cgi, "new_session" => false)
    rescue ArgumentError
      user = cgi.escape_param('user')
      pass = cgi.escape_param('pass')
    else
      if session['user'] == "" or session['pass'] == ""

        user = cgi.escape_param('user')
        pass = cgi.escape_param('pass')
      else

        user = session['user']
        pass = session['pass']
      end
      session.close
    end

    return user, pass
  end

  def user_regist(cgi, user, pass)
    raise RegistError if user == '' or pass == ''

    File.umask(0066)

    session = CGI::Session.new(cgi, "new_session" => true,
                   "session_expires" => Time.now + 60 * 60 * 24 * 8) # 8 days

    session['user'] = user
    session['pass'] = pass

    session.close
  end

  def user_regist_delete(cgi)

    begin
      session = CGI::Session.new(cgi, "session_key" => "SleWiki",
                                   "new_session" => false
                                  )
    rescue ArgumentError
    else
      session['user'] = ""
      session['pass'] = ""

      session.close
    end
  end

end


def redirect(cgi, url)

  print cgi.header({
                    'type' => 'text/html',
                    'Cache-Control' => 'no-cache',
                    'Pragma'    => 'no-cache',
                  })
  print %Q[
           <html>
           <head><meta http-equiv=refresh content="0;url=#{url}"></head>
           <body></body>
           </html>]
end

module SleWiki
module ConfigWrite
  def ConfigWrite.init
    File.open(Config[:config_path], 'r+') do |file|
      @text = file.read

      yield

      file.rewind
      file.print @text
      file.flush
      file.truncate(file.pos)
    end
  end

  def ConfigWrite.write(key, value)
    Config["#{key}".intern] = value
    if value == true or value == false
      @text.sub!(/^.*:#{key} .*$/, "    :#{key} => #{value},")
    else
      @text.sub!(/^.*:#{key} .*$/, %Q|    :#{key} => "#{value}",|)
    end
  end
end
end