extends Node3D

@export var subwayCar: PackedScene;
@export var maxSubwayCarsLength: int = 8;
@export var minSubwayCarsLength: int = 3;
@export var subwayCarSpeed: float = 5.0;
@export var subwayCarSpacing: float = 24.0;

var subwayCars: Array[Node3D] = [];
@onready var carSpawnPoint: Node3D = $CarSpawnPoint
@onready var hud: Control = $Control
@onready var player1CounterLabel: Label = hud.get_node("Player1Counter") if hud else null
@onready var player2CounterLabel: Label = hud.get_node("Player2Counter") if hud else null

@onready var player1ClickSound: AudioStreamPlayer3D = $Player1ClickSound
@onready var player2ClickSound: AudioStreamPlayer3D = $Player2ClickSound

@onready var startTimer: Timer = $StartTimer

@export var player1Counter: int = 0;
@export var player2Counter: int = 0;
@export var maxCounterValue: int = 999;

signal counter_changed(player: int, counter: int);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    randomize()

    # connect the counter_changed signal to the player1Counter and player2Counter
    counter_changed.connect(func(player: int, counter: int):
        if player == 1:
            player1Counter = counter;
            _update_counter_label(player1CounterLabel, player1Counter)
        elif player == 2:
            player2Counter = counter;
            _update_counter_label(player2CounterLabel, player2Counter)
    )

    # ensure HUD shows the initial value
    _update_counter_label(player1CounterLabel, player1Counter)
    _update_counter_label(player2CounterLabel, player2Counter)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    # get player1_up player2_up player1_down player2_down input events
    var player1_up = Input.is_action_just_pressed("player1_up")
    var player2_up = Input.is_action_just_pressed("player2_up")
    var player1_down = Input.is_action_just_pressed("player1_down")
    var player2_down = Input.is_action_just_pressed("player2_down")

    if player1_up:
        _adjust_counter_for_player(1, 1)
    if player1_down:
        _adjust_counter_for_player(1, -1)
    if player2_up:
        _adjust_counter_for_player(2, 1)
    if player2_down:
        _adjust_counter_for_player(2, -1)


func _adjust_counter_for_player(player: int, delta: int) -> void:
    if delta == 0:
        return

    var current_value = player1Counter if player == 1 else player2Counter
    var new_value = clampi(current_value + delta, 0, maxCounterValue)

    if new_value != current_value:
        counter_changed.emit(player, new_value)
        # gte a random pitch for the click sound
        var randomPitch = randf_range(0.8, 1.2)
        if player == 1:
            player1ClickSound.pitch_scale = randomPitch
            player1ClickSound.play()
        elif player == 2:
            player2ClickSound.pitch_scale = randomPitch
            player2ClickSound.play()

func _update_counter_label(label: Label, value: int) -> void:
    if label:
        label.text = str(value)


@export var timerDuration: int = 4;
var currentTimerDuration: int = timerDuration;

func _on_start_timer_timeout() -> void:
    currentTimerDuration -= 1;
    print("Current timer duration: %d" % currentTimerDuration);
    if currentTimerDuration <= 0:
        # set the length of the subway cars
        var length = randi() % (maxSubwayCarsLength - minSubwayCarsLength + 1) + minSubwayCarsLength;
        print("Spawning %d subway cars" % length);
        # spawn the subway cars
        for i in range(length):
            var car = subwayCar.instantiate();
            car.position = carSpawnPoint.position + Vector3(0, 0, i * subwayCarSpacing);
            add_child(car);
            subwayCars.append(car);
            car.speed = subwayCarSpeed;
    else:
        # start the timer again
        startTimer.start()

    
