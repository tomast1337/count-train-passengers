extends Control

@export var player1Counter: int = 0;
@export var player2Counter: int = 0;

@onready var player1CounterLabel: Label = $Player1/Player1Counter
@onready var player2CounterLabel: Label = $Player2/Player2Counter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    player1CounterLabel.text = str(player1Counter)
    player2CounterLabel.text = str(player2Counter)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass

func hide_counter_labels() -> void:
    var player1Control: Control = $Player1
    var player2Control: Control = $Player2
    if player1Control:
        player1Control.visible = false
    if player2Control:
        player2Control.visible = false

func show_counter_labels() -> void:
    var player1Control: Control = $Player1
    var player2Control: Control = $Player2
    if player1Control:
        player1Control.visible = true
    if player2Control:
        player2Control.visible = true
