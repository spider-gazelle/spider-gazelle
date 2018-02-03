class Welcome < Application
  base "/"

  def index
    response.headers["Date"] = time_now
    render html: "<body><h1>Welcome</h1><br />You're riding on Spider-Gazelle!</body>"
  end
end
