require 'bundler/setup'
require 'eventmachine'
require 'evma_httpserver'
require 'dbus'
require 'rype'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'thor'
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

  class Bot < Thor

    desc "start [CHAT_ID]", "start cogbot and add webhook to specific chatroom"
    def start(chat_id="")
      puts "Starting skybot"
      pid_file = File.join('/', 'tmp', 'skybot.pid')
      if File.exist?(pid_file)
        puts "skybot already running"
        exit
      end

      Dir.mkdir(File.join(ROOT_DIR, 'log'), 0700) unless File.directory?(File.join(ROOT_DIR, 'log'))
      threads = []
      Daemons.daemonize(
        :app_name => 'skybot',
        :dir_mode => :normal,
        :log_dir => File.join(ROOT_DIR, 'log'),
        :log_output => true,
        :dir => File.join('/', 'tmp')
      )

      Rype.on(:chatmessage_received) do |chatmessage|
        chatmessage.from do |from|
          chatmessage.from_name do |from_name|
            chatmessage.body do |body|
              chatmessage.chat do |chat|
                chat.members do |members|
                  is_private = members.length == 2
                  to, text   = parse_body(body)
                  Rype::Logger.info "chat name: #{chat.chatname}"
                  Rype::Logger.info "from: #{from_name}"
                  Rype::Logger.info "private chat: #{is_private}"
                  Rype::Logger.info "body: #{body}"
                  if body =~ /^(hi|hello|morning|evening|heyo)$/
                    chat.send_message("Greetings, #{from_name}") #if from_name == "Wei-fong Chang"
                  elsif body =~ /(https?\:[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)/i
                    url = body.scan(/(https?\:[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)/i).first
                    msg = url_parse(url[0])
                    chat.send_message("#{from_name}'s url [ #{msg} ]")
                  elsif body =~ /^\.u (.*)$/
                    query = /\.u (.*)$/.match(body)[1]
                    msg = urban_query(query)
                    chat.send_message("\"#{msg}\"")
                  end
                end
              end
            end
          end
        end
      end

      Rype.attach("skybot").join
    end

    desc "server [CHAT_ID]", "start post server"
    def server(chat_id="")
      if chat_id == ""
      	puts "No chatroom specified."
      	exit
      elsif chat_id == "stop"
      	puts "Stopping skybot"
      	server_pid_file = File.join('/', 'tmp', 'skybot_server.pid')
      	if File.exist?(server_pid_file)
      	  pidserver = File.read(server_pid_file).to_i
      	  Process.kill('TERM', pidserver)
      	else
      	  puts "no skybot server running"
      	end
      else
      	Daemons.daemonize(
      	  :app_name => 'skybot_server',
      	  :dir_mode => :normal,
      	  :log_dir => File.join(ROOT_DIR, 'log'),
      	  :log_output => true,
      	  :dir => File.join('/', 'tmp')
      	)
      	Rype.attach('skybot')
      	Signal.trap('TERM') { EM.stop }
      	puts "Start server"
      	EM.run do
      	  EM.add_timer(3) do
      	    EM.start_server(
      	      Skybot.config.server.ip,
      	      Skybot.config.server.port,
      	      Server,
      	      chat_id, Rype
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
      Rype::Logger.set(Logger.new(File.join(ROOT_DIR, 'skybot.log')))
      Rype.attach("skybot")
      Rype.chats do |chats|
        chats.each do |chat|
          p chat.chatname
        end
      end
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







