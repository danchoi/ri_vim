class RIVim
  class Install
    def self.install_vim_plugin
      require 'erb'
      plugin_template = File.read(File.join(File.dirname(__FILE__), 'plugin.erb'))
      vimscript_file = File.join(File.dirname(__FILE__), 'ri.vim')

      ri_vim_tool_path = "ri_vim"
      plugin_body = ERB.new(plugin_template).result(binding)

      `mkdir -p #{ENV['HOME']}/.vim/plugin`
      File.open("#{ENV['HOME']}/.vim/plugin/ri.vim", "w") {|f| f.write plugin_body}
      puts "Installed ri.vim into your ~/.vim/plugin directory."
      puts "You should be able to invoke RIVim in Vim with <Leader>r or <Leader>R."

    end

  end
end
