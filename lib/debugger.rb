require "reline"
puts "Debugger is loaded"

module Debugger
  class Session
    def suspend(binding)
      display_code(binding)
      while input = Reline.readline("(debug) ")
        case input
        when "s", "step"
          step_in
          break
        when "n", "next"
          step_over
          break
        when "c", "continue"
          break
        when "exit"
          exit
        else
          puts "=> " + eval_input(binding, input).inspect
        end
      end
    end

    def step_in
      TracePoint.trace(:line) do |tp|
        tp.disable
        suspend(tp.binding)
      end
    end

    def step_over
      current_depth = caller.length - 2

      TracePoint.trace(:line) do |tp|
        depth = caller.length

        next unless depth <= current_depth

        tp.disable
        suspend(tp.binding)
      end
    end

    def display_code(binding)
      file, current_line = binding.source_location

      if File.exist?(file)
        lines = File.readlines(file)
        end_line = [current_line + 5, lines.count].min - 1
        start_line = [end_line - 10, 0].max
        puts "[#{start_line + 1}, #{end_line + 1}] in #{file}"
        lines[start_line..end_line].each_with_index do |line, index|
          lineno = start_line + index + 1

          if lineno == current_line
            puts " => #{lineno}| #{line}"
          else
            puts "    #{lineno}| #{line}"
          end
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

class Binding
  def debug
    Debugger::SESSION.suspend(self)
  end
end

Debugger::LineBreakpoint.new(
  ENV["DEBUGGEE_FILE"],
  ENV["DEBUGGEE_LINE"].to_i
).enable
