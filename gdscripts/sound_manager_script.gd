extends Node

# ============================================================
# SOUND MANAGER - Autoload Singleton
# ============================================================
# Handles all audio playback: SFX (one-shot) and BGM (looping).
# Register this as an Autoload named "SoundManagerScript".
# ============================================================

# --- Preloaded SFX constants ---
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

const SFX_battle_start = preload("res://audio/sfx/battle_start.ogg")
const SFX_battle_win = preload("res://audio/sfx/battle_win_sound.ogg")
const SFX_battle_loss = preload("res://audio/sfx/battle_loss_sound.ogg")

# --- BGM player (persists until stopped or replaced) ---
var bgm_player: AudioStreamPlayer = null

# --- SFX: play a preloaded AudioStream as a one-shot ---
func play_sfx(sound: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.play()
	player.finished.connect(player.queue_free)

# --- SFX: load from a res:// path and play as a one-shot ---
func play_sfx_from_path(path: String) -> void:
	var stream = load(path)
	if stream:
		play_sfx(stream)
	else:
		print("SoundManager: Could not load SFX at: ", path)

# --- BGM: play background music from a res:// path ---
# If loop is true the track will repeat. Calling this while BGM is
# already playing will stop the old track and start the new one.
func play_bgm(path: String, loop: bool = true) -> void:
	stop_bgm()
	
	var stream = load(path)
	if stream == null:
		print("SoundManager: Could not load BGM at: ", path)
		return
	
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.stream = stream
	bgm_player.bus = "Master"
	
	if loop:
		bgm_player.stream.loop = true
	
	bgm_player.play()

# --- BGM: stop and free the current BGM player ---
func stop_bgm() -> void:
	if bgm_player != null:
		bgm_player.stop()
		bgm_player.queue_free()
		bgm_player = null
