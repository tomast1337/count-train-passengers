extends Control

const SCORE_TEMPLATE: String = """[b]Round Result:[/b]
Player 1 Guess: {Player1Guess} → {Player1RoundScore} Points
Player 2 Guess: {Player2Guess} → {Player2RoundScore} Points

[b]Correct Answer:[/b] 
{CorrectAnswer}

--------------------------------

[b]Game Score (Total):[/b]
Player 1: {Player1TotalScore} Points
Player 2: {Player2TotalScore} Points
"""

@export var player1Counter: int = 0;
@export var player2Counter: int = 0;

@onready var player1CounterLabel: Label = $Player1/Player1Counter
@onready var player2CounterLabel: Label = $Player2/Player2Counter
@onready var scoreLabel: RichTextLabel = $ScoreBoard/ScoreLabel

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

func hide_score_label() -> void:
    var scoreBoard: Control = $ScoreBoard
    if scoreBoard:
        scoreBoard.visible = false

func show_score_label() -> void:
    var scoreBoard: Control = $ScoreBoard
    if scoreBoard:
        scoreBoard.visible = true

func update_score_label(player1Guess: int, player2Guess: int, correctAnswer: int, player1RoundScore: int, player2RoundScore: int, player1TotalScore: int, player2TotalScore: int) -> void:
    scoreLabel.text = SCORE_TEMPLATE.format({
        "Player1Guess": player1Guess,
        "Player2Guess": player2Guess,
        "CorrectAnswer": correctAnswer,
        "Player1RoundScore": player1RoundScore,
        "Player2RoundScore": player2RoundScore,
        "Player1TotalScore": player1TotalScore,
        "Player2TotalScore": player2TotalScore,
    })
