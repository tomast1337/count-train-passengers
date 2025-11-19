extends Node3D

@onready var mainCameraAnimationPlayer: AnimationPlayer = $AnimationPlayer

@export var subwayCar: PackedScene;
@export var maxSubwayCarsLength: int = 8;
@export var minSubwayCarsLength: int = 3;
@export var subwayCarSpeed: float = 5.0;
@export var subwayCarSpacing: float = 24.0;
@export var minSubwayCarSpeed: float = 2.0;
@export var maxSubwayCarSpeed: float = 16.0;

var subwayCars: Array[Node3D] = [];
@onready var carSpawnPoint: Node3D = $CarSpawnPoint
@onready var hud: Control = $Control
@onready var player1CounterLabel: Label = hud.get_node("Player1Counter") if hud else null
@onready var player2CounterLabel: Label = hud.get_node("Player2Counter") if hud else null

@onready var player1ClickSound: AudioStreamPlayer3D = $Player1ClickSound
@onready var player2ClickSound: AudioStreamPlayer3D = $Player2ClickSound

@onready var startTimer: Timer = $StartTimer
@onready var gameOverTimer: Timer = $GameOverTimer

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

    countDownAudioStreamPlayer3D.stream = audios[str(timerDuration)]
    countDownAudioStreamPlayer3D.play()

    #play reset camera animation
    if  mainCameraAnimationPlayer.has_animation("RESET"):
        mainCameraAnimationPlayer.play("RESET")
    else:
        push_error("RESET animation not found")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    # get player1_up player2_up player1_down player2_down input events
    var player1_up = Input.is_action_just_pressed("player1_up")
    var player2_up = Input.is_action_just_pressed("player2_up")
    var player1_down = Input.is_action_just_pressed("player1_down")
    var player2_down = Input.is_action_just_pressed("player2_down")

    if player1_up:
        _adjust_counter_for_player(1, 1)
        gameOverTimer.reset()
    if player1_down:
        _adjust_counter_for_player(1, -1)
        gameOverTimer.reset()
    if player2_up:
        _adjust_counter_for_player(2, 1)
        gameOverTimer.reset()
    if player2_down:
        _adjust_counter_for_player(2, -1)
        gameOverTimer.reset()

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

@onready var countDownAudioStreamPlayer3D: AudioStreamPlayer3D = $CountDownAudioStreamPlayer3D

var audios = {
    "0": preload("res://sound/0.mp3"),
    "1": preload("res://sound/4.mp3"),
    "2": preload("res://sound/3.mp3"),
    "3": preload("res://sound/2.mp3"),
    "4": preload("res://sound/1.mp3"),
}

func _on_start_timer_timeout() -> void:
    currentTimerDuration -= 1;
    countDownAudioStreamPlayer3D.stream = audios[str(currentTimerDuration)]
    countDownAudioStreamPlayer3D.play()
    print("Current timer duration: %d" % currentTimerDuration);
    if currentTimerDuration <= 0:
        _spawn_train()
    else:
        # start the timer again
        startTimer.start()

func _spawn_train() -> void:
    if not subwayCar:
        push_error("Subway car scene is not assigned.")
        return

    var length := _get_train_length()
    var train_speed := _get_train_speed()
    print("Spawning %d subway cars at speed %.2f" % [length, train_speed])

    for i in range(length):
        var car := subwayCar.instantiate()
        car.position = carSpawnPoint.position + Vector3(0, 0, i * subwayCarSpacing);
        add_child(car);
        subwayCars.append(car);
        car.speed = train_speed;


# end game peeps display path
@onready var endGamePeepsDisplay: Path3D = $StationSections2/PeepsPath

func _on_game_over_timer_timeout() -> void:
    # spawn the peeps on the end game peeps display path
    var peeps = endGamePeepsDisplay.get_children()
    for peep in peeps:
        peep.visible = true


func _get_train_length() -> int:
    var min_length: int = min(minSubwayCarsLength, maxSubwayCarsLength)
    var max_length: int = max(minSubwayCarsLength, maxSubwayCarsLength)
    var length_range: int = max(1, max_length - min_length + 1)
    return (randi() % length_range) + min_length


func _get_train_speed() -> float:
    var min_speed: float = min(minSubwayCarSpeed, maxSubwayCarSpeed)
    var max_speed: float = max(minSubwayCarSpeed, maxSubwayCarSpeed)
    if is_equal_approx(min_speed, max_speed):
        return min_speed
    if max_speed <= min_speed:
        return subwayCarSpeed
    return randf_range(min_speed, max_speed)
