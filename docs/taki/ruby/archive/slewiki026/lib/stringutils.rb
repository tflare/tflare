# $Id: stringutils.rb 155 2005-09-21 13:23:24Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

class String

  def escape
    self.gsub(%r|([^./a-zA-Z0-9_-])|n) do
      escapestr = sprintf("%%%02X", $1.unpack("C")[0])
    end
  end

  def unescape
    self.gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
      unescapestr = [$1.delete('%')].pack('H*')
    end
  end
end

