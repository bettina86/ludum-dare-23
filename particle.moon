
import graphics, timer, keyboard from love

export *

class Particle
  watch_class self

  size: 1
  life: 1
  color: { 255, 255, 255 }

  fade_in_time: nil -- when to end fade in, or nil to disable
  fade_out_time: 0.4 -- when to start fade out

  -- terminal velocity
  tv: 800

  new: (@x,@y, @vx=0, @vy=0, @ax=0, @ay=0) =>
    -- MUST reset all properties that may have been set by any particle
    -- due to object reuse
    @time = 0
    @life = nil

  p: => @time / @life

  update: (dt, world) =>
    @time += dt

    @vx += @ax * dt
    @vy += @ay * dt

    @vx = math.min @tv, @vx
    @vy = math.min @tv, @vy

    @x += @vx * dt
    @y += @vy * dt

    return false unless world.viewport\touches_pt @x,@y
    @time < @life

  set_color: =>
    t = @p!
    a = if t > 0.5 then (1-t)*2*255 else 255

    a = if @fade_out_time and t >= @fade_out_time
      (1 - t) / (1 - @fade_out_time) * 255
    elseif @fade_in_time and t < @fade_in_time
      t / @fade_in_time * 255
    else
      255

    r,g,b = unpack @color
    graphics.setColor r,g,b,a

  draw: =>
    half = @size / 2
    @set_color!
    graphics.rectangle "fill", @x - half, @y - half, @size, @size

class ImageParticle extends Particle
  sprite: nil -- set by make_drawable
  drawable: nil

  new: (...) =>
    self.make_drawable @@__base unless @drawable
    super ...

  draw: =>
    @set_color!

    half_x = @sprite.cell_w / 2
    half_y = @sprite.cell_h / 2

    @drawable @x - half_x, @y - half_y


class Emitter
  self.draw_list = nil
  self.emitter_list = nil

  self.draw_all = =>
    return unless @draw_list
    @draw_list\draw!
    graphics.setColor 255,255,255,255


  self.update_all = (dt, world) =>
    return unless @emitter_list
    @emitter_list\update dt
    @draw_list\update dt, world

  -- this is a class method!!
  add: (cls, ...) ->
    Emitter.emitter_list = ReuseList! if not Emitter.emitter_list
    Emitter.emitter_list\add cls, ...

  ----

  per_frame: 1
  rate: 0.1
  dir: 0
  fan: math.pi/5

  ax: 0
  ay: 0

  vel: 0

  amount: 15 -- how many particles to spawn before death

  default_particle: Particle

  new: (@world, @x, @y, @particle_cls=@default_particle) =>
    if not @draw_list
      Emitter.draw_list = ReuseList!
      Emitter.__base.draw_list = Emitter.draw_list

    @attach = nil -- attached to some object?
    @amount = @@amount
    @time = @rate

  spawn: =>
    return if @amount == 0 -- no more particles!
    dir = @dir + (math.random! - 0.5) * @fan
    dx, dy = math.cos(dir), math.sin(dir)

    @draw_list\add @particle_cls, @x, @y, dx*@vel, dy*@vel, dx*@ax, dy*@ay

    @amount -= 1 if @amount != nil

  update: (dt) =>
    @time += dt
    while @time > @rate
      for i=1,@per_frame
        @spawn!
      @time -= @rate

    @amount == nil or @amount > 0

module "particles", package.seeall

class Spark extends Particle
  color: { 255, 211, 118 } -- the spark?
  life: 1.0

  new: (...) =>
    super ...
    if 1 == math.random 8
      @life = @life * (math.random! * 3 + 2)
    else
      @life = @life * (math.random! / 2 + 0.05)


class BlueSpark extends Spark
  color: { 99, 242, 255 }

class Smoke extends ImageParticle
  life: 0.8
  fade_in_time: 0.1
  fade_out_time: 0.2
  cell_id: 1

  -- so ugly
  make_drawable: (base) ->
    base.sprite = with Spriter imgfy"img/sprite.png", 16, 20
      .oy = 20 * 3

    base.drawable = (x, y) =>
      base.sprite\draw_cell base.cell_id, x, y

class BlueGlow extends Smoke
  life: 0.2
  cell_id: 2

class Explosion extends ImageParticle
  life: 0.8

  fade_in_time: nil
  fade_out_time: nil

  make_drawable: (base) ->
    base.sprite = with Spriter imgfy"img/sprite.png", 16, 20
      .oy = 20 * 2

    anim = Animator base.sprite, { 1, 2, 3, 4, 5 }
    base.drawable = (x, y) =>
      anim\drawt @p!, x, y

module "emitters", package.seeall

class HitEnemy extends Emitter
  default_particle: particles.Spark

  per_frame: 4
  rate: 0.05
  amount: 8
  ay: -200
  vel: 100

  dir: math.pi*1.5

class PourSmoke extends Emitter
  default_particle: particles.Smoke
  rate: 0.05
  per_frame: 2
  amount: 10

  fan: math.pi

  vel: 10

class ShootBlue extends Emitter
  default_particle: particles.BlueGlow
  vel: 20
  dir: math.pi*1.5
  fan: 0
  amount: 1

class Explosion extends Emitter
  default_particle: particles.Explosion
  amount: 1

class BigExplosion extends Emitter
  default_particle: particles.Explosion
  amount: 4

  spawn: (...) =>
    @x += math.random -2,2
    @y += math.random -2,2
    super ...

class RadialSpark extends Emitter
  default_particle: particles.Spark
  amount: 20
  rate: 0.03
  vel: 100
  ay: 500
  fan: 2*math.pi

class RadialBlue extends RadialSpark
  default_particle: particles.BlueSpark
  rate: 0.03
  per_frame: 4
  amount: 8
  life: 0.1

