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
@onready var hud: Control = $HUD
@onready var player1CounterLabel: Label = hud.get_node("Player1/Player1Counter") if hud else null
@onready var player2CounterLabel: Label = hud.get_node("Player2/Player2Counter") if hud else null

@onready var player1ClickSound: AudioStreamPlayer3D = $Player1ClickSound
@onready var player2ClickSound: AudioStreamPlayer3D = $Player2ClickSound

@onready var startTimer: Timer = $StartTimer
@onready var gameOverTimer: Timer = $GameOverTimer

@export var player1Counter: int = 0;
@export var player2Counter: int = 0;
@export var maxCounterValue: int = 999;
@export var lineZPosition: float = 0.0;  # Z position of the line to cross

# Score calculation parameters
@export var perfect_score: int = 100;  # Score for perfect guess
@export var worst_score: int = 0;  # Minimum score for worst guess
@export var score_error_multiplier: float = 50.0;  # Multiplier for percentage error in score calculation
@export var min_percentage_error: float = 0.0;  # Minimum percentage error (clamp)
@export var max_percentage_error: float = 1.0;  # Maximum percentage error (clamp)

var currentTrainCars: Array[Node3D] = [];  # Track cars of the current train
var hasEmittedSignalForCurrentTrain: bool = false;  # Prevent multiple emissions
var reparentedPeeps: Array[Node3D] = [];  # Track peeps that were reparented to main scene

var player1Score: int = 0;  # Current round score
var player2Score: int = 0;  # Current round score
var player1TotalScore: int = 0;  # Cumulative score across all rounds
var player2TotalScore: int = 0;  # Cumulative score across all rounds
var correctAnswer: int = 0;

signal counter_changed(player: int, counter: int);
signal last_wagon_crossed_line();

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    randomize()

    # connect the counter_changed signal to the player1Counter and player2Counter
    if !player1CounterLabel:
        push_error("Player1CounterLabel not found")
    if !player2CounterLabel:
        push_error("Player2CounterLabel not found")

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

    countDownAudioStreamPlayer3D.stream = AUDIOS[str(timerDuration)]
    countDownAudioStreamPlayer3D.play()

    # Connect animation finished signal
    if mainCameraAnimationPlayer:
        if not mainCameraAnimationPlayer.animation_finished.is_connected(_on_animation_player_animation_finished):
            mainCameraAnimationPlayer.animation_finished.connect(_on_animation_player_animation_finished)
    
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
        # Only reset timer if it's already running (game over phase)
        if not gameOverTimer.is_stopped():
            gameOverTimer.start()  # Reset timeout after last input
    if player1_down:
        _adjust_counter_for_player(1, -1)
        if not gameOverTimer.is_stopped():
            gameOverTimer.start()  # Reset timeout after last input
    if player2_up:
        _adjust_counter_for_player(2, 1)
        if not gameOverTimer.is_stopped():
            gameOverTimer.start()  # Reset timeout after last input
    if player2_down:
        _adjust_counter_for_player(2, -1)
        if not gameOverTimer.is_stopped():
            gameOverTimer.start()  # Reset timeout after last input

    # Check if last wagon has crossed the line
    _check_last_wagon_crossed_line()

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

const AUDIOS = {
    "0": preload("res://sound/0.mp3"),
    "1": preload("res://sound/4.mp3"),
    "2": preload("res://sound/3.mp3"),
    "3": preload("res://sound/2.mp3"),
    "4": preload("res://sound/1.mp3"),
}

func _on_start_timer_timeout() -> void:
    currentTimerDuration -= 1;
    countDownAudioStreamPlayer3D.stream = AUDIOS[str(currentTimerDuration)]
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

    # Reset tracking for new train
    currentTrainCars.clear()
    hasEmittedSignalForCurrentTrain = false

    for i in range(length):
        var car := subwayCar.instantiate()
        car.position = carSpawnPoint.position + Vector3(0, 0, i * subwayCarSpacing);
        add_child(car);
        subwayCars.append(car);
        currentTrainCars.append(car);
        car.speed = train_speed;


# end game peeps display path
@onready var endGamePeepsDisplayPath: Path3D = $StationSections2/PeepsPath

func _on_game_over_timer_timeout() -> void:
    # 1. NOW we calculate the scores (Inputs are final)
    player1Score = _calculate_score(player1Counter, correctAnswer)
    player2Score = _calculate_score(player2Counter, correctAnswer)
    
    # 2. Add to totals
    player1TotalScore += player1Score
    player2TotalScore += player2Score

    print("Final P1 Guess: %d | Score: %d" % [player1Counter, player1Score])
    print("Final P2 Guess: %d | Score: %d" % [player2Counter, player2Score])

    # 3. Update UI
    hud.hide_counter_labels()
    hud.update_score_label(player1Counter, player2Counter, correctAnswer, player1Score, player2Score, player1TotalScore, player2TotalScore)
    hud.show_score_label()
    
    if mainCameraAnimationPlayer.has_animation("end_game"):
        # Stop all subway cars first
        for car in currentTrainCars:
            if is_instance_valid(car) and car.has_method("stop"):
                car.stop()
        
        # Collect all peeps from all subway cars and reparent them
        var all_peeps: Array[Node3D] = []
        for car in currentTrainCars:
            if not is_instance_valid(car):
                continue
            # Access the peeps array from the subway car
            if "peeps" in car:
                var car_peeps = car.peeps
                if car_peeps is Array:
                    for peep in car_peeps:
                        if is_instance_valid(peep):
                            # Reparent peep to main scene so it's no longer affected by car movement
                            var old_parent = peep.get_parent()
                            if old_parent:
                                old_parent.remove_child(peep)
                            add_child(peep)
                            all_peeps.append(peep)
                            reparentedPeeps.append(peep)  # Track for cleanup
        
        # Distribute peeps evenly along the path
        if not all_peeps.is_empty() and endGamePeepsDisplayPath:
            _distribute_peeps_along_path(all_peeps, endGamePeepsDisplayPath)
        
        mainCameraAnimationPlayer.play("end_game")
    else:
        push_error("end_game animation not found")


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

func _distribute_peeps_along_path(peeps: Array[Node3D], path: Path3D) -> void:
    if peeps.is_empty() or not path or not path.curve:
        return
    
    var curve = path.curve
    var path_length = curve.get_baked_length()
    var peep_count = peeps.size()
    
    if peep_count == 0:
        return
    
    # Distribute peeps evenly along the path
    for i in range(peep_count):
        var peep = peeps[i]
        if not is_instance_valid(peep):
            continue
        
        # Calculate offset along the path (0.0 to 1.0)
        # For N peeps, distribute from start (0.0) to end (1.0)
        var offset: float = 0.0
        if peep_count > 1:
            offset = float(i) / float(peep_count - 1)
        else:
            offset = 0.5  # Single peep goes to middle
        offset = clamp(offset, 0.0, 1.0)
        
        # Get the position along the curve at this offset
        var path_position = curve.sample_baked(offset * path_length)
        
        # Convert to global position
        var target_position = path.to_global(path_position)
        
        # Move the peep to this position
        peep.global_position = target_position
        # rotate the peep 180 degrees around the y axis
        peep.rotation.y = PI + peep.rotation.y 
        
        # Make peep visible if it wasn't already
        peep.visible = true

func _count_total_peeps() -> int:
    var total_peeps: int = 0
    for car in currentTrainCars:
        if not is_instance_valid(car):
            continue
        if "peeps" in car:
            var car_peeps = car.peeps
            if car_peeps is Array:
                for peep in car_peeps:
                    if is_instance_valid(peep):
                        total_peeps += 1
    return total_peeps

func _calculate_score(guess: int, actual: int) -> int:
    print("\n--- SCORE DEBUG ---")
    print("Guess: %d | Actual: %d" % [guess, actual])
    
    # 1. Handle Zero Case
    if actual == 0:
        var result = perfect_score if guess == 0 else worst_score
        print("Actual is 0. Result: %d" % result)
        return result
    
    # 2. Calculate Difference
    var difference = abs(float(guess - actual))
    print("Difference: %f" % difference)
    
    # 3. Calculate Percentage Error (e.g. 0.1 for 10%)
    var percentage_error = difference / float(actual)
    print("Error %%: %f" % percentage_error)
    
    # 4. Calculate Penalty (Error * Multiplier)
    # With multiplier 50.0: 10% error = 5 points penalty
    var penalty = percentage_error * score_error_multiplier
    print("Penalty to subtract: %f" % penalty)
    
    # 5. Final Score
    var raw_score = float(perfect_score) - penalty
    print("Raw Score (100 - Penalty): %f" % raw_score)
    
    var final_score = clampi(int(round(raw_score)), worst_score, perfect_score)
    print("Final Clamped Score: %d" % final_score)
    print("-------------------\n")
    
    return final_score

func _check_last_wagon_crossed_line() -> void:
    # Only check if we have cars and haven't emitted signal yet
    if currentTrainCars.is_empty() or hasEmittedSignalForCurrentTrain:
        return

    # Find the last wagon (the one with the highest z position, since they're spawned with increasing z offsets)
    var lastWagon: Node3D = null
    var highestZ: float = -INF

    for car in currentTrainCars:
        # Remove invalid cars (that may have been freed)
        if not is_instance_valid(car):
            continue
        
        var carZ = car.global_position.z
        if carZ > highestZ:
            highestZ = carZ
            lastWagon = car

    # Check if last wagon has crossed the line
    # Since cars move in negative z direction, they cross when z <= lineZPosition
    if lastWagon and is_instance_valid(lastWagon):
        if lastWagon.global_position.z <= lineZPosition:
            hasEmittedSignalForCurrentTrain = true
            last_wagon_crossed_line.emit()
            print("Last wagon crossed the line at z = %.2f" % lineZPosition)


func _on_last_wagon_crossed_line() -> void:
    # 1. Count the actual passengers (Correct Answer)
    correctAnswer = _count_total_peeps()
    print("Train left. Correct answer is: %d. Waiting for player final inputs..." % correctAnswer)
    
    # 2. DO NOT calculate score here. The players are still guessing!
    
    # 3. Start the countdown to the results screen
    gameOverTimer.start()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
    if anim_name == "end_game":
        _start_new_round()

func _start_new_round() -> void:
    # Delete all subway cars
    for car in subwayCars:
        if is_instance_valid(car):
            car.queue_free()
    subwayCars.clear()
    currentTrainCars.clear()
    
    # Delete all peeps that were reparented to main scene
    for peep in reparentedPeeps:
        if is_instance_valid(peep):
            peep.queue_free()
    reparentedPeeps.clear()
    
    # Reset game state (but keep cumulative scores)
    player1Counter = 0
    player2Counter = 0
    currentTimerDuration = timerDuration
    hasEmittedSignalForCurrentTrain = false
    correctAnswer = 0
    player1Score = 0  # Reset round score
    player2Score = 0  # Reset round score
    # Note: player1TotalScore and player2TotalScore are NOT reset - they persist across rounds
    
    # Stop game over timer
    if not gameOverTimer.is_stopped():
        gameOverTimer.stop()
    
    # Update HUD
    _update_counter_label(player1CounterLabel, player1Counter)
    _update_counter_label(player2CounterLabel, player2Counter)
    hud.show_counter_labels()
    hud.hide_score_label()
    
    # Play RESET camera animation
    if mainCameraAnimationPlayer.has_animation("RESET"):
        mainCameraAnimationPlayer.play("RESET")
    else:
        push_error("RESET animation not found")
    
    # Start countdown timer
    countDownAudioStreamPlayer3D.stream = AUDIOS[str(timerDuration)]
    countDownAudioStreamPlayer3D.play()
    startTimer.start()
