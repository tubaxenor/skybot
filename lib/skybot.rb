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

module Skybot

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
                  Rype::Logger.info "private chat: #{is_private}"
                  Rype::Logger.info "body: #{body}"
                  if body =~ /^(hi|hello|morning|evening|heyo)$/
                    chat.send_message("Greetings, #{from_name}")
                  elsif body =~ /(https?\:[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)/i
                    url = body.scan(/(https?\:[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)/i).first
                    msg = url_parse(url[0])
                    chat.send_message("#{from_name}'s url [ #{msg} ]")
                  elsif body =~ /^\.u (.*)$/
                    query = /\.u (.*)$/.match()[1]
                    msg = urban_query(query)
                    chat.send_message("\"#{msg}\"")
                  end
                end
              end
            end
          end
        end
      end

      Rype.attach("skybot")
      threads << Rype.thread
      if chat_id != ""
        threads << Thread.new do 
          EM.run do
            EM.start_server(
              "127.0.0.1",
              "9990",
              Server,
              chat_id
            )
          end
        end
      end
      threads.each do |t|
        t.join
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
        CGI.unescape_html Nokogiri::HTML(open(url)).at("title").text.gsub(/\s+/, ' ')
      rescue
        "no title found"
      end
  end

end







