# $Id: swconfig.rb 163 2006-05-25 13:04:10Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

module SleWiki

module Config
  class ConfigError < StandardError; end;

  root = File::dirname(__FILE__)

  SW_CONFIG = {
    :title => "SleWiki test",

    # テーマパス
    :theme_path => "#{root}/theme",

    # スタイルシートパス
    :css_path => './theme/grass/grass.css',

    # gzip圧縮転送 true false
    :gzip_transfer => false,

    # 履歴の世代
    :history_generation => 3,

    # バックアップの間隔 秒数で指定
    :backup_interval => 60 * 60 * 24 * 1, # 1 day

    # 存在するページ名に自動でリンクするかどうか true false
    :auto_link => true,

    # TOPページ
    :top_page => '[一覧]',

    ###################################
    # 簡易認証用
    # パスワードは暗号化されています。
    # 画面の管理から更新を行ってください。

    # 認証をすべてのページで行う:"private"
    # 新規作成、修正ページのみ認証を行う:"protect"
    # 認証をすべてのページで行わない:"public"
    :auth => "protect",
    :auth_user => "test",
    :auth_pass => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",

    ###################################
    #以下については、通常変更する必要はありません。

    :slewikipath => root,

    :debug_mode => false,

    # 実行ファイルのパスを設定する。
    :indexpath => "index.cgi",

    :config_path => __FILE__,
    :store_path => "#{root}/store",
    :store_extname => ".db",
    :templatepath => "#{root}/template",
    :random_num => "0.928793479688466",
  }

  # use Config[:title]
  def self.[](key)
    unless SW_CONFIG.has_key?(key)
      raise ConfigError, "key not found: #{key}" 
    end
    SW_CONFIG[key]
  end

  def self.[]=(key, value)
    SW_CONFIG[key] = value
  end

end

end