extends MeshInstance3D

#var color_level_val = self.material.get_shader_parameter("color_levels")

#var color_lim_enable = self.material.get_shader_parameter("enable_color_limit")

func _ready() -> void:
	SettingsSingleton.global_settings.on_outline_toggle_updated.connect(update_outline_toggle)
	update_outline_toggle(SettingsSingleton.global_settings.get_outline_bool())
	#Color Level value
	SettingsSingleton.global_settings.on_color_level_updated.connect(update_color_level)
	update_color_level(SettingsSingleton.global_settings.get_color_level())
	#Color Limit enable/disable
	SettingsSingleton.global_settings.on_color_toggle_updated.connect(update_color_toggle)
	update_color_toggle(SettingsSingleton.global_settings.get_limit_bool())
	#Dither amount value
	SettingsSingleton.global_settings.on_dither_amount_updated.connect(update_dither_amount)
	update_dither_amount(SettingsSingleton.global_settings.get_dither_amount())
	#Dithering enable/disable
	SettingsSingleton.global_settings.on_dither_toggle_updated.connect(update_dither_toggle)
	update_dither_toggle(SettingsSingleton.global_settings.get_dither_bool())
	
	SettingsSingleton.global_settings.on_quantize_toggle_updated.connect(update_quantize_toggle)
	update_quantize_toggle(SettingsSingleton.global_settings.get_quantize_bool())


func update_outline_toggle(status:bool) -> void:
	material_override.set_shader_parameter("enable_outline",status)

func update_color_level(level:int) -> void:
	material_override.set_shader_parameter("color_levels",level)

func update_color_toggle(status:bool) -> void:
	material_override.set_shader_parameter("enable_color_limit",status)

func update_quantize_toggle(status:bool) -> void:
	material_override.set_shader_parameter("enable_color_palette",status)

func update_dither_amount(amount:float) -> void:
	material_override.set_shader_parameter("dither_strength",amount)

func update_dither_toggle(status:bool) -> void:
	material_override.set_shader_parameter("enable_dithering",status)
