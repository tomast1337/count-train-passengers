extends Node3D

@export var peepAnimation: PackedScene;
@export var peepModel: Array[PackedScene] = [];
@export var speed: float = 5.0;  # Speed in units per second along z-axis

@onready var audioStreamPlayer3D: AudioStreamPlayer3D = $AudioStreamPlayer3D

var peeps: Array[Node3D] = [];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Defer spawning to ensure all nodes are in the tree
    call_deferred("_spawn_peeps")

    # set up audio stream player 3D
    if audioStreamPlayer3D:
        audioStreamPlayer3D.play()
        const minSubwayCarSpeed: float = 2.0;
        const maxSubwayCarSpeed: float = 16.0;
        audioStreamPlayer3D.unit_size = minSubwayCarSpeed * maxSubwayCarSpeed;

        # scale the pitch of the audio stream player 3D based on the speed of the subway car
        # Normalize speed to 0-1 range
        var normalized_speed = (speed - minSubwayCarSpeed) / (maxSubwayCarSpeed - minSubwayCarSpeed)
        normalized_speed = clamp(normalized_speed, 0.0, 1.0)
        
        # Apply square root curve for more natural pitch scaling (ease-out)
        var curved_speed = sqrt(normalized_speed)
        
        # Map to pitch range (0.7 = slower/lower pitch, 1.5 = faster/higher pitch)
        const min_pitch: float = 0.7
        const max_pitch: float = 1.5
        audioStreamPlayer3D.pitch_scale = lerp(min_pitch, max_pitch, curved_speed)




func _spawn_peeps() -> void:
    # Get the Spawnpoints node
    var spawnpoints = get_node_or_null("Spawnpoints")
    if not spawnpoints:
        push_error("Spawnpoints node not found!")
        return
    
    # Get all child nodes (spawn points)
    var spawn_point_children = spawnpoints.get_children()
    if spawn_point_children.is_empty():
        push_warning("Spawnpoints has no children!")
        return
    
    if peepModel.is_empty():
        push_warning("No peep models assigned!")
        return
    
    # Spawn a peep at each spawn point
    for spawn_point in spawn_point_children:
        if randf() > 0.5:
            continue
        # Pick a random peep model
        var random_model = peepModel[randi() % peepModel.size()]
        if not random_model:
            continue
        
        # Instantiate the peep model
        var peep_instance = random_model.instantiate()
        if not peep_instance:
            continue
        
        # Get spawn point's world position
        var spawn_position = spawn_point.global_position
        
        # Add to scene first
        add_child(peep_instance)
        peeps.append(peep_instance)
        
        # Set position after adding to tree
        peep_instance.global_position = spawn_position
        
        # Add animation player and play idle animation
        if peepAnimation:
            # Check if peep already has an AnimationPlayer
            var anim_player = peep_instance.get_node_or_null("AnimationPlayer") as AnimationPlayer
            
            if not anim_player or not anim_player.has_animation("idle"):
                # Add the AnimationPlayer from peepAnimation scene
                var anim_player_instance = peepAnimation.instantiate()
                if anim_player_instance is AnimationPlayer:
                    anim_player = anim_player_instance as AnimationPlayer
                    peep_instance.add_child(anim_player)
                elif anim_player_instance:
                    # Try to find AnimationPlayer as a child
                    anim_player = anim_player_instance.get_node_or_null("AnimationPlayer") as AnimationPlayer
                    if anim_player:
                        peep_instance.add_child(anim_player_instance)
            
            # Play idle animation if available (with looping)
            if anim_player and anim_player.has_animation("idle"):
                # Set loop mode to loop
                var anim = anim_player.get_animation("idle")
                if anim:
                    anim.loop_mode = Animation.LOOP_LINEAR
                # Play the animation - it will loop automatically
                anim_player.play("idle")
                # Apply random offset to the animation
                var anim_length = anim.length
                var random_offset = randf() * anim_length
                anim_player.seek(random_offset)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    # Move the subway car along the z-axis at constant speed
    position.z -= speed * delta


func _on_tree_exiting() -> void:
    if audioStreamPlayer3D:
        audioStreamPlayer3D.stop()
        audioStreamPlayer3D.queue_free()

func stop() -> void:
    speed = 0.0
    set_process(false)  # Disable _process to prevent any further movement