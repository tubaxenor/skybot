require_relative '../helper.rb'

describe Skybot::Bot do
	it "can attach to skype" do
		instance = Skybot::Bot.new("test")
		instance.status.must_equal "OK"
	end
end