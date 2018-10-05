require 'forwardable'
class Frame
  extend Forwardable
  def_delegators :status,
    :normal_rolls_complete?, :bonus_rolls_complete?

  attr_reader :normal_rolls, :bonus_rolls, :turn_rule
  attr_accessor :status

  def initialize(normal_rolls:, bonus_rolls:, status: nil,
                 turn_rule: GeneralTurnRule.new, config: nil)
    @normal_rolls = normal_rolls
    @bonus_rolls  = bonus_rolls
    @status       = status
    @turn_rule    = turn_rule
    @config       = config
  end

  def rolls
    normal_rolls + bonus_rolls
  end

  def turn_complete?
    turn_rule.turn_complete?(self)
  end

  def accepts_another_roll?
    !(normal_rolls_complete? && bonus_rolls_complete?)
  end

  def score
    status.score(self)
  end

  def running_score(previous)
    status.running_score(previous, self)
  end

  def add_roll(roll)
    status.add_roll(roll, self)
  end
end
