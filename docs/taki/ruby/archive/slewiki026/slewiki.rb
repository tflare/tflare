# $Id: slewiki.rb 163 2006-05-25 13:04:10Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

#
# module SleWiki
#
module SleWiki

  VERSION = '0.2.6'

  require 'cgi'
  require 'cgi/session'
  require 'erb'
  require 'digest/sha2'

  require 'lib/utils'
  require 'lib/stringutils'
  require 'lib/gzip'

  if RUBY_VERSION > "1.8.0"
    require 'fileutils'
  else
    require 'lib/fileutils'
  end


  #
  # class Page
  #  definition a Page.
  #
  class Page

    def initialize(cgi)

      @cgi = cgi
    end

    def store_read(path=nil)

      PageStore.new(@cgi, @page_id, path).read
    end


    #######
    public
    #######

    def Page.index

      Page.path.each do |filename|
        yield filename
      end
    end

    def Page.path
      Dir.glob("#{Config[:store_path]}/**/*#{Config[:store_extname]}")
    end

  end

  #
  # class ViewPage
  #  definition a ViewPage.
  #
  class ViewPage < Page

    def initialize(cgi, page_id=nil)
      super(cgi)

      if page_id
        @page_id = page_id
      else
        @page_id = @cgi.escape_param('page_id').escape
      end
    end

    def output
      text = "<h2>#{@page_id.unescape}</h2>"
      text << store_read
      Html.new(@cgi, text)
    end
  end

  #
  # class HistoryPage
  #  definition a HistoryPage.
  #
  class HistoryPage < ViewPage

    def output
      text = ''

      (1..Config[:history_generation]).each do |generation|
        path = Config[:store_path] + "/#{@page_id}#{Config[:store_extname]}.#{generation.to_s}"
        if File.exist?(path.untaint)
          text << "<h2>#{@page_id.unescape}#{generation.to_s}#{Msg['before_generation']}</h2>"
          text << store_read(path)
        end
      end

      Html.new(@cgi, text)
    end
  end

  #
  # class EditPage
  #  definition a EditPage.
  #
  class EditPage < Page

    def initialize(cgi)
      super
      @page_id = cgi.escape_param('page_id').escape
    end

    def output
      @title  = @page_id.unescape
      @text = store_read
      @text = Format::input_format(@text)

      Html.new(@cgi, erb("editform.rhtml"))
    end
  end

  #
  # class ListPage
  #  definition a ListPage.
  #
  class ListPage < Page

    #######
    private
    #######

    def title
      Msg["page_list"]
    end

    def list_format

      filename = nil
      text     = ''

      text << "<h2>#{title}</h2>\n"
      text << "<table class='list'>\n"
      text << "<tr class='listtitle'>\n"
      text << "<th class='list'>#{Msg['page_name']}</th>\n"
      text << "<th class='list'>#{Msg['last_modified']}</th>\n"
      text << "</tr>\n"

      index do |filename|
         text << yield(filename)
      end

      text << "</table>"

      if filename == nil
         text =  "<h2>#{title}</h2>"
         text << Msg["no_page"]
      end

      Html.new(@cgi, text)
    end

    def index
      Page.path.sort_by {|name| name.downcase }.
        each do |filename|

        yield filename
      end
    end

    #######
    public
    #######

    def output

      list_format do |filename|
        list =  "<tr class='listbody'>"
        list << "<td>#{Format::make_link(filename)}</td>"
        list << "<td>"
        list << File.mtime(filename.untaint).format_date
        list << "</td>"
        list << "</tr>"
        list << "\n"
      end
    end

  end

  #
  # class RecentPage
  #  definition a RecentPage.
  #
  class RecentPage < ListPage

    def title
      Msg["recent_list"]
    end

    def index

      # A file is sorted in the new order of updating time.
      Page.path.sort_by {|f| File.mtime(f.untaint).to_i }.reverse.
        each do |filename|

        yield filename
      end
    end
  end


  #
  # class TopPage
  #  definition a TopPage.
  #
  class TopPage < Page

    def TopPage.system_page_list

      list = []
      list << "[#{Msg['list']}]"
      list << "[#{Msg['recent']}]"
    end

    def TopPage.system_page_list?(page)

      TopPage.system_page_list.each do |list|
        if list == page
          return true
        end
      end
      return false
    end

    def TopPage.change_list

      user_page_list = Page.path.collect do |list|
        list = TopPage.get_pass(list)
      end
      change_list = system_page_list + user_page_list
    end

    def TopPage.now
      toppage = Config[:top_page]
      toppage = TopPage.get_pass(toppage)
    end

    def output

      if TopPage.now == "[#{Msg['list']}]"
        ListPage.new(@cgi).output
        return
      end

      if TopPage.now == "[#{Msg['recent']}]"
        RecentPage.new(@cgi).output
        return
      end

      ViewPage.new(@cgi, TopPage.now.escape).output
    end

    private
    def TopPage.get_pass(list)
      list = list.unescape
      list = list.sub(%r|#{Config[:store_path]}/|, '')
      list = list.sub(%r|#{Config[:store_extname]}|, '')
    end
  end

  #
  # class AuthPage
  #  definition a Auth.
  #
  class AuthPage < Page

    def auth_check

      begin
        boolean = Auth.simple_auth(@cgi)
        return boolean
      rescue Auth::AuthError
        Html.new(@cgi, erb("authpage.rhtml"))
        return false
      end
    end
  end


  class AdminPage < Page

    def process
      title_change
      thema_change
      toppage_change

      if Config[:auth] == "private" or Config[:auth] == "protect"
        auth_change
      end
      TopPage.new(@cgi).output
    end

    def title_change
      title = @cgi.escape_param('title')
      return if title == Config[:title]
      return if title == ''

      ConfigWrite.init do
        ConfigWrite.write('title', title)
      end

    end

    def thema_change
      return if Thema.now == @cgi.escape_param('thema')

      thema = @cgi.escape_param('thema')
      ConfigWrite.init do
        ConfigWrite.write('css_path', "./theme/#{thema}/#{thema}.css")
      end

    end

    def toppage_change
      return if TopPage.now == @cgi.escape_param('toppage')

      toppage = @cgi.escape_param('toppage')

      if TopPage.system_page_list?(toppage)
        toppage = "#{Config[:store_path]}/" +
                   toppage.escape           +
                   Config[:store_extname]
      end

      ConfigWrite.init do
        ConfigWrite.write('top_page', "#{toppage}")
      end

    end

    def auth_change
      user = @cgi.escape_param('user')
      pass = @cgi.escape_param('pass')

      return if user == '' or pass == ''

      begin 
        Auth::user_regist(@cgi, user, pass)
      rescue Auth::RegistError
        Html.new(@cgi, erb("authpage.rhtml"))
        return false
      end

      ConfigWrite.init do

        ConfigWrite.write('auth', true)
        ConfigWrite.write('auth_user', user)
        ConfigWrite.write('auth_pass', Digest::SHA256.hexdigest(pass))

      end
    end

  end

  class PageStore

    require 'lib/filelock'

    def initialize(cgi, page_id, path=nil)

      @cgi     = cgi
      @page_id = page_id

      if path
        @path = path
      else
        @path = Config[:store_path] + "/#{page_id}#{Config[:store_extname]}"
      end
      @path.untaint

    end

    def write(text, path=nil)

      if path
        @path = path
      else
        @path = @path.escape
        if @cgi.escape_param('act') == "make_page"
          write_prep
        end
      end

      History.new(@path).history

      begin
        Filelock::lock(@path) do
          File.open(@path, 'w') do |file|
            file.write(text)
          end
        end
      rescue Filelock::FilelockError
        Html.new(@cgi, Msg["lock"])
        exit
      end

      if path == nil and @cgi.escape_param('act') == "make_page"
        Format::allset_auto_link(@cgi, File.basename(@path, Config[:store_extname]).unescape)
      end
    end

    def read

      begin
        File.open(@path, 'r') do |file|
          file.read
        end
      rescue Errno::ENOENT
        Html.new(@cgi, Msg["no_store_file"])
        exit
      end
    end

    def delete

      @path = @path.escape

      History.new(@path).history
      Format::allset_auto_link(@cgi, File.basename(@path, Config[:store_extname]).unescape)
      Html.new(@cgi, Msg["delete_complete"])
      exit
    end

    private
    def write_prep

      if %r|\.{2}\/| =~ @path
        Html.new(@cgi, Msg["theme_nameerror"])
        exit
      end

      if @page_id and @page_id[0].chr == '.'
        Html.new(@cgi, Msg["head_dotword"])
        exit
      end

      if FileTest.exist?(@path)
        Html.new(@cgi, Msg["word_define"])
        exit
      end

      FileUtils.mkdir_p(File.dirname(@path))

    end
  end

  #
  # class Write
  #  definition a Write.
  #
  class Write

    def initialize(cgi)

      @cgi = cgi
    end

    #######
    private
    #######

    def title
      title = @cgi.escape_param('title')

      if title.empty?
        title = Time.now.to_i.to_s
      end

      title
    end

    def text
      text = @cgi.escape_param('text')
      text = Format::output_format(text, title)
      delete_check(text) if @cgi.escape_param('act') == "edit_write"
      text_check(text)   if @cgi.escape_param('act') == "edit_write"
      text
    end

    def text_check(text)
      old_text = PageStore.new(@cgi, title.escape, nil).read
      if text == old_text
        Html.new(@cgi, Msg["text_equal"])
        exit
      end
    end

    def delete_check(text)
      if text.empty?
        PageStore.new(@cgi, title).delete
      end
    end

    #######
    public
    #######

    def write
      PageStore.new(@cgi, title).write(text)
    end
  end

  #
  # class Backup
  #  definition a Backup.
  #

  class Backup

    def initialize
      @backup_dir  = Config[:store_path]
      @backup_time_f = "#{@backup_dir}/backuptime"
      @interval    = Config[:backup_interval]

      backup
    end


    def backup

      if timing_check?

        Page.index do |path|
          path = path.untaint
          FileUtils.copy(path, path + ".bak")
        end
        write_backup_time(Time.now.to_i.to_s)
      end
    end


    def timing_check?

      if  Time.now > read_backup_time() + @interval
        true
      else
        false
      end
    end

    def read_backup_time

      begin
        open(@backup_time_f, "r") do |file|

          backup_time = Time.at(file.read.chomp.to_i)
        end
      rescue Errno::ENOENT

        backup_time = Time.at(0)
      rescue
        raise
      end
    end

    def write_backup_time(time)

      open(@backup_time_f, "w") do |file|
        file.puts  time
      end
    end
  end


  class History

    def initialize(path)

      @path = path
    end

    def history
      (Config[:history_generation]).downto(1) do |generation|
        from_path = @path + from_gene(generation)
        if File.exist?(from_path)
          FileUtils.mv(from_path, @path + ".#{generation.to_s}")
        end
      end
    end

    private
    def from_gene(generation)
      if generation == 1
         generation = ""
      else
         "." + (generation - 1).to_s
      end
    end
  end


  #
  # module Thema
  #  definition a Thema.
  #
    module Thema

      module_function

      def index
        entries = Dir.entries(Config[:theme_path])
        thema_pass = entries.delete_if{|path| File.file?(path.untaint) }
        thema_pass = entries.delete_if{|path| path[0].chr == '.' }
        thema_pass = entries.delete_if{|path| path == 'template' }
      end

      def now
        thema_re = %r|\./theme/(.+)/.+\.css| 
        if thema_re =~ Config[:css_path]
           now_thema = $1
        end
      end
    end

  #
  # module Format
  #  definition a Format.
  #
    module Format

      module_function

      URL_RE = %r{((?:https?|ftp)://[-!a-zA-Z0-9\.\/+#_?~&%=^\\@:;,'"*()]+)}

      # input_format process and output_format process always pair.
      # output_format convert
      # input_format change back

      def input_format(text)
        text = text.gsub(/<br>/, "\r\n")
        text = text.gsub(/<a href=.*?>/, "") # adhoc delete a tag
        text = text.gsub(/<\/a>/, "")        # adhoc delete a tag

        text = text.gsub(/&nbsp;/, " ")
      end

      def output_format(text, title=nil)

        clean_white_space!(text)

        if Config[:auto_link] == false
          return format_text = url_convert(text)
        end

        if URL_RE =~ text
          format_text = ''
          format_text << auto_link($PREMATCH, title)
          format_text << url_convert($MATCH)
          while URL_RE =~ post_match = $POSTMATCH
            format_text << auto_link($PREMATCH, title)
            format_text << url_convert($MATCH)
          end
          format_text << auto_link(post_match, title)
        else
          format_text = auto_link(text, title)
        end

        format_text.gsub(/<br>[ ]+/){ $MATCH.gsub(/[ ]/, '&nbsp;') }
      end

      def auto_link(text, title)
        path = Page.path

        # store empty
        return text if path == []
        page_list = path.collect do |path|
          basename = File.basename(path, Config[:store_extname]).unescape

          # 編集しようとしているファイルと同じ名前の場合リンクしない
          if title and title == basename
            nil
          else
            Regexp::quote(basename)
          end
        end

        page_list = /#{page_list.compact.reverse.join('|')}/
        text.gsub(page_list){|word| make_link(page_filename(word.escape), word)}
      end

      def allset_auto_link(cgi, str)

        Page.index do |path|
          page = PageStore.new(cgi, nil, path)
          old_text = page.read
          if old_text.include?(str)
            text = input_format(old_text)
            change_text = output_format(text)
            if old_text != change_text
              page.write(change_text, path)
            end
          end
        end
      end

      def page_title(filename)
        /#{Config[:store_path]}\/(.+)#{Config[:store_extname]}/ =~ filename
        page_title = $1
      end

      def page_filename(title)

        Page.path.each do |path|
          if path.include?(title + Config[:store_extname])
            return path
          end
        end

      end

      def make_link(filename, title=nil)
        page_id = page_title(filename)
        title   = page_id.unescape if title == nil
        text = ''
        text << %Q|<a href="#{Config[:indexpath]}?act=view&amp;|
        text << %Q|page_id=#{page_id}">#{title}</a>|
        text
      end

      def url_convert(text)
        text.gsub(URL_RE){%Q|<a href="#{$1}">#{$1}</a>|}
      end

      def clean_white_space!(text)
        text.gsub!(/\r\n/, "<br>")
        text.gsub!(/\r/, "<br>")
        text.gsub!(/\n/, "<br>")
        z_space = "\241\241"   # 全角 スペース
        text.gsub!(/<br>[ \t#{z_space}]+<br>/, "<br><br>")
        text.gsub!(/(?:<br>)+$/, '') # 行末改行カット
        text.gsub!(/(?:<br>){11,}/, "<br>" * 10) # 11行以上の改行は10行に切り詰める
        text
      end

    end

  #
  # class Distribute
  #  definition a Distribute.
  #

  class Distribute

    def initialize

      @cgi = CGI.new

      if Config[:auth] == "private"
        if AuthPage.new(@cgi).auth_check == false
           return
        end
      end

      Backup.new

      if @cgi.escape_param('act') and @cgi.escape_param('act') != ""
        __send__(@cgi.escape_param('act'))
      else
        top_page
      end
    end

    #######
    private
    #######

##現在のページに関する操作

    def view
      ViewPage.new(@cgi).output
    end

    def edit
      if AuthPage.new(@cgi).auth_check
        EditPage.new(@cgi).output
      end
    end

    def edit_write
      Security.check(@cgi)
      if AuthPage.new(@cgi).auth_check
        Write.new(@cgi).write
        redirect(@cgi, Config[:indexpath])
      end
    end

    def history
      HistoryPage.new(@cgi).output
    end
######

    def new_page
      if AuthPage.new(@cgi).auth_check
        Html.new(@cgi, erb("pageform.rhtml"))
      end
    end

    def make_page
      Security.check(@cgi)
      if AuthPage.new(@cgi).auth_check
        Write.new(@cgi).write
        redirect(@cgi, Config[:indexpath])
      end
    end

    def list
      ListPage.new(@cgi).output
    end

    def recent
      RecentPage.new(@cgi).output
    end

    def top_page
      TopPage.new(@cgi).output
    end

    def admin
      if AuthPage.new(@cgi).auth_check
        Html.new(@cgi, erb("admin.rhtml"))
      end
    end

    def adminedit
      Security.check(@cgi)
      if AuthPage.new(@cgi).auth_check
        AdminPage.new(@cgi).process
      end
    end

    def search
      require 'lib/search'
      search_text = @cgi.escape_param('search_text')
      Html.new(@cgi, Search.search(search_text))
    end

######
    def method_missing(message)
      Html.new(@cgi, Msg["method_missing"] + message.to_s)
      exit
    end

  end


  #
  # class Html
  #  definition a Html.
  #

  class Html

    def initialize(cgi, body)

      @cgi = cgi
      make(body)
    end


    #######
    private
    #######

    def make(body)

      html = ''
      html <<  erb("header.rhtml")
      html <<  body
      html <<  erb("footer.rhtml")

      send(html)
    end

    def head

      head = {
          'charset'     => 'euc-jp',
          'language'    => 'ja',
          'Cache-Control' => 'no-cache',
          'Pragma'    => 'no-cache',
      }

      if Gzip::exec?(@cgi)
        gzip_head = {'Content-Encoding' => 'gzip'}
        head.update(gzip_head)
      end

      return head
    end


    def send(page)

      if Gzip::exec?(@cgi)
        print @cgi.header(head())
        Gzip::write(@cgi, page)
      else
        @cgi.out(head()){page}
      end
    end

  end

  #
  # module Security
  #  definition a Security.
  #
  module Security

    def Security.check(cgi)
      random_num_check(cgi)
      request_method_check(cgi)
    end

    def Security.set_random_num
      random_num = rand

      ConfigWrite.init do
        ConfigWrite.write('random_num', random_num)
      end

      return random_num
    end

private

    def Security.get_random_num

      random_num = SleWiki::Config[:random_num]
      return random_num
    end

    def Security.random_num_check(cgi)
      if cgi.escape_param('random_num') != get_random_num
        Html.new(cgi, Msg["random_num_error"])
        exit
      end
    end

    def Security.request_method_check(cgi)
      if /post/i !~ cgi.request_method
        Html.new(cgi, Msg["getmethod_error"])
        exit
      end
    end
  end

  #
  # module Msg
  #  definition a Msg.
  #
  module Msg

    DEFINE = {}

    File.open("./msg_j.cfg"){|file|
      file.read.each_line do |line|
        next if /^#/   =~ line
        defkey, value  =  line.chomp.split(/\s+/)
        DEFINE[defkey] =  value
      end
    }

    def self.[](key)

      DEFINE[key] ||= DEFINE["msg_no_define"] + key
    end
  end

end
