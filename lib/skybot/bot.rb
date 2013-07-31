require 'dbus'

### Monkey patch
class DBus::Connection
  def update_buffer
    @buffer += @socket.read_nonblock(MSG_BUF_SIZE)
  rescue EOFError
    raise                     # the caller expects it
  rescue Errno::EWOULDBLOCK
    # simply fail the read if it would block
    return
  rescue Exception => e
    puts "Oops:", e
    raise if @is_tcp          # why?
    puts "WARNING: read_nonblock failed, falling back to .recv"
    @buffer += @socket.recv(MSG_BUF_SIZE)
  end
end

module Skybot
	class Bot
		attr_reader :status, :skype, :connected, :thread, :events
		def initialize(appname="skybot")
			@appname = appname
      @dbus = DBus::SessionBus.instance
      dbus_service = @dbus.service("com.Skype.API")
      @skype = dbus_service.object('/com/Skype')
      @skype.introspect
      @skype.default_iface = "com.Skype.API"
      @status, = @skype.Invoke "NAME #{@appname}"
      if @status == 'CONNSTATUS OFFLINE'
        raise StandardError, "You are currently offline."
      elsif @status != 'OK'
        raise StandardError, "Unknown Error, maybe you didn't accept the api access ?"
      end
      @skype.Invoke "PROTOCOL 7"
      @receiving_service = @dbus.request_service("com.tubaxenor.skybot-#{@appname.gsub(/[^A-Za-z0-9-]/, '-')}-#{Process.pid}")
      @loop = DBus::Main.new
      @events = {}
      @connected = true
		end

		def add_event(scope, proc=nil, &block)
      @events[scope] ||= []
      @events[scope] << (proc ? proc : block)
		end

    def invoke(message, &block)
      if block_given?
        @skype.Invoke(message) do |headers, answer|
          block.call(answer)
        end
      else
        answer = @skype.Invoke(message) do |_, _|
          # Huh? Without passing in a block, sometimes it hangs...??
        end
        answer.split[3..-1].join(' ')
      end
    end

    def run
      raise StandardError, "Skybot not connected to Skype." unless @connected
      # @thread ||= Thread.new do
      callback_interface = Class.new(DBus::Object) do
        def initialize(path, events)
          @events = events
          super(path)
        end
        dbus_interface "com.Skype.API.Client" do
          dbus_method :Notify, "in data:s" do |message|
            Logger.info message
            Bot.dispatch(message, @events)
          end
        end
      end
      @receiving_service.export(callback_interface.new("/com/Skype/Client", @events))
      @loop << @dbus
      @loop.run
      # end
    end

		def self.dispatch(message, events)
      events.keys.each do |key|
        next unless match = Regexp.new("^#{key}").match(message)
        events[key].each{ |callback| callback.call(*match.captures) }
      end
		end

    # end
	end
end