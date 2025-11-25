extends Control

@onready var speedMin: SpinBox = $PanelOptions/SpeedMin
@onready var speedMax: SpinBox = $PanelOptions/SpeedMax
@onready var wagonMin: SpinBox = $PanelOptions/WagonMin
@onready var wagonMax: SpinBox = $PanelOptions/WagonMax

@onready var quitButton: Button = $Panel/QuitButton

@export var minSubwayCarSpeed: float = 2.0;
@export var maxSubwayCarSpeed: float = 16.0;
@export var minSubwayCarsLength: int = 3;
@export var maxSubwayCarsLength: int = 8;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Initialize values from exported variables
    if speedMin:
        speedMin.value = minSubwayCarSpeed
    if speedMax:
        speedMax.value = maxSubwayCarSpeed
    if wagonMin:
        wagonMin.value = minSubwayCarsLength
    if wagonMax:
        wagonMax.value = maxSubwayCarsLength

    # if running in a browser, hide the quit button
    if OS.get_name() == "HTML5":
        quitButton.visible = false

func _on_quit_button_pressed() -> void:
    # stop the game
    get_tree().quit()

func _on_start_button_pressed() -> void:
    var main_scene: PackedScene = load("res://scenes/main.tscn")
    if not main_scene:
        push_error("Unable to load the main scene.")
        return

    var main_scene_instance: Node3D = main_scene.instantiate() as Node3D
    if not main_scene_instance:
        push_error("Failed to instantiate the main scene.")
        return

    _apply_selected_settings_to_game(main_scene_instance)
    _replace_current_scene(main_scene_instance)


func _apply_selected_settings_to_game(game_scene: Node3D) -> void:
    if not game_scene:
        return

    var speed_min_value := float(speedMin.value)
    var speed_max_value := float(speedMax.value)
    var wagon_min_value := int(wagonMin.value)
    var wagon_max_value := int(wagonMax.value)

    # Clamp to ensure logical ordering before assigning.
    if speed_max_value < speed_min_value:
        var swap_speed := speed_min_value
        speed_min_value = speed_max_value
        speed_max_value = swap_speed

    if wagon_max_value < wagon_min_value:
        var swap_wagon := wagon_min_value
        wagon_min_value = wagon_max_value
        wagon_max_value = swap_wagon

    game_scene.minSubwayCarSpeed = speed_min_value
    game_scene.maxSubwayCarSpeed = speed_max_value
    game_scene.minSubwayCarsLength = wagon_min_value
    game_scene.maxSubwayCarsLength = wagon_max_value


func _replace_current_scene(new_scene: Node3D) -> void:
    if not new_scene:
        return

    var tree := get_tree()
    var root := tree.root
    var previous_scene := tree.current_scene

    root.add_child(new_scene)
    tree.current_scene = new_scene

    if previous_scene:
        previous_scene.queue_free()


func _on_speed_max_value_changed(value: float) -> void:
    if not speedMax or not speedMin:
        return
    
    var min_value = speedMin.value
    const min_difference: float = 1.0
    
    # Ensure max is at least min + 1
    if value < min_value + min_difference:
        speedMax.value = min_value + min_difference
    else:
        speedMax.value = value


func _on_speed_min_value_changed(value: float) -> void:
    if not speedMin or not speedMax:
        return
    
    var max_value = speedMax.value
    const min_difference: float = 1.0
    
    # Ensure min is at most max - 1
    if value > max_value - min_difference:
        speedMin.value = max_value - min_difference
    else:
        speedMin.value = value


func _on_wagon_max_value_changed(value: float) -> void:
    if not wagonMax or not wagonMin:
        return
    
    var min_value = int(wagonMin.value)
    const min_difference: int = 1
    var new_value = int(value)
    
    # Ensure max is at least min + 1
    if new_value < min_value + min_difference:
        wagonMax.value = min_value + min_difference
    else:
        wagonMax.value = new_value

func _on_wagon_min_value_changed(value: float) -> void:
    if not wagonMin or not wagonMax:
        return
    
    var max_value = int(wagonMax.value)
    const min_difference: int = 1
    var new_value = int(value)
    
    # Ensure min is at most max - 1
    if new_value > max_value - min_difference:
        wagonMin.value = max_value - min_difference
    else:
        wagonMin.value = new_value


func _on_volume_h_slider_value_changed(value: float) -> void:
    # Slider is 0-100, convert to a linear 0-1 value, then to dB
    var normalized_volume: float = clamp(value / 100.0, 0.0, 1.0)
    var db_volume: float = linear_to_db(normalized_volume)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_volume)
