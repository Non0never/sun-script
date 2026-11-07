# SCRIPT DE RAYO DE SOL - CREATED BY POLECTRON
module SunSettings
  BGPATH = "Graphics/Fogs/Sun.png"
  SUN_OPACITY = 150

  class << self
    attr_accessor :sun_sprite

    def active_spritesets
      @active_spritesets ||= []
    end

    def register_spriteset(spriteset)
      active_spritesets << spriteset unless active_spritesets.include?(spriteset)
    end

    def unregister_spriteset(spriteset)
      active_spritesets.delete(spriteset)
    end

    def primary_spriteset
      active_spritesets.first
    end

    def current_time
      if defined?(UnrealTimeSystem) && UnrealTimeSystem.respond_to?(:current_time)
        return UnrealTimeSystem.current_time
      end
      pbGetTimeNow
    end

    def opacity_at(time)
      hour = time.hour + time.min / 60.0 + time.sec / 3600.0
      factor = if hour >= 5 && hour < 6
                 hour - 5
               elsif hour >= 6 && hour < 18
                 1.0
               elsif hour >= 18 && hour < 20
                 (20 - hour) / 2.0
               else
                 0.0
               end
      (SUN_OPACITY.clamp(0, 255) * factor).round
    end

    def desired_opacity
      return 0 if $sun_switch == false
      return 0 unless $game_map && $game_screen
      metadata = GameData::MapMetadata.try_get($game_map.map_id)
      return 0 unless metadata && metadata.outdoor_map
      return 0 unless $game_screen.weather_type == :None
      return 0 unless nil_or_empty?($game_map.fog_name)
      opacity_at(current_time)
    end
  end
end

class Spriteset_Map
  alias sun_script_initialize initialize
  alias sun_script_update update
  alias sun_script_dispose dispose

  def initialize(*args)
    $sun_switch = true if $sun_switch.nil?
    sun_script_initialize(*args)
    SunSettings.register_spriteset(self)
  end

  def update
    sun_script_update
    updateSun if SunSettings.primary_spriteset == self
  end

  def dispose
    SunSettings.unregister_spriteset(self)
    disposeSun if SunSettings.active_spritesets.empty?
    sun_script_dispose
  end

  def createSun
    path = pbResolveBitmap(SunSettings::BGPATH) || pbResolveBitmap("Plugins/Sun Script/Sun")
    return unless path
    bitmap = Bitmap.new(path)
    sprite = Sprite.new(Spriteset_Map.viewport)
    sprite.bitmap = bitmap
    sprite.z = 200
    sprite.blend_type = 1
    sprite.x = sprite.y = 0
    sprite.zoom_x = Graphics.width.to_f / bitmap.width
    sprite.zoom_y = Graphics.height.to_f / bitmap.height
    SunSettings.sun_sprite = sprite
  end

  def updateSun
    opacity = SunSettings.desired_opacity
    if opacity <= 0
      disposeSun
      return
    end
    sprite = SunSettings.sun_sprite
    if !sprite || sprite.disposed?
      createSun
      sprite = SunSettings.sun_sprite
    end
    sprite.opacity = opacity if sprite && !sprite.disposed?
  end

  def disposeSun
    sprite = SunSettings.sun_sprite
    if sprite && !sprite.disposed?
      bitmap = sprite.bitmap
      sprite.dispose
      bitmap.dispose if bitmap && !bitmap.disposed?
    end
    SunSettings.sun_sprite = nil
  end
end
