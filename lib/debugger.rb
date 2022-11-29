puts "Debugger is loaded"

class LineBreakpoint
  def initialize(file, line)
    @file = file
    @line = line
    @tp =
      TracePoint.new(:line) do |tp|
        # we need to expand paths to make sure they'll match
        if File.expand_path(tp.path) == File.expand_path(@file) &&
             tp.lineno == @line
          puts "#{name} is triggered"
        end
      end
  end

  def name
    "Breakpoint at #{@file}:#{@line}"
  end

  def enable
    @tp.enable
    puts "Breakpoint at #{@file}:#{@line} is activated"
  end
end

LineBreakpoint.new(ENV["DEBUGGEE_FILE"], ENV["DEBUGGEE_LINE"].to_i).enable
