require "./spec_helper"

describe Welcome do
  # ==============
  #  Unit Testing
  # ==============
  it "should generate a date string" do
    # instantiate the controller you wish to unit test
    route_params = {} of String => String
    route_name = :index
    welcome = Welcome.new(context("GET", "/"), route_params, route_name)

    # Test the instance methods of the controller
    welcome.time_now.should contain("GMT")
  end

  # ==============
  # Test Responses
  # ==============
  with_server do
    it "should welcome you" do
      result = curl("GET", "/").not_nil!
      result.body.should eq("<body><h1>Welcome</h1><br />You're riding on Spider-Gazelle!</body>")
      result.headers["Date"].nil?.should eq(false)
    end
  end
end
