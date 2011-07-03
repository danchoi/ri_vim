require 'abbrev'
require 'optparse'

begin
  require 'readline'
rescue LoadError
end

begin
  require 'win32console'
rescue LoadError
end

require 'rdoc/ri'
require 'rdoc/ri/paths'
require 'rdoc/markup'
require 'rdoc/markup/formatter'
require 'rdoc/text'

##
# For RubyGems backwards compatibility

require 'rdoc/ri/formatter'

class RDoc::RI::Driver
  class Error < RDoc::RI::Error; end
  class NotFoundError < Error
    alias name message
    def message # :nodoc:
      "Nothing known about #{super}"
    end
  end

  ##
  # An RDoc::RI::Store for each entry in the RI path
  attr_accessor :stores

  def self.default_options
    options = {}
    options[:width] = 72
    options[:use_cache] = true
    options[:profile] = false

    # By default all standard paths are used.
    options[:use_system] = true
    options[:use_site] = true
    options[:use_home] = true
    options[:use_gems] = true
    options[:extra_doc_dirs] = []

    return options
  end

  ##
  # Dump +data_path+ using pp

  def self.dump data_path
    require 'pp'

    open data_path, 'rb' do |io|
      pp Marshal.load(io.read)
    end
  end

  ##
  # Parses +argv+ and returns a Hash of options

  def self.process_args argv
    options = default_options
    options[:names] = argv
    options[:width] ||= 72
    options
  end


  def self.run argv = ARGV
    options = process_args argv
    ri = new options
    ri.run
  end

  def initialize initial_options = {}
    @paging = false
    @classes = nil
    options = self.class.default_options.update(initial_options)
    @formatter_klass = options[:formatter]
    @names = options[:names]
    @list = options[:list]
    @doc_dirs = []
    @stores   = []
    RDoc::RI::Paths.each(options[:use_system], options[:use_site],
                                   options[:use_home], options[:use_gems],
                                   *options[:extra_doc_dirs]) do |path, type|
      @doc_dirs << path

      store = RDoc::RI::Store.new path, type
      store.load_cache
      @stores << store
    end
    # @docs_dirs is IMPORTANT
    #puts @doc_dirs
    @list_doc_dirs = false
    @interactive = false
  end

  ##
  # Adds paths for undocumented classes +also_in+ to +out+

  def add_also_in out, also_in
    return if also_in.empty?

    out << RDoc::Markup::Rule.new(1)
    out << RDoc::Markup::Paragraph.new("Also found in:")

    paths = RDoc::Markup::Verbatim.new
    also_in.each do |store|
      paths.parts.push store.friendly_path, "\n"
    end
    out << paths
  end

  ##
  # Adds a class header to +out+ for class +name+ which is described in
  # +classes+.

  def add_class out, name, classes
    heading = if classes.all? { |klass| klass.module? } then
                name
              else
                superclass = classes.map do |klass|
                  klass.superclass unless klass.module?
                end.compact.shift || 'Object'

                "#{name} < #{superclass}"
              end

    out << RDoc::Markup::Heading.new(1, heading)
    out << RDoc::Markup::BlankLine.new
  end

  ##
  # Adds "(from ...)" to +out+ for +store+

  def add_from out, store

    out << RDoc::Markup::Paragraph.new("(from #{store.friendly_path})")
  end

  ##
  # Adds +includes+ to +out+

  def add_includes out, includes
    return if includes.empty?

    out << RDoc::Markup::Rule.new(1)
    out << RDoc::Markup::Heading.new(1, "Includes:")

    includes.each do |modules, store|
      if modules.length == 1 then
        include = modules.first
        name = include.name
        path = store.friendly_path
        out << RDoc::Markup::Paragraph.new("#{name} (from #{path})")

        if include.comment then
          out << RDoc::Markup::BlankLine.new
          out << include.comment
        end
      else
        out << RDoc::Markup::Paragraph.new("(from #{store.friendly_path})")

        wout, with = modules.partition { |incl| incl.comment.empty? }

        out << RDoc::Markup::BlankLine.new unless with.empty?

        with.each do |incl|
          out << RDoc::Markup::Paragraph.new(incl.name)
          out << RDoc::Markup::BlankLine.new
          out << incl.comment
        end

        unless wout.empty? then
          verb = RDoc::Markup::Verbatim.new

          wout.each do |incl|
            verb.push incl.name, "\n"
          end

          out << verb
        end
      end
    end
  end

  ##
  # Adds a list of +methods+ to +out+ with a heading of +name+

  def add_method_list out, methods, name
    return unless methods

    out << RDoc::Markup::Heading.new(1, "#{name}:")
    out << RDoc::Markup::BlankLine.new

    out.push(*methods.map do |method|
      #Ths does not work:
      #RDoc::Markup::Verbatim.new method
      RDoc::Markup::Paragraph.new method
    end)

    out << RDoc::Markup::BlankLine.new
  end

  ##
  # Returns ancestor classes of +klass+

  def ancestors_of klass
    ancestors = []

    unexamined = [klass]
    seen = []

    loop do
      break if unexamined.empty?
      current = unexamined.shift
      seen << current

      stores = classes[current]

      break unless stores and not stores.empty?

      klasses = stores.map do |store|
        store.ancestors[current]
      end.flatten.uniq

      klasses = klasses - seen

      ancestors.push(*klasses)
      unexamined.push(*klasses)
    end

    ancestors.reverse
  end

  ##
  # For RubyGems backwards compatibility

  def class_cache # :nodoc:
  end

  ##
  # Hash mapping a known class or module to the stores it can be loaded from

  def classes
    return @classes if @classes

    @classes = {}

    @stores.each do |store|
      store.cache[:modules].each do |mod|
        # using default block causes searched-for modules to be added
        @classes[mod] ||= []
        @classes[mod] << store
      end
    end

    @classes
  end

  ##
  # Completes +name+ based on the caches.  For Readline

  def complete name
    klasses = classes.keys
    completions = []

    klass, selector, method = parse_name name

    # may need to include Foo when given Foo::
    klass_name = method ? name : klass

    if name !~ /#|\./ then
      completions = klasses.grep(/^#{klass_name}[^:]*$/)
      completions.concat klasses.grep(/^#{name}[^:]*$/) if name =~ /::$/

      completions << klass if classes.key? klass # to complete a method name
    elsif selector then
      completions << klass if classes.key? klass
    elsif classes.key? klass_name then
      completions << klass_name
    end

    if completions.include? klass and name =~ /#|\.|::/ then
      methods = list_methods_matching name

      if not methods.empty? then
        # remove Foo if given Foo:: and a method was found
        completions.delete klass
      elsif selector then
        # replace Foo with Foo:: as given
        completions.delete klass
        completions << "#{klass}#{selector}"
      end

      completions.push(*methods)
    end

    c = completions.sort.uniq
    puts c.inspect
    c

  end

  ##
  # Converts +document+ to text and writes it to the pager

  def display document
    page do |io|
      text = document.accept formatter(io)

      io.write text
    end
  end

  ##
  # Outputs formatted RI data for class +name+.  Groups undocumented classes

  def display_class name
    return if name =~ /#|\./

    klasses = []
    includes = []

    found = @stores.map do |store|
      begin
        klass = store.load_class name
        klasses  << klass
        includes << [klass.includes, store] if klass.includes
        [store, klass]
      rescue Errno::ENOENT
      end
    end.compact

    return if found.empty?

    also_in = []

    includes.reject! do |modules,| modules.empty? end

    out = RDoc::Markup::Document.new

    add_class out, name, klasses

    add_includes out, includes

    found.each do |store, klass|
      comment = klass.comment
      class_methods    = store.class_methods[klass.full_name]
      instance_methods = store.instance_methods[klass.full_name]
      attributes       = store.attributes[klass.full_name]

      if comment.empty? and !(instance_methods or class_methods) then
        also_in << store
        next
      end

      add_from out, store

      unless comment.empty? then
        out << RDoc::Markup::Rule.new(1)
        out << comment
      end

      if class_methods or instance_methods or not klass.constants.empty? then
        out << RDoc::Markup::Rule.new(1)
      end

      unless klass.constants.empty? then
        out << RDoc::Markup::Heading.new(1, "Constants:")
        out << RDoc::Markup::BlankLine.new
        list = RDoc::Markup::List.new :NOTE

        constants = klass.constants.sort_by { |constant| constant.name }

        list.push(*constants.map do |constant|
          parts = constant.comment.parts if constant.comment
          parts << RDoc::Markup::Paragraph.new('[not documented]') if
            parts.empty?

          RDoc::Markup::ListItem.new(constant.name, *parts)
        end)

        out << list
      end

      add_method_list out, class_methods,    'Class methods'
      add_method_list out, instance_methods, 'Instance methods'
      add_method_list out, attributes,       'Attributes'

      out << RDoc::Markup::BlankLine.new
    end

    add_also_in out, also_in

    display out
  end

  ##
  # Outputs formatted RI data for method +name+

  def display_method name
    found = load_methods_matching name

    raise NotFoundError, name if found.empty?

    filtered = filter_methods found, name

    out = RDoc::Markup::Document.new

    out << RDoc::Markup::Heading.new(1, name)
    out << RDoc::Markup::BlankLine.new

    filtered.each do |store, methods|
      methods.each do |method|

        out << RDoc::Markup::Paragraph.new("(from #{store.friendly_path})")

        unless name =~ /^#{Regexp.escape method.parent_name}/ then
          out << RDoc::Markup::Heading.new(3, "Implementation from #{method.parent_name}")
        end
        out << RDoc::Markup::Rule.new(1)

        if method.arglists then
          arglists = method.arglists.chomp.split "\n"
          arglists = arglists.map { |line| line + "\n" }
          out << RDoc::Markup::Verbatim.new(*arglists)
          out << RDoc::Markup::Rule.new(1)
        end

        out << RDoc::Markup::BlankLine.new
        out << method.comment
        out << RDoc::Markup::BlankLine.new
      end
    end

    display out
  end

  ##
  # Outputs formatted RI data for the class or method +name+.
  #
  # Returns true if +name+ was found, false if it was not an alternative could
  # be guessed, raises an error if +name+ couldn't be guessed.

  def display_name name
    return true if display_class name

if name =~ /::|#|\./
    puts name.inspect

    display_method name 
end
    true
  rescue NotFoundError
    # TODO use this!
    #
    matches = list_methods_matching name if name =~ /::|#|\./
    matches = classes.keys.grep(/^#{name}/) if matches.empty?

    raise if matches.empty?

    page do |io|
      io.puts "#{name} not found, maybe you meant:"
      io.puts
      io.puts matches.join("\n")
    end

    false
  end

  ##
  # Displays each name in +name+

  def display_names names
    names.each do |name|
      name = expand_name name

      display_name name
    end
  end
  ##
  # Expands abbreviated klass +klass+ into a fully-qualified class.  "Zl::Da"
  # will be expanded to Zlib::DataError.

  def expand_class klass
    klass.split('::').inject '' do |expanded, klass_part|
      expanded << '::' unless expanded.empty?
      short = expanded << klass_part

      subset = classes.keys.select do |klass_name|
        klass_name =~ /^#{expanded}[^:]*$/
      end

      abbrevs = Abbrev.abbrev subset

      expanded = abbrevs[short]

      raise NotFoundError, short unless expanded

      expanded.dup
    end
  end

  ##
  # Expands the class portion of +name+ into a fully-qualified class.  See
  # #expand_class.

  def expand_name name
    klass, selector, method = parse_name name

    return [selector, method].join if klass.empty?

    "#{expand_class klass}#{selector}#{method}"
  end

  ##
  # Filters the methods in +found+ trying to find a match for +name+.

  def filter_methods found, name
    regexp = name_regexp name

    filtered = found.find_all do |store, methods|
      methods.any? { |method| method.full_name =~ regexp }
    end

    return filtered unless filtered.empty?

    found
  end

  ##
  # Yields items matching +name+ including the store they were found in, the
  # class being searched for, the class they were found in (an ancestor) the
  # types of methods to look up (from #method_type), and the method name being
  # searched for

  def find_methods name
    klass, selector, method = parse_name name

    types = method_type selector

    klasses = nil
    ambiguous = klass.empty?

    if ambiguous then
      klasses = classes.keys
    else
      klasses = ancestors_of klass
      klasses.unshift klass
    end

    methods = []

    klasses.each do |ancestor|
      ancestors = classes[ancestor]

      next unless ancestors

      klass = ancestor if ambiguous

      ancestors.each do |store|
        methods << [store, klass, ancestor, types, method]
      end
    end

    methods = methods.sort_by do |_, k, a, _, m|
      [k, a, m].compact
    end

    methods.each do |item|
      yield(*item) # :yields: store, klass, ancestor, types, method
    end

    self
  end

  ##
  # Creates a new RDoc::Markup::Formatter.  If a formatter is given with -f,
  # use it.  If we're outputting to a pager, use bs, otherwise ansi.

  def formatter(io)
    RDoc::Markup::ToRdoc.new
    #RDoc::Markup::ToAnsi.new
  
  end

  ##
  # Runs ri interactively using Readline if it is available.

  def interactive
    puts "\nEnter the method name you want to look up."

    if defined? Readline then
      Readline.completion_proc = method :complete
      puts "You can use tab to autocomplete."
    end

    puts "Enter a blank line to exit.\n\n"

    loop do
      name = if defined? Readline then
               Readline.readline ">> "
             else
               print ">> "
               $stdin.gets
             end

      puts name
      return if name.nil? or name.empty?

      name = expand_name name.strip
      puts name
      x = list_methods_matching name
      puts x
      puts list_known_classes([name])

      begin
        display_name name
      rescue NotFoundError => e
        puts e.message
      end
    end

  rescue Interrupt
    puts $!
    exit
  end

  ##
  # Is +file+ in ENV['PATH']?

  def in_path? file
    return true if file =~ %r%\A/% and File.exist? file

    ENV['PATH'].split(File::PATH_SEPARATOR).any? do |path|
      File.exist? File.join(path, file)
    end
  end

  ##
  # Lists classes known to ri starting with +names+.  If +names+ is empty all
  # known classes are shown.

  def list_known_classes names = []
    names = []
    classes = []

    stores.each do |store|
      classes << store.modules
    end


    puts classes

    classes = classes.flatten.uniq.sort

    unless names.empty? then
      filter = Regexp.union names.map { |name| /^#{name}/ }

      classes = classes.grep filter
    end

    return classes
    page do |io|
      if paging? or io.tty? then
        if names.empty? then
          io.puts "Classes and Modules known to ri:"
        else
          io.puts "Classes and Modules starting with #{names.join ', '}:"
        end
        io.puts
      end

      io.puts classes.join("\n")
    end
  end

  ##
  # Returns an Array of methods matching +name+

  def list_methods_matching name
    found = []

    find_methods name do |store, klass, ancestor, types, method|
      if types == :instance or types == :both then
        methods = store.instance_methods[ancestor]

        if methods then
          matches = methods.grep(/^#{Regexp.escape method.to_s}/)

          matches = matches.map do |match|
            "#{klass}##{match}"
          end

          found.push(*matches)
        end
      end

      if types == :class or types == :both then
        methods = store.class_methods[ancestor]

        next unless methods
        matches = methods.grep(/^#{Regexp.escape method.to_s}/)

        matches = matches.map do |match|
          "#{klass}::#{match}"
        end

        found.push(*matches)
      end
    end

    found.uniq
  end

  ##
  # Loads RI data for method +name+ on +klass+ from +store+.  +type+ and
  # +cache+ indicate if it is a class or instance method.

  def load_method store, cache, klass, type, name
    methods = store.send(cache)[klass]

    return unless methods

    method = methods.find do |method_name|
      method_name == name
    end

    return unless method

    store.load_method klass, "#{type}#{method}"
  end

  ##
  # Returns an Array of RI data for methods matching +name+

  def load_methods_matching name
    found = []

    find_methods name do |store, klass, ancestor, types, method|
      methods = []

      methods << load_method(store, :class_methods, ancestor, '::',  method) if
        [:class, :both].include? types

      methods << load_method(store, :instance_methods, ancestor, '#',  method) if
        [:instance, :both].include? types

      found << [store, methods.compact]
    end

    found.reject do |path, methods| methods.empty? end
  end

  ##
  # Returns the type of method (:both, :instance, :class) for +selector+

  def method_type selector
    case selector
    when '.', nil then :both
    when '#'      then :instance
    else               :class
    end
  end

  ##
  # Returns a regular expression for +name+ that will match an
  # RDoc::AnyMethod's name.

  def name_regexp name
    klass, type, name = parse_name name

    case type
    when '#', '::' then
      /^#{klass}#{type}#{Regexp.escape name}$/
    else
      /^#{klass}(#|::)#{Regexp.escape name}$/
    end
  end


  def page
    yield $stdout
  end

  def paging?
    false
  end

  ##
  # Extracts the class, selector and method name parts from +name+ like
  # Foo::Bar#baz.
  #
  # NOTE: Given Foo::Bar, Bar is considered a class even though it may be a
  #       method

  def parse_name(name)
    parts = name.split(/(::|#|\.)/)

    if parts.length == 1 then
      if parts.first =~ /^[a-z]/ then
        type = '.'
        meth = parts.pop
      else
        type = nil
        meth = nil
      end
    elsif parts.length == 2 or parts.last =~ /::|#|\./ then
      type = parts.pop
      meth = nil
    elsif parts[-2] != '::' or parts.last !~ /^[A-Z]/ then
      meth = parts.pop
      type = parts.pop
    end

    klass = parts.join

    [klass, type, meth]
  end

  ##
  # Looks up and displays ri data according to the options given.

  def run
    #puts [@list_doc_dirs, @doc_dirs].inspect
    puts @names.inspect
      display_name @names.first
      display_method @names.first
      puts '-' * 80
       # list_known_classes @names
      return
    if @list_doc_dirs then
      puts @doc_dirs
    elsif @list then
      list_known_classes @names
    elsif @interactive or @names.empty? then
      interactive
    else
      display_names @names
    end
  rescue NotFoundError => e
    #raise
    abort e.message
  end

end


if __FILE__ == $0
  puts "TEST"
  puts RDoc::RI::Driver.run ARGV

end
