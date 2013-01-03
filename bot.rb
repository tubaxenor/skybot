require 'rype'

def parse_body(body)
  case body
  when /^! *(.*)/           ; [Config.me, $1]
  when /^> *(.*)/           ; [Config.me, "eval #{$1}"]
  when /^@(\w+)[,;:]? +(.*)/; [$1, $2]
  when /^(\w+)[,;:] +(.*)/  ; [$1, $2]
  else [nil, body]
  end
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
            if body =~ /greensky/
              chat.send_message("huh? who call me ?")
            end
          end
        end
      end
    end
  end
end

Rype.attach
Rype.thread.join

