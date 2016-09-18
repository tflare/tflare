#!/usr/local/bin/ruby -Ke
# $Id: update.cgi 157 2005-10-02 13:01:18Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

begin

  BEGIN { STDOUT.binmode }
  $SAFE = 1

  require 'slebbs'
  require 'sleconfig'
  require 'lib/utility'

  cgi = CGI.new

  begin
    Auth.simple_auth(cgi)
  rescue Auth::UnauthorizedError
    SleBbs::Html.new(cgi, erb("authpage.rhtml"))
    exit
  end

  case  cgi.params['act'][0]
  when  "thread_delete"

    thread_id   = cgi.params['thread_id'][0].untaint
    File.rename(SleBbs::Config[:dbpath] + "/#{thread_id}#{SleBbs::Config[:dbextname]}",
          SleBbs::Config[:dbpath] + "/#{thread_id}" + ".del")

    cgi.params['thread_id'][0] = nil
    SleBbs::Html.new(cgi, "����å�#{thread_id}�κ������λ���ޤ�����")

  when  "res_delete_confirm"

    thread_id = cgi.params['thread_id'][0].untaint
    res_id  = cgi.params['res_id'][0].untaint.to_i

    if res_id == 1
      SleBbs::Html.new(cgi, "�쥹�ֹ�1�Ͼä��ޤ��󡣾ä���祹��åɤ��Ⱦä��Ƥ�������")
    elsif res_id == 0
       SleBbs::Html.new(cgi, "�쥹�ֹ�#{cgi.params['res_id'][0].untaint}�������Ǥ���")
    end

    dbpath = SleBbs::Config[:dbpath] + "/#{thread_id}#{SleBbs::Config[:dbextname]}"
    if end_line(dbpath) < res_id
      SleBbs::Html.new(cgi, "���顼��ȯ�����ޤ���������å�#{thread_id}:�쥹#{res_id}��¸�ߤ��ޤ���")
    end

    line = SleBbs::Resread.new(dbpath, res_id.to_s).read.to_s.chomp
    SleBbs::Html.new(cgi, "����å�#{thread_id}:�쥹#{res_id}<br>#{line}<br>�κ���򤷤Ƥ�����Ǥ���" +
              %Q|<form><input type="hidden" name="act" value="res_delete">| <<
              %Q|<input type="hidden" name="res_id" value="#{res_id}">| <<
              %Q|<input type="hidden" name="thread_id" value="#{thread_id}">| <<
              %Q|<input type="submit" value="�쥹���"></form><hr>|)

  when  "res_delete"

    thread_id = cgi.params['thread_id'][0].untaint
    res_id  = cgi.params['res_id'][0].untaint.to_i
    line    = cgi.params['line'][0].untaint

    SleBbs::Resedit.delete(SleBbs::Config[:dbpath] + "/#{thread_id}#{SleBbs::Config[:dbextname]}", res_id-1, line)
    SleBbs::Html.new(cgi, "�쥹�κ������λ���ޤ�����������å�#{thread_id}:�쥹#{res_id}")

  when "auth_change"

    user = cgi.params['user'][0]
    pass = cgi.params['pass'][0]

    Auth::user_regist(cgi, user, pass)

    require 'digest/sha2'

    File.open(SleBbs::Config[:config_path], 'r+') do |file|
      text = file.read

      text.sub!(/^.*:auth .*$/, "    :auth      => true,")
      text.sub!(/^.*:auth_user .*$/, %Q|    :auth_user => "#{user}",|)
      text.sub!(/^.*:auth_pass .*$/, %Q|    :auth_pass => "#{Digest::SHA256.hexdigest(pass)}",|)
          
      file.rewind
      file.print text
      file.flush
      file.truncate(file.pos)
    end

    SleBbs::Html.new(cgi, "ǧ�����꤬��λ���ޤ�����")

  else
    display_text = SleBbs::Msg["thread_index"]

    thread = SleBbs::Threadread.new
    thread_convoy = %Q|<table class="list"><tr><th class="list">No</th><th class="list">����åɥ����ȥ�</th><th class="list">��Ƽ�̾</th><th class="list">�쥹</th><th class="list">�ǽ������</th></tr>\n|

    thread_body = thread.thread do |thread_id|
      text =  ''
      text << %Q|<form method="post" action="update.cgi">\n| <<
        %Q|<input type="hidden" name="act" value="thread_delete">\n| <<
        %Q|<input type="hidden" name="thread_id" value="#{thread_id}">\n| <<
        %Q|<input type="submit" value="����åɺ��">\n| <<
        %Q|</form>| <<
        %Q|<form method="post" action="update.cgi">\n| <<
        %Q|<input type="text" name="res_id" size=6>\n| <<
        %Q|<input type="hidden" name="act" value="res_delete_confirm">\n| <<
        %Q|<input type="hidden" name="thread_id" value="#{thread_id}">\n| <<
        %Q|<input type="submit" value="�쥹���">\n| <<
        %Q|</form>\n| <<
        %Q|<hr>|
    end

    thread_body << %Q|<h2>ǧ��</h2>| <<
        %Q|�桼��̾�ȥѥ���ɤ��ѹ����Ԥ��ޤ���<br>| <<
        %Q|<div class="form">| <<
        %Q|<form method="post" name="auth" action="update.cgi">| <<
        %Q|<input type="hidden" name="act" value="auth_change">\n| <<
        %Q|<div class="title">user:<input type="text" name="user" size="15"></div>| <<
        %Q|<div class="title">pass:<input type="password" name="pass" size="15"></div>| <<
        %Q|<div class="button"><input type="submit" value="Submit"></div>| <<
        %Q|</form>| <<
        %Q|</div>|

    display_text << thread_body
    SleBbs::Html.new(cgi, display_text)
  end

rescue
  print "Content-Type: text/plain\n\n"
  exception = "#$! (#{$!.class})" + "\n" + 
        $!.backtrace.join("\n")
  puts exception

  open("#{SleBbs::Config[:bbspath]}/exception", "w") do |log|
    log.puts  exception
  end

end

