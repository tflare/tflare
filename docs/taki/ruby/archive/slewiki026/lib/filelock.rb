# $Id: filelock.rb 163 2006-05-25 13:04:10Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

module SleWiki

#
# module Filelock
#
module Filelock
  VERSION = '0.0.2'

  class FilelockError < StandardError; end

  def Filelock::lock(path)
    lockpath = path + 'lock'

    unless  File::exist?(lockpath)

      open(lockpath, "w").close

      if  block_given?
        begin
          yield
        ensure
          Filelock::unlock(path)
        end
      end
    else

      10.times do
        unless  File::exist?(lockpath)
          Filelock::lock(lockpath)
        else
          sleep(0.5)
        end
      end

      raise Filelock::FilelockError
    end
  end

  def Filelock::unlock(path)
    lockpath = path + 'lock'

    File::delete(lockpath)
  end
end
end