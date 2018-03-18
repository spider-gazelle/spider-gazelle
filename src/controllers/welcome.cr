class Welcome < Application
  base "/"

  def index
    welcome_text = "You're being trampled by Spider-Gazelle!"

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
