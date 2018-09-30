class Game
  attr_reader :input, :output, :scoresheet_output,
              :scoresheet_maker,
              :num_frames, :players,
              :observers

  def initialize(input: $stdin, output: $stdout, scoresheet_output: $stdout,
                 scoresheet_maker: DetailedScoresheet)
    @input  = input
    @output = output
    @scoresheet_output = scoresheet_output
    @scoresheet_maker  = scoresheet_maker

    @players    = initialize_players
    @num_frames = determine_num_frames

    @observers  = []
  end

  def play
    frame_num = 1
    while frame_num <= num_frames
      players.each_with_index {|player, i|
        output.print "\n\n#{player.name} now starting frame #{frame_num}"

        while !player.turn_complete?(frame_num)
          output.print "\n Roll? >"
          roll   = listen("0").to_i
          player = update_player(i, player, roll)
        end

        notify_observers(player)
        # scoresheet_maker.new(frames: player.frames, io: scoresheet_output).render
      }

      frame_num += 1
    end

    output.print "\n\nGame over, thanks for playing!"
    output.print "\nFinal Scores:"
    players.each {|player|
      output.print "\n  #{player.name} #{player.score}"
      }
    output.puts
  end

  def initialize_players
    [].tap {|players|
      get_player_names.each {|name|
        type = get_player_game_type(name).to_sym
        players << Player.new(name: name, config: Variant::CONFIGS.fetch(type))
      }
    }
  end

  def get_player_names
    output.print "\nWho's playing? (Larry, Curly, Moe) >"
    listen("Larry, Curly, Moe").gsub(" ", "").split(",")
  end

  def get_player_game_type(name)
    output.print "\nWhich game would #{name} like to play? (TENPIN) >"
    listen("TENPIN")
  end

  def listen(default)
    ((i = input.gets.chomp).empty? ? default : i)
  end

  def determine_num_frames
    players.first.num_frames_in_game
  end

  def update_player(i, old_player, roll)
    new_player = old_player.new_roll(roll)
    players[i] = new_player
    new_player
  end

  # observers
  def add_observer(onlooker)
    observers << onlooker
  end

  def remove_observer(onlooker)
    observers.delete(onlooker)
  end

  def notify_observers(player)
    observers.each {|onlooker| onlooker.update(player: player, io: scoresheet_output)}
  end
end
