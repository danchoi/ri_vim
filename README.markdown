# RIVim

RIVim lets search and navigate Ruby library and gem documentation inside Vim.

[screenshots]

Benefits:

* autocomplete helps you look up classes and methods 

## Prerequisites

* Ruby 1.9.2
* Vim 7.3 (will not work on 7.2) 

## Install

    gem install ri_vim

Then

    ri_vim_install

`ri_vim_install` installs a Vim plugin into your ~/.vim/plugin
directory. 

If you get an error message saying that ri_vim_install is missing, then you
probably have a `PATH` issue. Try one of these workarounds:

* Put the directory where Rubygems installs executables on your `PATH`
* Try installing with `sudo gem install ri_vim && ri_vim_install`

To upgrade ViTunes to a newer version, just repeat the installation procedure.
Don't forget to run `ri_vim_install` again after you download the new gem.



