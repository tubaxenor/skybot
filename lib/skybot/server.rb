require 'rype'
require "cgi"
require "yajl"

class Server < EM::Connection
  include EM::HttpServer

  def initialize(chat_id, rype)
    @chat_id = chat_id
    @rype = rype
  end

  def post_init
    super
    no_environment_strings
  end

  def process_http_request
    if @http_request_method == "POST"
        hash = Yajl::Parser.parse(URI.unescape(@http_post_content[8..-1]))
        Rype::Logger.info(hash.inspect)
	hash['commits'].each do |c|
	  file_modification = "mod #{c['modified'].count} del #{c['removed'].count} add #{c['added'].count}"
	  msg = "%s -> %s / %s" % [
	    c['committer']['name'],
	    CGI::unescape(c['message']),
	    file_modification
	  ]
	@rype.chat(@chat_id).send_message(msg)
      end
    end

    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.send_response
  rescue Exception => e
    Rype::Logger.error e
  end

  private
  def short(x)
    x.map { |l| l.gsub(/([^\/]*)\//) { |s| s[0,1] + '/'} }
  end
end
