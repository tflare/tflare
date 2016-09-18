#!/usr/local/bin/ruby -Ke
# $Id: index.cgi 163 2006-05-25 13:04:10Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

begin

  BEGIN { STDOUT.binmode }
  $SAFE = 1

  require 'slewiki'
  require 'swconfig'

  SleWiki::Distribute::new

rescue

  open("#{SleWiki::Config[:slewikipath]}/exception", "w") do |log|
    exception = "#$! (#{$!.class})" + "\n" + 
          $!.backtrace.join("\n")
    log.puts  exception
  end

  if SleWiki::Config[:debug_mode]
    print "Content-Type: text/plain\n\n"
    puts exception
  else
    print "Content-Type: text/plain\n\n"
    puts SleWiki::Msg["system_error"]
  end

end



