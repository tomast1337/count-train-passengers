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
