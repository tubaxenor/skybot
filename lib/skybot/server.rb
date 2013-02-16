require 'rype'

class Server < EM::Connection
  include EM::HttpServer

  def initialize(chat_id)
    @chat_id = chat_id
  end

  def post_init
    super
    no_environment_strings
  end

  def process_http_request
    if @http_request_method == "POST"
    	Rype.chat(@chat_id).send_message(@http_post_content)
    end

    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.send_response
  rescue Exception => e
  	Rype::Logger.error e
  end
end