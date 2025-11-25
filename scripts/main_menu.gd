extends Node3D

@onready var spawnTimer: Timer = $SpawnTimer # The timer to spawn the subway cars
@onready var carSpawnPoint: Node3D = $CarSpawnPoint # The point where the subway cars will spawn

@export var subwayCar: PackedScene; # The subway car scene to spawn

@export var maxSubwayCarsLength: int = 8; # Maximum length of the subway cars
@export var minSubwayCarsLength: int = 3; # Minimum length of the subway cars

@export var minSubwayCarSpeed: float = 2.0; # Minimum speed of the subway cars
@export var maxSubwayCarSpeed: float = 16.0; # Maximum speed of the subway cars

@export var subwayCarSpacing: float = 24.0; # Distance between subway cars
@export var offScreenThreshold: float = -50.0;  # Z position where train is considered off screen

var subwayCars: Array[Node3D] = []; # Track the subway cars in the current train
var currentTrain: Node3D = null;  # Track the currently spawned train
var waitingForTrainToLeave: bool = false;  # Flag to know when to check if train is off screen

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    print("[main_menu] _ready() - Initializing")
    print("[main_menu] Spawn timer: ", spawnTimer)
    print("[main_menu] Car spawn point: ", carSpawnPoint)
    print("[main_menu] Subway car scene: ", subwayCar)
    print("[main_menu] Off screen threshold: ", offScreenThreshold)


func _on_spawn_timer_timeout() -> void:
    print("[main_menu] Timer timeout - Spawning new train")
    # Stop the timer while the train is on screen
    spawnTimer.stop()
    print("[main_menu] Timer stopped")
    waitingForTrainToLeave = true
    print("[main_menu] Waiting for train to leave screen")
    
    # Spawn a new train
    _spawn_train()


func _spawn_train() -> void:
    if not subwayCar:
        push_error("[main_menu] Subway car PackedScene not assigned!")
        return
    
    # Determine the length of the train
    var length = randi() % (maxSubwayCarsLength - minSubwayCarsLength + 1) + minSubwayCarsLength
    print("[main_menu] Spawning train with %d cars" % length)
    
    # Create a parent node to group all cars together
    var train = Node3D.new()
    train.name = "Train"
    train.global_position = carSpawnPoint.global_position
    print("[main_menu] Train spawn position: ", train.global_position)
    add_child(train)
    currentTrain = train
    print("[main_menu] Train created and added to scene")
    var speed = randf_range(minSubwayCarSpeed, maxSubwayCarSpeed)
    # Spawn subway cars
    var cars_spawned = 0
    for i in range(length):
        var car = subwayCar.instantiate()
        if car:
            car.position = Vector3(0, 0, i * subwayCarSpacing)
            train.add_child(car)
            car.speed = speed
            subwayCars.append(car)
            cars_spawned += 1
            print("[main_menu] Car %d spawned at local position: %s, speed: %s" % [i, car.position, car.speed])
    
    print("[main_menu] Train spawned successfully with %d cars" % cars_spawned)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    # Check if we're waiting for the train to leave and if it's off screen
    if waitingForTrainToLeave and currentTrain:
        # Check if the train (or its last car) has moved off screen
        var isOffScreen = false
        
        if currentTrain.get_child_count() > 0:
            # Get the last car (furthest back)
            var lastCar = currentTrain.get_child(currentTrain.get_child_count() - 1)
            var lastCarZ = lastCar.global_position.z
            
            if lastCarZ <= offScreenThreshold:
                isOffScreen = true    
        if isOffScreen:
            # Train is off screen, remove it and restart timer
            print("[main_menu] Removing train from scene")
            currentTrain.queue_free()
            currentTrain = null
            waitingForTrainToLeave = false
            # Restart the timer to spawn next train
            print("[main_menu] Restarting spawn timer")
            spawnTimer.start()
            print("[main_menu] Timer started - waiting for next timeout")
