# wrapper for a File instance - formats the written output to be nice readable
# LilyPond source

# delegates all methods of File, reimplements just File#puts and File#print

require 'delegate'

class LilyPondOutputFormatter < DelegateClass(File)
  
  def initialize(io)
    @io = io
    @indentation_level = 0
    @space = "  "
    @last_output_method = nil
    super(@io)
  end
  
  def puts(s="\n")
    if @last_output_method == :print then
      # not at the beginning of a line - without indentation
      if s =~ /\{\s*$/ || s =~ /<</ then
        r = @io.puts s
        indent
      elsif s=~ /\}\s*$/ || s =~ />>/ then
        unindent
        r = @io.puts s
      else
        r = @io.puts s
      end

    else
      if s =~ /\{\s*$/ || s =~ /<</ then
        r = @io.puts indentation_space+s
        indent
      elsif s=~ /\}\s*$/ || s =~ />>/ then
        unindent
        r = @io.puts indentation_space+s
      else
        r = @io.puts indentation_space+s
      end
    end
    
    @last_output_method = :puts
    return r
  end
  
  def print(s)
    if @last_output_method == :puts then # beginning of a new line
      if s =~ /\{\s*$/ || s =~ /<</ then
        r = @io.print indentation_space+s
        indent
      elsif s=~ /\}\s*$/ || s =~ />>/ then
        unindent
        r = @io.print indentation_space+s
      else
        r = @io.print indentation_space+s
      end
    else
      r = @io.print s
    end
    
    @last_output_method = :print
    return r
  end
  
  def ensure_new_line
    if @last_output_method == :print then
      @last_output_method = :puts
      @io.puts
    end
  end
  
  def indent
    @indentation_level += 1
  end
  
  def unindent
    @indentation_level -= 1 if @indentation_level - 1 >= 0
  end
  
  def indentation_space
    @space * @indentation_level
  end
end