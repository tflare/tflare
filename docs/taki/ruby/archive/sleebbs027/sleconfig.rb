# $Id: mtconfig.rb 157 2005-10-02 13:01:18Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

module SleBbs

module Config
  class ConfigError < StandardError; end;

  root = File::dirname(__FILE__)

  MC_CONFIG = {
    # BBS�Υ����ȥ�̾��
    :bbsname => "SleBbs_test",

    # �����Υ���åɺ����ε���: true false
    :new_thread => true,

    # ����åɤκ����
    :max_thread => 20,

    # �ҤȤĤΥ���åɤκ���쥹��
    :max_res => 200,

    # ���ɽ�����̤�ɽ������쥹
    :start_display_res => "|5",

    # ̾���ȥ᡼�륢�ɥ쥹��Ф�������: true false,
    :session => true,

    # �������륷���ȥѥ�
    :css_path => "./theme/basic/basic.css",

    # gzip����ž�� true false
    :gzip_transfer => false,

    # host̾��ɽ��, true false
    :host => true,

    # user_agent��ɽ��, true false
    :ua => true,

    # ̾�������Ϥ��ʤ�����ɽ������
    :noname => "NOBODY",

    # �ǡ����������ɽ������
    :delete_display => "delete",

    # 1�쥹����ʸ�ιԿ�����, false�����¤ʤ�
    :res_max_line => 20,

    # �Хå����åפδֳ� �ÿ��ǻ���
    :backup_interval => 60 * 60 * 24 * 1, # 1 day

    # ���ƥʥ󥹥ڡ�����ɽ�����롣: true false
    :maintenance_mode => false,

    ###################################
    # �ʰ�ǧ����
    # �ѥ���ɤϰŹ沽����Ƥ��ޤ���
    # ���̤δ������鹹����ԤäƤ���������

    # ǧ�ڤ�Ԥ�: true ǧ�ڤ�Ԥ�ʤ�:false
    :auth      => true,
    :auth_user => "test",
    :auth_pass => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",

    ###################################
    #�ʲ��ˤĤ��Ƥϡ��̾��ѹ�����ɬ�פϤ���ޤ���

    :bbspath => root,

    # �¹ԥե�����Υѥ������ꤹ�롣
    :indexpath => "index.cgi",
    :config_path => __FILE__,
    :dbpath => "#{root}/db",
    :dbextname => ".db",
    :templatepath => "#{root}/template",
  }

  # use Config[:bbsname]
  def self.[](key)
    unless MC_CONFIG.has_key?(key)
      raise ConfigError, "key not found: #{key}" 
    end
    MC_CONFIG[key]
  end

  def self.[]=(key, value)
    MC_CONFIG[key] = value
  end

end
end