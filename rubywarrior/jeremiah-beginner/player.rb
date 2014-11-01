class Player
  def initialize
    @map = Map.new
    @health = 20

    @status = :explore
  end

  def play_turn(warrior)
    update_health(warrior)
    @map.update(warrior)
    puts "Current status: #{@status}"

    send(@status, warrior)
  end

  def update_health(warrior)
    @damaged_last_turn = warrior.health < @health
    @health = warrior.health
    puts "Current health: #{@health}"
    puts "Damaged last turn" if @damaged_last_turn
  end

  def change_status(status, warrior)
    @status = status
    send(status, warrior)
  end

  def run_and_rest(warrior)
    if @health >= 20 || (@damaged_last_turn && @health > 9)
      change_status(:explore, warrior)
    else
      if @map.enemy_ahead? || @damaged_last_turn
        warrior.walk!(:backward)
        @map.current_position -= 1
      else
        warrior.rest!
      end
    end
  end

  def attack(warrior)
    if @map.enemy_ahead?
      warrior.attack!
    else
      change_status(:explore, warrior)
    end
  end

  def rescue(warrior)
    if @map.captive_ahead?
      warrior.rescue!
    elsif @map.captive_behind?
      warrior.rescue!(:backward)
    else
      change_status(:explore, warrior)
    end
  end

  def explore(warrior)
    if @health < 10 && !@damaged_last_turn
      change_status(:run_and_rest, warrior)
    elsif @map.enemy_ahead?
      change_status(:attack, warrior)
    elsif @map.captive_adjacent?
      change_status(:rescue, warrior)
    else
      if @map.wall_behind?
        warrior.walk!
        @map.current_position += 1
      else
        warrior.walk!(:backward)
        @map.current_position -= 1
      end
    end
  end
end

class Map
  attr_accessor :current_position
  def initialize
    @positions = {}
    @current_position = 0
  end

  def update(warrior)
    @positions[@current_position + 1] = map_val(warrior.feel(:forward))
    @positions[@current_position - 1] = map_val(warrior.feel(:backward))
    puts @positions
  end

  def map_val(space)
    if space.enemy?
      :enemy
    elsif space.captive?
      :captive
    elsif space.wall?
      :wall
    else
      :nothing
    end
  end

  def enemy_ahead?
    @positions[@current_position + 1] == :enemy
  end

  def captive_adjacent?
    captive_ahead? || captive_behind?
  end

  def captive_ahead?
    @positions[@current_position + 1] == :captive
  end
  
  def captive_behind?
    @positions[@current_position - 1] == :captive
  end

  # have found the back wall
  # not necessarilly immediately behind you
  def wall_behind?
    pos = @current_position
    while(@positions.has_key?(pos))
      return true if @positions[pos] == :wall
      pos -= 1
    end
    return false
  end
end
