# ri.vim / ri Vim plugin

The ri Vim plugin lets you search and navigate Ruby library and gem
documentation inside Vim.

[screenshots]

Advantages over the venerable command-line `ri` tool:

* write code and browse pertinent documentation in adjacent Vim windows
* powerful autocompletion help
* hyperlinking lets your jump from definition to definition
* run back and forth through your jump history with CTRL-o and CTRL-i
* jump directly to gem README's and into the gem source directories
* directly open corresponding HTML-formatted rdoc documentation


## Prerequisites

* Ruby 1.9.2 (but may work with other versions)
* Vim 7.3 (will not work on 7.2) 

## Install

    gem install ri_vim

Then

    ri_vim_install

`ri_vim_install` installs the ri.vim plugin into your ~/.vim/plugin directory. 

To upgrade ri.vim to a newer version, just repeat the installation procedure.
Don't forget to run `ri_vim_install` again after you download the new gem.




## Acknowledgements

Special thanks to Eric Hodel, the maintainer of ri and rdoc, for providing and
maintaining the whole ri and rdoc infrastructure that ri.vim builds on.

And to Tim Pope, who continues to lead the way in making Vim a
ultra-productive environment for Ruby programming.






