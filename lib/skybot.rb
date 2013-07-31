# $:.unshift File.expand_path(File.join(File.dirname(__FILE__), "lib"))

require 'bundler/setup'
require 'eventmachine'
require 'evma_httpserver'
require 'dbus'
require 'rype'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'thor'
require 'lib/skybot/logger'
require 'lib/skybot/bot'
require 'lib/skybot/server'
require 'lib/skybot/events'
require "daemons"
require 'ostruct'

module Skybot

  def self.config
    if File.exist? File.join(ROOT_DIR, 'config/config.yml')
      to_ostruct(YAML::load_file(File.join(ROOT_DIR, 'config/config.yml')))
    else
      to_ostruct(YAML::load_file(File.join(ROOT_DIR, 'config/config.default.yml')))
    end
  end

  class Runner < Thor

    desc "start", "start skybot"
    def start
      puts "Starting skybot"
      pid_file = File.join('/', 'tmp', 'skybot.pid')
      if File.exist?(pid_file)
        puts "skybot is already running"
        exit
      end

      Dir.mkdir(File.join(ROOT_DIR, 'log'), 0700) unless File.directory?(File.join(ROOT_DIR, 'log'))
      Daemons.daemonize(
        :app_name => 'skybot',
        :dir_mode => :normal,
        :log_dir => File.join(ROOT_DIR, 'log'),
        :log_output => true,
        :dir => File.join('/', 'tmp')
      )
      bot = Skybot::Bot.new("skybot")

      bot.add_event("CHATMESSAGE (.*) STATUS RECEIVED") do |chatmessage_id|
        received_msg = bot.skype.Invoke("GET CHATMESSAGE #{chatmessage_id} BODY")[0].split[3..-1].join(' ')
        from = bot.skype.Invoke("GET CHATMESSAGE #{chatmessage_id} FROM_DISPNAME")[0].split[3..-1].join(' ')
        chatname = bot.skype.Invoke("GET CHATMESSAGE #{chatmessage_id} CHATNAME")[0].split[3..-1].join(' ')

        if received_msg =~ /^(hi|hello|morning|evening|heyo)$/
          msg = "Greetings, #{from}"
          bot.skype.Invoke("CHATMESSAGE #{chatname} #{msg}") #if from_name == "Wei-fong Chang"
        elsif received_msg =~ /(https?\:[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)/i
          url = received_msg.scan(/(https?\:[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)/i).first
          title = url_parse(url[0])
          msg = "#{from}'s url [ #{title} ]"
          bot.skype.Invoke("CHATMESSAGE #{chatname} #{msg}")
        elsif received_msg =~ /^\.u (.*)$/
          query = /\.u (.*)$/.match(received_msg)[1]
          msg = urban_query(query)
          Skybot::Logger.info msg
          bot.skype.Invoke("CHATMESSAGE #{chatname} \"#{msg}\"")
        end
      end  
      bot.run
    end

    desc "server [CHAT_ID]", "start post server"
    def server(chat_id="")
      if chat_id == ""
      	puts "No chatroom specified. Please do \"skybot list\" to check the current running rooms first "
      	exit
      elsif chat_id == "stop"
      	puts "Stopping skybot server"
      	server_pid_file = File.join('/', 'tmp', 'skybot_server.pid')
      	if File.exist?(server_pid_file)
      	  pidserver = File.read(server_pid_file).to_i
      	  Process.kill('TERM', pidserver)
      	else
      	  puts "no skybot server running"
      	end
      else
        puts "Starting skybot server on #{Daemon}"
      	chat_id.daemonize(
      	  :app_name => 'skybot_server',
      	  :dir_mode => :normal,
      	  :log_dir => File.join(ROOT_DIR, 'log'),
      	  :log_output => true,
      	  :dir => File.join('/', 'tmp')
      	)
      	bot = Skybot::Bot.new("skybot")
      	Signal.trap('TERM') { EM.stop }
      	puts "Start server"
      	EM.run do
      	  EM.add_timer(3) do
      	    EM.start_server(
      	      Skybot.config.server.ip,
      	      Skybot.config.server.port,
      	      Server,
      	      chat_id, bot.skype
      	    )
      	  end
      	end
      end
    end

    desc "stop", "stop skybot"
    def stop
      puts "Stopping skybot"
      pid_file = File.join('/', 'tmp', 'skybot.pid')
      if File.exist?(pid_file)
      	pid = File.read(pid_file).to_i
      	Process.kill('TERM', pid)
      else
        puts "no skybot running"
      end
    end

    desc "restart", "restart skybot"
    def restart
      stop
      sleep(3)
      start
    end

    desc "list", "list chatroom"
    def list

      # bot
      # Rype.chats do |chats|
      #   chats.each do |chat|
      #     p chat.chatname
      #   end
      # end
    end

    private
      def parse_body(body)
        case body
        when /^! *(.*)/           ; [Config.me, $1]
        when /^> *(.*)/           ; [Config.me, "eval #{$1}"]
        when /^@(\w+)[,;:]? +(.*)/; [$1, $2]
        when /^(\w+)[,;:] +(.*)/  ; [$1, $2]
        else [nil, body]
        end
      end

      def urban_query(query)
        url = "http://www.urbandictionary.com/define.php?term=#{query}"
        CGI.unescape_html Nokogiri::HTML(open(url)).at("div.definition").text.gsub(/\s+/, ' ')
      rescue
        "no result found"
      end

      def url_parse(url)
        CGI.unescape_html Nokogiri::HTML(open(url), nil, "UTF-8").at("title").text.gsub(/\s+/, ' ').force_encoding('UTF-8')
      rescue
        "no title found"
      end

      def to_ostruct(obj)
        result = obj
        if result.is_a? Hash
          result = result.dup
          result.each do |key, val|
            result[key] = to_ostruct(val)
          end
          result = OpenStruct.new result
        elsif result.is_a? Array
          result = result.map { |r| to_ostruct(r) }
        end
        return result
      end
  end

end







