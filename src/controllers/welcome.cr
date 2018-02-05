class Welcome < Application
  base "/"

  def index
    response.headers["Date"] = time_now
    welcome_text = "You're riding on Spider-Gazelle!"

    respond_with do
      html Kilt.render("src/views/welcome.ecr")
      text "Welcome, #{welcome_text}"
      json({welcome: welcome_text})
      xml do
        XML.build(indent: "  ") do |xml|
          xml.element("welcome") { xml.text welcome_text }
        end
      end
    end
  end
end
