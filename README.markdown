# ri.vim : ri plugin for Vim

`ri.vim` lets you search and navigate Ruby library and gem documentation inside
Vim.

[screenshots]

Advantages over the venerable `ri` command-line tool:

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

This installs the ri.vim plugin into your ~/.vim/plugin directory. 

To upgrade ri.vim to a newer version, just repeat the installation procedure.
Don't forget to run `ri_vim_install` again after you download the new gem.

The next step is to make sure that you have ri documentation installed on your
system for everything you want to look up. See the **Generate ri documentation**
section below for help.

* * * 

## Commands

For the all the commands below, the mapleader is assumed to be `,`. If it is
`\` or something else for your setup, use that instead.

### Invoking the plugin

* `,r` opens the search/autocomplete window, and will use a horizontal split to
  display matching documentation
* `,R` opens the search/autocomplete window, and will use a vertical split to
  display matching documentatoin
* `,K` opens the search/autocomplete window and prefills it with the keyword
  under the cursor

These mappings will work irrespective of the filetype of your current buffer.
You don't have to be looking at a Ruby file to invoke ri.vim. You could, e.g.,
be writing a blog post about Ruby.

If these mapping clash or you don't like them, you can override them. See
**Changing keymappings** below.

### Using the search/autocomplete window

Withe the search/autocomplete window open, start typing the name of the class,
module, or method you want to lookup.

Press `TAB` to start autocompletion.

If you've started typing a name starting with a capital letter, you'll see
autocompletion suggestions for matching classes and modules. If you're looking
for a namespace-nested module or class, you can autocomplete the first 
namespace, type `:` and then press `TAB` again to autocomplete the next inner
namespace.

![screenshot](https://github.com/danchoi/ri_vim/raw/master/screens/nested_search.png)

If you've started typing a name starting with a lower case letter or 
a symbol that is valid in Ruby method names (i.e., `/^[=*\/&|%^\[<>]/`), ri.vim
will suggest matching methods from different classes and modules.

![screenshot](https://github.com/danchoi/ri_vim/raw/master/screens/method_search.png)

Use the standard Vim autocompletion commands to move up and down the match
list.

* `CTRL-p` and `CTRL-n` let you navigate the drop-down matches. Press `ENTER` to select
one.
* `CTRL-e` closes the match list and lets you continue typing
* `CTRL-u`: when the match list is active, cycles forward through the match
  list and what you've typed so far; when the match list is inactive, erases
  what you've typed.
* both `TAB` and `CTRL-x CTRL-u` reactivates autocompletion if it's gone away
* `CTRL-y` selects the highlighted match without triggering ENTER

When you're searching for a class or module (but not yet for method searches),
you will sometimes see a little number in parentheses to the right of a match.
This is a rough indicator of how much actual documentation there is to see for
that class or module. It actually represents how many "parts" of the generated
documentation has a "comment" associated with it. (Don't ask me what the
definition of a "part" is; it's just something the RDoc::RI codebase knows
about.)
    
### The documentation window

When you find a matching method or class or module and press `ENTER`, you
should see the ri documentation, with a little bit of syntax coloring, display
in a Vim window.

![screenshot](https://github.com/danchoi/ri_vim/raw/master/screens/ri_string_doc.png)

You can move to cursor to any valid Ruby method or class/module name on this
page and press `ENTER` to jump to the documentation.




* * *

## Generate ri documentation

`ri.vim` won't work very well unless you have generated ri documentation for
your Ruby built-in library, standard library, and your installed Ruby gems.

Please consult other reference sources for instructions specific to your
particular setup.

But I'll try to cover some common cases:

If you use RVM, run this to install ri documentation for the built-in and
standard library of your active Ruby installation:

    rvm docs generate-ri

You can check if this worked by running a command like `ri Enumerable` or `ri
IO` on the comand line. 

You may run into the following an error when you run this rvm command:

    uh-oh! RDoc had a problem:
    invalid option: --ri-site generator already set to ri

If you see this, you should patch the `~/.rvm/scripts/docs` script.  Find the
`generate_ri()` function and replace this line:

    rdoc -a --ri --ri-site > /dev/null 2>> ${rvm_log_path}/$rvm_docs_ruby_string/docs.log

with:

    rdoc -a --ri 

and run `rvm docs generate-ri` again.

To generate ri documentation for your gems, reinstall the ones currently
without ri documentation with the following command

    gem install [gemname] --ri

and then check to see if this worked by using ri to look up a class or module
in that gem; e.g.,

    ri ActiveRecord::Associations::ClassMethods
    
If you like using `ri.vim`, you may want to make to remove `--no-ri` if you
added that to your `.gemrc`. This will make sure that the `gem install` command
automatically generates ri documentation.


## Changing keymappings

You can change the keymappings for invoking ri.vim by appending something like
this to your `.vimrc`:

    nnoremap  ,ri :call ri#OpenSearchPrompt(0)<cr> " horizonal split
    nnoremap  ,RI :call ri#OpenSearchPrompt(1)<cr> " vertical split
    nnoremap  ,RK :call ri#LookupNameUnderCursor()<cr> " keyword lookup 

* * *

## Acknowledgements

Special thanks to Eric Hodel for developing and maintaining the whole ri and
rdoc infrastructure that ri.vim builds on. ri.vim adds just a little piece to
that very useful codebase.

And also to Tim Pope, who continues to lead the way in making Vim a very
productive and happy environment for crafting Ruby software.



