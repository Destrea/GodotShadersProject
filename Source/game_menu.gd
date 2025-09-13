extends CanvasLayer


@onready var fov_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/FOV/Fov_slider
@onready var fov_label: Label = $PanelContainer/MarginContainer/VBoxContainer/FOV/Fov_label

@onready var outline_toggle: CheckBox = $"PanelContainer/MarginContainer/VBoxContainer/Toon Shader/OutlineToggle"
@onready var dither_label : Label = $PanelContainer/MarginContainer/VBoxContainer/DitherSlider/Dither_Label
@onready var dither_toggle: CheckBox = $"PanelContainer/MarginContainer/VBoxContainer/Dither Shader/DitherToggle"
@onready var dither_slider : HSlider = $PanelContainer/MarginContainer/VBoxContainer/DitherSlider/Dither_slider
@onready var color_label : Label = $PanelContainer/MarginContainer/VBoxContainer/ColorSlider/Color_Label
@onready var color_toggle : CheckBox = $"PanelContainer/MarginContainer/VBoxContainer/Color Limiter/ColorLimToggle"
@onready var color_slider : HSlider = $PanelContainer/MarginContainer/VBoxContainer/ColorSlider/Color_slider
@onready var palette_toggle : CheckBox = $PanelContainer/MarginContainer/VBoxContainer/ColorPalette/ColorPaletteToggle


var in_menu: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	connect_fov_settings()
	connect_colorlim_settings()
	connect_dither_settings()
	connect_outline_settings()
	connect_palette_settings()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Esc"):
		in_menu = !in_menu
		visible = in_menu
		get_tree().set_pause(in_menu)
		if in_menu:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func connect_palette_settings()->void:
	palette_toggle.toggled.connect(SettingsSingleton.global_settings.toggle_quantize_effect)
	palette_toggle.set_pressed_no_signal(SettingsSingleton.global_settings.get_quantize_bool())


func connect_outline_settings()->void:
	outline_toggle.toggled.connect(SettingsSingleton.global_settings.toggle_outline_efect)
	outline_toggle.set_pressed_no_signal(SettingsSingleton.global_settings.get_outline_bool())

func connect_fov_settings() -> void:
	fov_slider.value_changed.connect(SettingsSingleton.global_settings.set_camera_fov)
	SettingsSingleton.global_settings.on_camera_fov_updated.connect(update_fov_label)
	fov_slider.set_value_no_signal(SettingsSingleton.global_settings.get_camera_fov())
	update_fov_label(SettingsSingleton.global_settings.get_camera_fov())

func connect_dither_settings() -> void:
	#Dithering slider/value changing
	dither_slider.value_changed.connect(SettingsSingleton.global_settings.set_dither_amount)
	SettingsSingleton.global_settings.on_dither_amount_updated.connect(update_dither_label)
	dither_slider.set_value_no_signal(SettingsSingleton.global_settings.get_dither_amount())
	update_dither_label(SettingsSingleton.global_settings.get_dither_amount())
	#Toggle
	dither_toggle.toggled.connect(SettingsSingleton.global_settings.toggle_dither_shader)
	dither_toggle.set_pressed_no_signal(SettingsSingleton.global_settings.get_dither_bool())

func connect_colorlim_settings() -> void:
	# Color limit slider/value changing
	color_slider.value_changed.connect(SettingsSingleton.global_settings.set_color_level)
	SettingsSingleton.global_settings.on_color_level_updated.connect(update_color_label)
	color_slider.set_value_no_signal(SettingsSingleton.global_settings.get_color_level())
	update_color_label(SettingsSingleton.global_settings.get_color_level())
	# Toggle
	color_toggle.toggled.connect(SettingsSingleton.global_settings.toggle_color_limit)
	color_toggle.set_pressed_no_signal(SettingsSingleton.global_settings.get_limit_bool())

func update_color_label(level:int) -> void:
	color_label.set_text(str(level))

func update_dither_label(amount:float) -> void:
	dither_label.set_text(str(amount))

func update_fov_label(fov: int) ->void:
	fov_label.set_text(str(fov))

func _on_outline_toggle_toggled(toggled_on: bool) -> void:
	SettingsSingleton.global_settings.Outline_Shader = toggled_on

func _on_fxaa_toggle_toggled(toggled_on: bool) -> void:
	SettingsSingleton.global_settings.FXAA_Shader = toggled_on

func _on_dither_toggle_toggled(toggled_on: bool) -> void:
	SettingsSingleton.global_settings.Dither_shader = toggled_on
