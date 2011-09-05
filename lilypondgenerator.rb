class LilyPondGenerator
  
  def generate(staves, output=STDOUT)
    @output = output
    
    @output.puts "\\version \"2.14.2\""
    @output.puts
    
    @stave_name = 'Stave'
    
    staves.each do |s|
      @stave_name += "E"
      create_pitches s
      if s.config['notation'] == 'true' then
        create_notation s
      end
      if s.config['tablature'] == 'true' then
        create_tablature s
      end
    end
  end
  
  def create_pitches(stave)
    @output.puts "pitches#{@stave_name} = {"
    s.music.each do |m|
      if m == :bar then
        puts "|"
      else if m.is_a? Note then
        pitch = m.pitch(s.tuning)
        puts 
      end
    end
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