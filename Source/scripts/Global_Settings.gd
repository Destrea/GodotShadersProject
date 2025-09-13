extends Resource
class_name GlobalSettings

signal on_camera_fov_updated(fov: int)
@export var camera_fov: int = 75 : set = set_camera_fov, get = get_camera_fov

signal on_outline_toggle_updated(status:bool)
@export var Outline_Shader : bool = true : set = toggle_outline_efect, get = get_outline_bool;

signal on_quantize_toggle_updated(status:bool)
@export var quantize_shader : bool = true : set = toggle_quantize_effect, get = get_quantize_bool;

signal on_color_level_updated(level:int)
signal on_color_toggle_updated(status:bool)
@export var color_limit : bool = true : set = toggle_color_limit, get = get_limit_bool;
@export var color_level : int = 8 : set = set_color_level, get = get_color_level;

signal on_dither_amount_updated(dither: float)
signal on_dither_toggle_updated(status:bool)
@export var Dither_shader : bool = true : set = toggle_dither_shader, get = get_dither_bool;
@export var dither_amount :float = 0.3 : set = set_dither_amount, get = get_dither_amount;

func set_camera_fov(value: int) -> void:
	camera_fov = value
	on_camera_fov_updated.emit(camera_fov)

func get_camera_fov() -> int:
	return camera_fov

func toggle_outline_efect(value:bool) -> void:
	Outline_Shader = value
	on_outline_toggle_updated.emit(value)
	
func get_outline_bool()->bool:
	return Outline_Shader

func toggle_quantize_effect(value:bool)-> void:
	quantize_shader = value
	on_quantize_toggle_updated.emit(value)

func get_quantize_bool()->bool:
	return quantize_shader

func toggle_color_limit(value:bool)->void:
	color_limit = value
	on_color_toggle_updated.emit(value)

func get_limit_bool() -> bool:
	return color_limit

func set_color_level(value:int) -> void:
	color_level = value
	on_color_level_updated.emit(color_level)
	
func get_color_level()-> int:
	return color_level

func toggle_dither_shader(value:bool)->void:
	Dither_shader = value
	on_dither_toggle_updated.emit(value)
	
func get_dither_bool() -> bool:
	return Dither_shader

func set_dither_amount(value: float) -> void:
	dither_amount = value
	on_dither_amount_updated.emit(dither_amount)
	
func get_dither_amount() -> float:
	return dither_amount
