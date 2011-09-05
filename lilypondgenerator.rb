class LilyPondGenerator
  
  def generate(staves, output=STDOUT)
    @output = output
    
    @output.puts "\\version \"2.14.2\""
    @output.puts
    
    @stave_name = 'Stave'
    
    staves.each do |s|
      @stave_name += "E"
      create_pitches s
      if s.config['notation'] == 'true' && s.config['tablature'] == 'true' then
        create_notation_and_tablature s
      else
        if s.config['notation'] == 'true' then
          create_notation s
        elsif s.config['tablature'] == 'true' then
          create_tablature s
        else
          STDERR.puts "Warning: no notation or tablature Staff! No output!"
        end
      end
    end
  end
  
  def create_pitches(stave)
    @output.puts "pitches#{@stave_name} = {"
    
    stave.music.each {|m|
      if m == :bar then
        puts "|"
      elsif m.is_a?(Note) then
        pitch = m.pitch(stave.tuning)
        puts pitch[0]
      end
    }
    
    @output.puts "}"
  end
  
  def create_notation_and_tablature(stave)
    @output.puts "\\score {"
    @output.puts "<<"
    create_notation(stave)
    create_tablature(stave)
    @output.puts ">>"
    @output.puts "}"
  end
  
  def create_notation(stave)
    @output.puts "\\new Staff \\relative c' {"
    @output.puts "\\pitches#{@stave_name}"
    @output.puts "}"
  end
  
  def create_tablature(stave)
    @output.puts "\\new TabStaff \\relative c' {"
    @output.puts "\\pitches#{@stave_name}"      
    @output.puts "}"
  end
  
end