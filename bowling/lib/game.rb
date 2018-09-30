require 'observer'

module ScoresheetRenderingObserver
  def update(player:, io:)
    new(frames: player.frames, io: io).render
  end
end

# Design Challenge:
#
# Now Cheater exists and can Decorate a Player.  Fine.
# However, the way Game is structured here, either everybody cheats
# (i.e., you inject player_maker: Cheater) or no one does
# (you inject player_maker: Player, or take the default).
#
# This seems to defeat the whole point of cheating.
#
# What would it take to allow some players to secretly cheat,
# unbeknownst to the others?

class Game
  include Observable

  attr_reader :input, :output, :scoresheet_output,
              :scoresheet_maker, :player_maker,
              :num_frames, :players,
              :observers

  def initialize(input: $stdin, output: $stdout, scoresheet_output: $stdout,
                 player_maker: Player)
    @input  = input
    @output = output
    @scoresheet_output = scoresheet_output
    @player_maker      = player_maker

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

        changed
        notify_observers(player: player, io: scoresheet_output)
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
        players << player_maker.for(name: name, config: Variant::CONFIGS.fetch(type))
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
end
