extends Node3D

@export var peepAnimation: PackedScene;
@export var peepModel: Array[PackedScene] = [];
@export var max_peeps: int = 15;
@export var min_peeps: int = 2;

var peeps: Array[Node3D] = [];
var peep_count: int = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    peep_count = randi() % (max_peeps - min_peeps) + min_peeps;
    # Defer spawning to ensure all nodes are in the tree
    call_deferred("_spawn_peeps")


func _spawn_peeps() -> void:
    # Get the Path3D node
    var path_3d = get_node_or_null("Path3D")
    if not path_3d:
        push_error("Path3D not found!")
        return
    
    # Get the curve from Path3D
    var curve = path_3d.curve
    if not curve:
        push_error("Path3D has no curve!")
        return
    
    var curve_length = curve.get_baked_length()
    if curve_length <= 0:
        push_error("Path3D curve has no length!")
        return
    
    # Spawn peeps
    for i in range(peep_count):
        if peepModel.is_empty():
            push_warning("No peep models assigned!")
            break
        
        # Pick a random peep model
        var random_model = peepModel[randi() % peepModel.size()]
        if not random_model:
            continue
        
        # Instantiate the peep model
        var peep_instance = random_model.instantiate()
        if not peep_instance:
            continue
        
        # Calculate random position along the path
        var random_offset = randf() * curve_length
        var random_position = curve.sample_baked(random_offset)
        
        # Transform to world space using Path3D's global transform
        var path_transform = path_3d.global_transform
        var world_position = path_transform * random_position
        
        # Add to scene first
        add_child(peep_instance)
        peeps.append(peep_instance)
        
        # Set position after adding to tree
        peep_instance.global_position = world_position
        
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
            
            # Play idle animation if available
            if anim_player and anim_player.has_animation("idle"):
                anim_player.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass
