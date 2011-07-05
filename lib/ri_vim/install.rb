class RIVim
  module Install
    def self.install_vim_plugin
      require 'erb'
      plugin_template = File.read(File.join(File.dirname(__FILE__), 'plugin.erb'))
      vimscript_file = File.join(File.dirname(__FILE__), 'vitunes.vim')
      plugin_body = ERB.new(plugin_template).result(binding)

      `mkdir -p #{ENV['HOME']}/.vim/plugin`
      File.open("#{ENV['HOME']}/.vim/plugin/ri.vim", "w") {|f| f.write plugin_body}
      puts "Installed vitunes.vim into your ~/.vim/plugin directory."
      puts "You should be able to invoke ViTunes in Vim with <Leader>i or <Leader>I."
      puts "If you want to start ViTunes directly, type `vitunes` on the command line."
    end

  end
end
