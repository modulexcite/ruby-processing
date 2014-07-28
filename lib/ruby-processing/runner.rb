require 'ostruct'
require 'fileutils'
require 'rbconfig'
require_relative '../ruby-processing/config'
require_relative '../ruby-processing/version'


module Processing

  # Utility class to handle the different commands that the 'rp5' command
  # offers. Able to run, watch, live, create, app, and unpack
  class Runner
    HELP_MESSAGE = <<-EOS
    Version: #{RubyProcessing::VERSION}

    Ruby-Processing is a little shim between Processing and JRuby that helps
    you create sketches of code art.

    Usage:
    rp5 [choice] path/to/sketch

    choice:-
    run:              run sketch once
    watch:            watch for changes on the file and relaunch it on the fly
    live:                  launch sketch and give an interactive IRB shell
    create [width height]: create a new sketch.
    app:              create an application version of the sketch
    setup:            check setup, install jruby-complete, unpack samples

    Common options:
    --nojruby:  use jruby-complete in place of an installed version of jruby
    (Set [JRUBY: 'false'] in .rp5rc to make using jruby-complete default)

    Examples:
    rp5 setup unpack_samples
    rp5 run samples/contributed/jwishy.rb
    rp5 create some_new_sketch 640 480
    rp5 create some_new_sketch --p3d 640 480
    rp5 watch some_new_sketch.rb

    Everything Else:
    http://wiki.github.com/jashkenas/ruby-processing

    EOS

    # Start running a ruby-processing sketch from the passed-in arguments
    def self.execute
      runner = self.new
      runner.parse_options(ARGV)
      runner.execute!
    end

    # Dispatch central.
    def execute!
      case @options.action
      when 'run'    then run(@options.path, @options.args)
      when 'watch'  then watch(@options.path, @options.args)
      when 'live'   then live(@options.path, @options.args)
      when 'create' then create(@options.path, @options.args, @options.p3d)
      when 'app'    then app(@options.path)
      when 'setup'  then setup(@options.path)
      when /-v/     then show_version
      when /-h/     then show_help
      else
        show_help
      end
    end

    # Parse the command-line options. Keep it simple.
    def parse_options(args)
      @options = OpenStruct.new
      @options.p3d   = !args.delete('--p3d').nil?
      @options.jruby  = !args.delete('--jruby').nil?
      @options.nojruby  = !args.delete('--nojruby').nil?
      @options.action = args[0]     || nil
      @options.path   = args[1]     || File.basename(Dir.pwd + '.rb')
      @options.args   = args[2..-1] || []
    end

    # Create a fresh Ruby-Processing sketch, with the necessary
    # boilerplate filled out.
    def create(sketch, args, p3d)
      require_relative '../ruby-processing/exporters/creator'
      Processing::Creator.new.create!(sketch, args, p3d)
    end

    # Just simply run a ruby-processing sketch.
    def run(sketch, args)
    ensure_exists(sketch)
      spin_up('run.rb', sketch, args)
    end

    # Run a sketch, keeping an eye on it's file, and reloading
    # whenever it changes.
    def watch(sketch, args)
    ensure_exists(sketch)
      spin_up('watch.rb', sketch, args)
    end

    # Run a sketch, opening its guts to IRB, letting you play with it.
    def live(sketch, args)
    ensure_exists(sketch)
      spin_up('live.rb', sketch, args)
    end

    # Generate a cross-platform application of a given Ruby-Processing sketch.
    def app(sketch)
      require_relative '../ruby-processing/exporters/application_exporter'
      Processing::ApplicationExporter.new.export!(sketch)
    end

    def setup(choice)
      usage = 'Usage: rp5 setup [check | install | unpack_samples]'
      installed = File.exist?("#{RP5_ROOT}/lib/ruby/jruby-complete.jar")
      proc_root = File.exist?("#{ENV['HOME']}/.rp5rc")
      case choice
      when /check/
        check(proc_root, installed)
      when /install/
        system "cd #{RP5_ROOT}/vendors && rake"
        if !proc_root
          set_processing_root
          warn 'PROCESSING_ROOT set optimistically, run check to confirm'
        end
      when /unpack_samples/
        require 'fileutils'
        FileUtils.cp_r("#{RP5_ROOT}/samples", "#{Dir.pwd}/rp_samples")
      else
        puts usage
      end
    end

    def check(proc_root, installed)
      show_version
      root = '  PROCESSING_ROOT = Not Set!!!' unless proc_root
      root ||= "  PROCESSING_ROOT = #{Processing::CONFIG['PROCESSING_ROOT']}"
      puts root
      puts "  JRUBY = #{Processing::CONFIG['JRUBY']}"
      puts "  jruby-complete installed = #{installed}"
    end


    # Display the current version of Ruby-Processing.
    def show_version
      puts "Ruby-Processing version #{RubyProcessing::VERSION}"
    end

    # Show the standard help/usage message.
    def show_help
      puts HELP_MESSAGE
    end


    private

    # Trade in this Ruby instance for a JRuby instance, loading in a
    # starter script and passing it some arguments.
    # Unless --nojruby is passed, use the installed version of jruby, instead of
    # our vendored jarred one (vendored version is required for some sketches eg shaders).
    # For people with system jruby they can use ~.rp5rc config to use option without flag
    def spin_up(starter_script, sketch, args)
      runner = "#{RP5_ROOT}/lib/ruby-processing/runners/#{starter_script}"
      warn('The --jruby flag is no longer required') if @options.jruby
      @options.nojruby = true if Processing::CONFIG['JRUBY'] == 'false'
      java_args = discover_java_args(sketch)
      command = @options.nojruby ?
        ['java', java_args, '-cp', jruby_complete, 'org.jruby.Main', runner, sketch, args].flatten :
        ['jruby', java_args, runner, sketch, args].flatten
      exec(*command)
      # exec replaces the Ruby process with the JRuby one.
    end

    # If you need to pass in arguments to Java, such as the ones on this page:
    # http://docs.oracle.com/javase/1.5.0/docs/tooldocs/windows/java.html
    # then type them into a java_args.txt in your data directory next to your sketch.
    def discover_java_args(sketch)
      arg_file = "#{File.dirname(sketch)}/data/java_args.txt"
      args = []
      args += dock_icon
      if File.exist?(arg_file)
        args += File.read(arg_file).split(/\s+/)
      elsif Processing::CONFIG['java_args']
        args += Processing::CONFIG['java_args'].split(/\s+/)
      end
      args.map! { |arg| "-J#{arg}" } unless @options.nojruby
      args
    end

    def ensure_exists(sketch)
      puts "Couldn't find: #{sketch}" and exit unless File.exist?(sketch)
    end

    def jruby_complete
      rcomplete = File.join(RP5_ROOT, 'lib/ruby/jruby-complete.jar')
      if File.exist?(rcomplete)
        return rcomplete
      else
        warn "#{rcomplete} does not exist\nTry running `rp5 setup install`"
        exit
      end
    end

    def os
      @os ||=
        host_os = RbConfig::CONFIG['host_os']
        case host_os
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
          :windows
        when /darwin|mac os/
          :macosx
        when /linux/
          :linux
        when /solaris|bsd/
          :unix
        else
          raise "unknown os: #{host_os.inspect}"
        end
    end


    # Optimistically set processing root
    def set_processing_root
      require 'psych'
      os
      data = {}
      path = File.expand_path("#{ENV['HOME']}/.rp5rc")
      if @os == :macosx
        data['PROCESSING_ROOT'] = %q(/Applications/Processing.app/Contents/Java')
      else
        root = "#{ENV['HOME']}/processing-2.2.1"
        data['PROCESSING_ROOT'] = root
      end
      data['JRUBY'] = %q(true)
      open(path, 'w:UTF-8') {|f| f.write(data.to_yaml) }
    end

    # On the Mac, we can display a fat, shiny ruby in the Dock.
    def dock_icon
      os
      icon = []
      if @os == :mac
        icon << '-Xdock:name=Ruby-Processing'
        icon << "-Xdock:icon=#{RP5_ROOT}/lib/templates/application/Contents/Resources/sketch.icns"
      end
      icon
    end
  end # class Runner
end # module Processing

