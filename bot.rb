require 'bundler/setup'
require 'dbus'
require 'rype'
require 'open-uri'
require 'nokogiri'
require 'cgi'

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

Rype.on(:chatmessage_received) do |chatmessage|
  chatmessage.from do |from|
    chatmessage.from_name do |from_name|
      chatmessage.body do |body|
        chatmessage.chat do |chat|
          chat.members do |members|
            is_private = members.length == 2
            to, text   = parse_body(body)
            puts "chat name: #{chat.chatname}"
            puts "private chat: #{is_private}"
            puts "body: #{body}"
            if body =~ /^(hi|hello|morning|evening|heyo)$/
              chat.send_message("Greetings, #{from_name}")
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

Rype.attach
Rype.thread.join

