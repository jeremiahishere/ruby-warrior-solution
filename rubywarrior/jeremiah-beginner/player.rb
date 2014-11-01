class Player
  def initialize
    @map = Map.new
    @health = 20

    @status = :explore
    @facing = :forward
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
    if @health >= 20 || (@damaged_last_turn && @health > 9 && @map.enemy_in_range?)
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

  def melee_attack(warrior)
    if @map.enemy_ahead?
      warrior.attack!
    elsif @map.enemy_behind?
      warrior.pivot!
    else
      change_status(:explore, warrior)
    end
  end
  
  def ranged_attack(warrior)
    if @map.enemy_adjacent?
      change_status(:melee_attack, warrior)
    elsif @map.enemy_in_range_behind?
      warrior.shoot!(:backward)
    elsif @map.enemy_in_range_ahead?
      warrior.shoot!(:forward)
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
    if (@health < 7 && !@damaged_last_turn) || (@health < 20 && !@map.enemy_in_range?)
      change_status(:run_and_rest, warrior)
    elsif @map.enemy_adjacent?
      change_status(:melee_attack, warrior)
    elsif warrior.respond_to?(:shoot!) && @map.enemy_in_range?
      change_status(:ranged_attack, warrior)
    elsif @map.captive_adjacent?
      change_status(:rescue, warrior)
    else
      if @map.wall_behind?
        if @map.wall_immediately_ahead?
          warrior.pivot!
        else
          warrior.walk!
          @map.current_position += 1
        end
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
    if warrior.respond_to? :look
      warrior.look(:forward).each_with_index do |space, index|
        @positions[@current_position + index + 1] = map_val(space)
      end
      warrior.look(:backward).each_with_index do |space, index|
        @positions[@current_position - index - 1] = map_val(space)
      end
    else
      @positions[@current_position + 1] = map_val(warrior.feel(:forward))
      @positions[@current_position - 1] = map_val(warrior.feel(:backward))
    end
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

  def enemy_adjacent?
    enemy_ahead? || enemy_behind?
  end

  def enemy_ahead?
    @positions[@current_position + 1] == :enemy
  end

  def enemy_behind?
    @positions[@current_position - 1] == :enemy
  end

  def enemy_in_range?
    enemy_in_range_ahead? || enemy_in_range_behind?
  end

  def enemy_in_range_ahead?
    pos = @current_position
    3.times do
      return true if @positions[pos] == :enemy
      return false if @positions[pos] != :nothing
      pos += 1
    end
    return false
  end

  def enemy_in_range_behind?
    pos = @current_position
    3.times do
      return true if @positions[pos] == :enemy
      return false if @positions[pos] != :nothing
      pos -= 1
    end
    return false
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

  def wall_immediately_ahead?
    @positions[@current_position +1] == :wall
  end
end
