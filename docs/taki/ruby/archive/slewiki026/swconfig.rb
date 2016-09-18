# $Id: swconfig.rb 163 2006-05-25 13:04:10Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

module SleWiki

module Config
  class ConfigError < StandardError; end;

  root = File::dirname(__FILE__)

  SW_CONFIG = {
    :title => "SleWiki test",

    # �ơ��ޥѥ�
    :theme_path => "#{root}/theme",

    # �������륷���ȥѥ�
    :css_path => './theme/grass/grass.css',

    # gzip����ž�� true false
    :gzip_transfer => false,

    # ���������
    :history_generation => 3,

    # �Хå����åפδֳ� �ÿ��ǻ���
    :backup_interval => 60 * 60 * 24 * 1, # 1 day

    # ¸�ߤ���ڡ���̾�˼�ư�ǥ�󥯤��뤫�ɤ��� true false
    :auto_link => true,

    # TOP�ڡ���
    :top_page => '[����]',

    ###################################
    # �ʰ�ǧ����
    # �ѥ���ɤϰŹ沽����Ƥ��ޤ���
    # ���̤δ������鹹����ԤäƤ���������

    # ǧ�ڤ򤹤٤ƤΥڡ����ǹԤ�:"private"
    # ���������������ڡ����Τ�ǧ�ڤ�Ԥ�:"protect"
    # ǧ�ڤ򤹤٤ƤΥڡ����ǹԤ�ʤ�:"public"
    :auth => "protect",
    :auth_user => "test",
    :auth_pass => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",

    ###################################
    #�ʲ��ˤĤ��Ƥϡ��̾��ѹ�����ɬ�פϤ���ޤ���

    :slewikipath => root,

    :debug_mode => false,

    # �¹ԥե�����Υѥ������ꤹ�롣
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