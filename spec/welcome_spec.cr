require "./spec_helper"

describe Welcome do
  # ==============
  #  Unit Testing
  # ==============
  it "should generate a date string" do
    # instantiate the controller you wish to unit test
    welcome = Welcome.new(context("GET", "/"))

    # Test the instance methods of the controller
    welcome.time_now.should contain("GMT")
  end

  # ==============
  # Test Responses
  # ==============
  with_server do
    it "should welcome you" do
      result = curl("GET", "/")
      result.body.should eq("<!DOCTYPE html>\n<html lang=\"en\">\n<head><title>Welcome</title></head>\n<body>You're riding on Spider-Gazelle!</body>\n</html>\n")
      result.headers["Date"]?.nil?.should eq(false)
    end
  end
end
