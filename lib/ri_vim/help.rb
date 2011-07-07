class RIVim
  class Help
    def self.help
      readme = File.expand_path("../../../README.markdown", __FILE__)
      help = "RIVim help\n\n" + File.read(readme)
    end
  end
end
