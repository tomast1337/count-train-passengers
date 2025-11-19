extends Control

@onready var speedMin: SpinBox = $PanelOptions/SpeedMin
@onready var speedMax: SpinBox = $PanelOptions/SpeedMax
@onready var wagonMin: SpinBox = $PanelOptions/WagonMin
@onready var wagonMax: SpinBox = $PanelOptions/WagonMax

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass



func _on_quit_button_pressed() -> void:
    # stop the game
    get_tree().quit()

func _on_start_button_pressed() -> void:
    # start the game
    get_tree().change_scene_to_file("res://main.tscn")


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
