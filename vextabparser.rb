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
    when "#"
      # comment - my extension to the VexTab language
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
    "time" => nil,
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
  
  # parse line beginning with keyword "notes"
  
  def parse_notes_line(tokens)
    unless current_stave
      raise "Error: cannot add notes, no stave has been defined yet - at line #{@line_number}."
    end
    
    # remove initial keyword
    tokens.shift
    
    tokens.each do |notes|
      if notes == "|" then
        current_stave.music.push :bar
        next
      end
      
      parse_notes_expression(notes)
    end
  end
  
  # parse one of the space-separated expressions
  
  def parse_notes_expression(notes)
    parsed_expression_backup = notes.dup
    
    awaiting = :frets
    chord = false
    
    # find first string number:
    string = next_string_number notes
    
    while ! notes.empty? do
      token = next_token(notes)
      unless token
        raise "Parse error: unable to parse expression '#{parsed_expression_backup}' at line #{@line_number}. Unparsable rest is '#{notes}'"
      end
      
      case token
      when /\d+/
        if awaiting == :frets then
          new_note = Note.new(token.to_i, string)
          if chord then
            current_stave.music.last.add_note new_note
          else
            current_stave.music.push new_note
          end
        else
          awaiting = :frets
        end
      when "/"
        awaiting = :string
      when "-"
        if chord then
          raise "Parse error: unexpected '-' in chord at line #{@line_number}."
        end
      when "b"
        if awaiting != :frets then
          raise "Error: unexpected 'b' at line #{@line_number} in expression '#{parsed_expression_backup}'"
        end
        
        unless current_stave.music.last.is_a? Bend
          # create new Bend first
          m = current_stave.music.pop
          b = Bend.new
          b.add_note m
          current_stave.music.push b
        end
        
        # read following token - must be a fret number
        n = next_token(notes)
        unless n =~ /^\d+$/
          raise "Parse error: fret number expected after 'b' at line #{@line_number} in expression '#{parsed_expression_backup}'."
        end
        
        current_stave.music.last.add_note Note.new(n.to_i, string)
        
      when "v"
        current_stave.music.last.vibrato = :vibrato
      when "V"
        current_stave.music.last.vibrato = :harsh_vibrato
      when "("
        chord = true
        current_stave.music.push Chord.new
        string = next_string_number notes
      when ")"
        chord = false
      when "."
        unless chord
          raise "Unexpected '.' out of chord at line #{@line_number}"
        end
        awaiting = :frets
        string = next_string_number notes
      else
        raise "Parse Error: unknown token '#{token}' in expression '#{parsed_expression_backup}' at line #{@line_number}."
      end
    end
  end
  
  # cuts first valid token from the beginning of the expression and returns it
  
  def next_token(expression)
    expression.slice!(/^\d+|[\)\(-tbhpsvV\.\/\|]/)
  end
  
  # finds first string number in the expression and returns it as number
  
  def next_string_number(expression)
    begin
      s = expression.match(/\/(?<n>\d+)/)[:n].to_i
    rescue NoMethodError
      raise "Parse Error: No string number found at line #{@line_number} in expression '#{notes}'"
    end
    
    return s
  end
  
  def current_stave
    @staves.last
  end
end

class Tuning
  NOTES = [:c, :cis, :d, :dis, :e, :f, :fis, :g, :gis, :a, :ais, :b]
  OCTAVE_STEPS = NOTES.size
  
  def initialize(*notes_and_octaves)
    @strings = []
    while ! notes_and_octaves.empty? do
      note = notes_and_octaves.shift
      octave = notes_and_octaves.shift
      @strings.push [note, octave]
    end
  end
  
  def pitch(string, fret)
    p = @strings[string-1]
    i = (NOTES.index(p[0]) + fret) % NOTES.size
    octave = (NOTES.index(p[0]) + fret) / NOTES.size
    return [NOTES[i], p[1]+octave]
  end
  
  def Tuning.numeric_pitch(pitch)
    Tuning::NOTES.index(pitch[0]) + pitch[1]*NOTES.size
  end
end

class Stave
  
  TUNINGS = {
    "standard" => Tuning.new(:e, 5, :b, 4, :g, 4, :d, 4, :a, 3, :e, 3)
  }
  
  def initialize
    @config = VexTabParser::STAVE_CONFIG_DEFAULTS.dup
    @music = []
  end
  
  attr_reader :config
  attr_reader :music
  
  # returns an instance of Tuning
  
  def tuning
    TUNINGS[@config['tuning']]
  end
end

# Note as defined in VexTab: a pair of fret and string number

class Note
  def initialize(fret, string)
    @fret = fret
    @string = string
    @vibrato = false
  end
    
  attr_reader :fret
  attr_reader :string
  attr_accessor :vibrato
  
  def pitch(tuning)
    tuning.pitch(@string, @fret)
  end
  
  def octave(tuning)
    pitch(tuning)[1]
  end
  
  # numeric "absolute" value of a pitch
  
  def numeric_pitch(tuning)
    a = pitch tuning
    return Tuning.numeric_pitch a
  end
  
  def difference(note, tuning)
    return numeric_pitch(tuning) - note.numeric_pitch(tuning)
  end
end

class NotesGroup
  def initialize
    @notes = []
  end
  
  attr_reader :notes
  
  def add_note(n)
    @notes << n
  end
  
  def octave(tuning)
    @notes.first.octave(tuning)
  end
  
  def pitch(tuning)
    @notes.first.pitch(tuning)
  end
  
  def numeric_pitch(tuning)
    @notes.first.numeric_pitch(tuning)
  end
end

class Bend < NotesGroup
  def initialize
    @notes = []
  end
  
  attr_reader :notes
  
  def add_note(n)
    unless n.is_a? Note
      raise "No #{n.class} may be inserted to a Bend. Only Notes are allowed."
    end
    super(n)
  end
  
  def bend_and_release?
    @notes.size == 3 && @notes.first.fret == @notes.last.fret
  end
  
  def vibrato=(v)
    @notes.last.vibrato = v
  end
end

class Chord < NotesGroup
end
