extends Node

# Sound files for BGM and SFX
const SFX_attack_sound = preload("res://audio/sfx/attack_sound.ogg")
const SFX_coin_flip_sound = preload("res://audio/sfx/coin_flip_sound.ogg")
const SFX_knockout_sound = preload("res://audio/sfx/knockout_sound.ogg")
const SFX_select_button = preload("res://audio/sfx/select_button.ogg")
const SFX_evolve_sound = preload("res://audio/sfx/evolve_sound.ogg")
const SFX_trainer_sound = preload("res://audio/sfx/trainer_sound.ogg")
const SFX_damage_sound = preload("res://audio/sfx/damage_sound.ogg")
const SFX_status_sound = preload("res://audio/sfx/status_sound.ogg")
const SFX_energy_sound = preload("res://audio/sfx/energy_sound.ogg")
const SFX_card_draw_sound = preload("res://audio/sfx/card_draw_sound.ogg")
const SFX_poison_sound = preload("res://audio/sfx/poison_sound.ogg")
const SFX_heal_sound = preload("res://audio/sfx/heal_sound.ogg")

const SFX_plus_select = preload("res://audio/sfx/plus_select.ogg")
const SFX_minus_select = preload("res://audio/sfx/minus_select.ogg")
const SFX_gamemode_select = preload("res://audio/sfx/gamemode_select_sound.ogg")



func play_sfx(sound: AudioStream) -> void:
	# Create a temporary AudioStreamPlayer, play it, then free it automatically
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.play()
	# 'finished' signal frees the node once playback ends
	player.finished.connect(player.queue_free)
