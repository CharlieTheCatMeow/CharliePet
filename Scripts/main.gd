extends Node2D

var speed = 300
var direction = Vector2(0, 0)
var screen_size = Vector2()
var window_size = Vector2(200, 200)

var idle_timer = 0.0
var idle_cooldown = 0
var is_idling = false

var is_dragging = false
var drag_offset = Vector2()

var mouse_no_movement = false
var mouse_no_movement_timer = 8.0
var mouse_position = Vector2(DisplayServer.mouse_get_position())
var last_mouse_position = Vector2()
var is_going_to_sleep = false
var go_to_sleep_timer = 0.0
var is_sleeping = false
var is_waking_up = false
var wake_up_timer = 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

func _ready() -> void:
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.flip_h = true
	animated_sprite.play("Walk")
	area.input_event.connect(_on_area_input)

func _physics_process(delta: float) -> void:
	if is_dragging:
		var mouse_pos = Vector2(DisplayServer.mouse_get_position())
		var new_win_pos = mouse_pos - drag_offset
		DisplayServer.window_set_position(Vector2i(new_win_pos))
		return

	mouse_position = Vector2(DisplayServer.mouse_get_position())
	mouse_position.x -= window_size.x / 2
	mouse_position.y -= window_size.y / 2

	if mouse_position != last_mouse_position:
		mouse_no_movement_timer = 8.0
		mouse_no_movement = false
		if is_going_to_sleep:
			is_going_to_sleep = false
			if is_sleeping:
				is_sleeping = false
				is_waking_up = true
				var sprite_frames = animated_sprite.sprite_frames
				var num_frames = sprite_frames.get_frame_count("Wake_up")
				var anim_speed = animated_sprite.speed_scale * sprite_frames.get_animation_speed("Wake_up")
				wake_up_timer = num_frames / anim_speed
				animated_sprite.play("Wake_up")
				speed = 0
			else:
				speed = 300
				animated_sprite.play("Walk")
	last_mouse_position = mouse_position

	if is_going_to_sleep:
		go_to_sleep_timer -= delta
		if go_to_sleep_timer <= 0:
			is_sleeping = true
			if animated_sprite.sprite_frames.has_animation("Sleep"):
				animated_sprite.play("Sleep")
		return
		
	if is_waking_up:
		wake_up_timer -= delta
		if wake_up_timer <= 0:
			is_waking_up = false
			speed = 300
			animated_sprite.play("Walk")
		return

	if is_idling:
		idle_timer -= delta
		if idle_timer <= 0:
			is_idling = false
			idle_cooldown = 4.0
			speed = 300
			animated_sprite.play("Walk")
	else:
		idle_cooldown -= delta
	var window_position = Vector2(DisplayServer.window_get_position())
	direction = window_position.direction_to(mouse_position)
	if window_position.distance_to(mouse_position) >= 100:
		if !is_idling:
			animated_sprite.play("Walk")
		window_position += direction * speed * delta
		window_position.x = clamp(window_position.x, 0, screen_size.x - window_size.x)
		window_position.y = clamp(window_position.y, 0, screen_size.y - window_size.y)
	else:
		if !is_idling:
			maybe_idle()
		if idle_cooldown > 0:
			animated_sprite.play("Idle")

		mouse_no_movement_timer -= delta

	if direction.x < 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true

	if mouse_no_movement_timer <= 0:
		mouse_no_movement = true
	if mouse_no_movement and not is_going_to_sleep:
		is_going_to_sleep = true
		is_idling = false
		var animation_name = "Go_to_sleep"
		var sprite_frames = animated_sprite.sprite_frames
		var num_frames = sprite_frames.get_frame_count(animation_name)
		var anim_speed = animated_sprite.speed_scale * sprite_frames.get_animation_speed(animation_name)
		go_to_sleep_timer = num_frames / anim_speed
		animated_sprite.play(animation_name)
		speed = 0
	if not mouse_no_movement:
		speed = 300

	DisplayServer.window_set_position(Vector2i(window_position))

func maybe_idle():
	if idle_cooldown > 0:
		return
	if randf() < 0.3:
		is_idling = true
		var r = randi() % 3
		if r == 0:
			var animation_name = "Stretch"
			var sprite_frames = animated_sprite.sprite_frames
			var num_frames = sprite_frames.get_frame_count(animation_name)
			var anim_speed = animated_sprite.speed_scale * sprite_frames.get_animation_speed(animation_name)
			idle_timer = num_frames / anim_speed
			animated_sprite.play(animation_name)
			speed = 0
		elif r == 1:
			var animation_name = "Look_left"
			var sprite_frames = animated_sprite.sprite_frames
			var num_frames = sprite_frames.get_frame_count(animation_name)
			var anim_speed = animated_sprite.speed_scale * sprite_frames.get_animation_speed(animation_name)
			idle_timer = num_frames / anim_speed
			animated_sprite.play(animation_name)
			speed = 0
		elif r == 2:
			var animation_name = "Look_right"
			var sprite_frames = animated_sprite.sprite_frames
			var num_frames = sprite_frames.get_frame_count(animation_name)
			var anim_speed = animated_sprite.speed_scale * sprite_frames.get_animation_speed(animation_name)
			idle_timer = num_frames / anim_speed
			animated_sprite.play(animation_name)
			speed = 0

func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			if is_going_to_sleep:
				is_going_to_sleep = false
				is_sleeping = false
				mouse_no_movement = false
				mouse_no_movement_timer = 8.0
				speed = 300
				animated_sprite.play("Walk")
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos
		else:
			is_dragging = false
