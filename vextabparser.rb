# Parser of the VexTab tablature language

class VexTabParser
  
  private
  
  def reset
    @line_number = 0
    @staves = []
  end
  
  public
  
  # lines : Array of Strings, each is one line of tablature file
  
  def parse(lines)
    reset
    
    lines.each_with_index do |l, i|
      @line_number = i+1
      parse_line l
    end
    
    return @staves
  end
  
  def parse_line(l)
    l.strip!
    if l.empty? then
      return
    end
    
    tokens = l.split(/\s+/)
    case tokens.first
    when "tabstave"
      parse_stave_line(tokens)
    when "notes"
      parse_notes_line(tokens)
    else
      raise "Parse Error: invalid keyword '#{tokens.first}' at line #{@line_number}."
    end
  end
  
  # allowed stave arguments and their allowed values
  STAVE_CONFIG_KEYWORDS = {
    "notation" => ["true", "false"],
    "tablature" => ["true", "false"],
    "clef" => ["treble", "alto", "tenor", "bass"],
    "key" => %w(C Am F Dm Bb Gm Eb Cm Ab Fm Db Bbm Gb Ebm Cb Abm G Em D Bm A F#m E C#m B G#m F# D#m C# A#m),
    "time" => ["C", "C|", "#/#"],
    "tuning" => ["standard"]
  }
  
  # default values of stave arguments
  STAVE_CONFIG_DEFAULTS = {
    "notation" => "false",
    "tablature" => "true",
    "clef" => "treble",
    "key" => "C",
    "time" => "C",
    "tuning" => "standard"
  }
  
  def parse_stave_line(tokens)
    s = Stave.new
    @staves.push s
    
    # remove initial keyword
    tokens.shift
    
    # parse arguments
    tokens.each do |arg|
      argname, argvalue = arg.split "="
      unless argname && argvalue
        raise "Parse Error: Missing name or value of stave argument '#{arg}' at line #{@line_number}"
      end
      
      unless STAVE_CONFIG_KEYWORDS.has_key? argname
        raise "Error: unknown stave argument '#{argname}' at line #{@line_number}."
      end
      unless STAVE_CONFIG_KEYWORDS[argname].include? argvalue
        raise "Error: unknown value '#{argvalue}' of stave argument '#{argname}' at line #{@line_number}"
      end
      
      current_stave.config[argname] = argvalue
    end
  end
  
  def parse_notes_line(tokens)
    unless current_stave
      raise "Error: cannot add notes, no stave has been defined yet - at line #{@line_number}."
    end
    
    # remove initial keyword
    tokens.shift
    
    tokens.each do |notes|
      if notes == "|" then
        current_stave.music.push :bar
        return
      end
      
      frets, string = notes.split "/"
      unless frets && string
        raise "Parse Error: invalid notes expression '#{notes}' at line #{@line_number}: frets or string missing"
      end
      unless string =~ /^[0-9]+$/
        raise "Parse Error: invalid string '#{string}' at line #{@line_number}."
      end
      
      string = string.to_i
      
      frets.split("-").each do |f|
        unless f =~ /^[0-9]+$/
          raise "Parse Error: invalid fret '#{f}' at line #{@line_number}."
        end
        
        current_stave.music.push Note.new(f.to_i, string)
      end
    end
  end
  
  def current_stave
    @staves.last
  end
end

class Tuning
  NOTES = [:c, :cis, :d, :dis, :e, :f, :fis, :g, :gis, :a, :ais, :b]
  
  def initialize(*notes_and_octaves)
    @strings = []
    while ! notes_and_octaves.empty? do
      note = notes_and_octaves.shift
      octave = notes_and_octaves.shift
      @strings.push [note, octave]
    end
  end
  
  def pitch(string, fret)
    p = @strings[string]
    i = (NOTES.index(p[0]) + fret) % NOTES.size
    octave = (NOTES.index(p[0]) + fret) / NOTES.size
    return [NOTES[i], p[1]+octave]
  end
end

class Stave
  
  TUNINGS = {
    "standard" => Tuning.new(:e, 2, :b, 2, :g, 2, :d, 1, :a, 1, :e, 1)
  }
  
  def initialize
    @config = VexTabParser::STAVE_CONFIG_DEFAULTS.dup
    @music = []
  end
  
  attr_reader :config
  attr_reader :music
end

# Note as defined in VexTab: a pair of fret and string number

class Note
  def initialize(fret, string)
    @fret = fret
    @string = string
  end
  
  attr_reader :fret
  attr_reader :string
  
  def pitch(tuning)
    tuning.pitch(@string, @fret)
  end
end