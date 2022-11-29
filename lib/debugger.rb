require "reline"
puts "Debugger is loaded"

module Debugger
  class Session
    def suspend(binding)
      while input = Reline.readline("(debug) ")
        case input
        when "c", "continue"
          break
        when "exit"
          exit
        else
          puts "=> " + eval_input(binding, input).inspect
        end
      end
    end

    def eval_input(binding, input)
      binding.eval(input)
    rescue Exception => e
      puts "Evaluation error: #{e.inspect}"
    end
  end

  SESSION = Session.new
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
            SESSION.suspend(tp.binding)
          end
        end
    end

    def name
      "Breakpoint at #{@file}:#{@line}"
    end

    def enable
      puts "#{name} is activated"
      @tp.enable
    end
  end
end

Debugger::LineBreakpoint.new(
  ENV["DEBUGGEE_FILE"],
  ENV["DEBUGGEE_LINE"].to_i
).enable
