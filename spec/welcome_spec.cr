require "./spec_helper"

describe Welcome do
  # ==============
  #  Unit Testing
  # ==============
  it "should generate a date string" do
    # instantiate the controller you wish to unit test
    welcome = Welcome.spec_instance(HTTP::Request.new("GET", "/"))

    # Test the instance methods of the controller
    welcome.set_date_header.should contain("GMT")
  end

  # ==============
  # Test Responses
  # ==============
  client = AC::SpecHelper.client

  # optional, use to change the response type
  headers = HTTP::Headers{
    "Accept" => "application/yaml",
  }

  it "should welcome you with json" do
    result = client.get("/")
    result.body.should eq %("You're being trampled by Spider-Gazelle!")
    result.headers["Date"].should_not be_nil
  end

  it "should welcome you with yaml" do
    result = client.get("/", headers: headers)
    result.body.should eq "--- You're being trampled by Spider-Gazelle!\n"
    result.headers["Date"].should_not be_nil
  end

  it "should extract params for you" do
    result = client.post("/api/400")
    JSON.parse(result.body).should eq({"result" => 400})
  end
end
