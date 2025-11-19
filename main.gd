extends Node3D

@export var subwayCar: PackedScene;
@export var maxSubwayCarsLength: int = 8;
@export var minSubwayCarsLength: int = 3;
@export var subwayCarSpeed: float = 5.0;
@export var subwayCarSpacing: float = 24.0;


var subwayCars: Array[Node3D] = [];
@onready var carSpawnPoint: Node3D = $CarSpawnPoint


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
