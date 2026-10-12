class_name NeonAnimationFrames
extends RefCounted

# Generated from reference-guided video clips by the documented art pipeline.
# Literal preloads keep every runtime frame discoverable by the Web exporter.

const HERO_IDLE = [
	preload("res://assets/characters/hero/idle/idle_00.webp"),
]

const HERO_RUN = [
	preload("res://assets/characters/hero/run/run_00.webp"),
	preload("res://assets/characters/hero/run/run_01.webp"),
	preload("res://assets/characters/hero/run/run_02.webp"),
	preload("res://assets/characters/hero/run/run_03.webp"),
	preload("res://assets/characters/hero/run/run_04.webp"),
	preload("res://assets/characters/hero/run/run_05.webp"),
	preload("res://assets/characters/hero/run/run_06.webp"),
	preload("res://assets/characters/hero/run/run_07.webp"),
	preload("res://assets/characters/hero/run/run_08.webp"),
	preload("res://assets/characters/hero/run/run_09.webp"),
	preload("res://assets/characters/hero/run/run_10.webp"),
	preload("res://assets/characters/hero/run/run_11.webp"),
	preload("res://assets/characters/hero/run/run_12.webp"),
]

const HERO_JUMP = [
	preload("res://assets/characters/hero/jump/jump_00.webp"),
	preload("res://assets/characters/hero/jump/jump_01.webp"),
	preload("res://assets/characters/hero/jump/jump_02.webp"),
	preload("res://assets/characters/hero/jump/jump_03.webp"),
	preload("res://assets/characters/hero/jump/jump_04.webp"),
	preload("res://assets/characters/hero/jump/jump_05.webp"),
	preload("res://assets/characters/hero/jump/jump_06.webp"),
	preload("res://assets/characters/hero/jump/jump_07.webp"),
	preload("res://assets/characters/hero/jump/jump_08.webp"),
	preload("res://assets/characters/hero/jump/jump_09.webp"),
	preload("res://assets/characters/hero/jump/jump_10.webp"),
	preload("res://assets/characters/hero/jump/jump_11.webp"),
]

const HERO_ATTACK = [
	preload("res://assets/characters/hero/attack/attack_00.webp"),
	preload("res://assets/characters/hero/attack/attack_01.webp"),
	preload("res://assets/characters/hero/attack/attack_02.webp"),
	preload("res://assets/characters/hero/attack/attack_03.webp"),
	preload("res://assets/characters/hero/attack/attack_04.webp"),
	preload("res://assets/characters/hero/attack/attack_05.webp"),
	preload("res://assets/characters/hero/attack/attack_06.webp"),
	preload("res://assets/characters/hero/attack/attack_07.webp"),
	preload("res://assets/characters/hero/attack/attack_08.webp"),
	preload("res://assets/characters/hero/attack/attack_09.webp"),
	preload("res://assets/characters/hero/attack/attack_10.webp"),
	preload("res://assets/characters/hero/attack/attack_11.webp"),
]

const HERO_DEATH = [
	preload("res://assets/characters/hero/death/death_00.webp"),
	preload("res://assets/characters/hero/death/death_01.webp"),
	preload("res://assets/characters/hero/death/death_02.webp"),
	preload("res://assets/characters/hero/death/death_03.webp"),
	preload("res://assets/characters/hero/death/death_04.webp"),
	preload("res://assets/characters/hero/death/death_05.webp"),
	preload("res://assets/characters/hero/death/death_06.webp"),
	preload("res://assets/characters/hero/death/death_07.webp"),
	preload("res://assets/characters/hero/death/death_08.webp"),
	preload("res://assets/characters/hero/death/death_09.webp"),
	preload("res://assets/characters/hero/death/death_10.webp"),
	preload("res://assets/characters/hero/death/death_11.webp"),
]

const BLADE_IDLE = [
	preload("res://assets/characters/blade_guard/idle/idle_00.webp"),
]

const BLADE_RUN = [
	preload("res://assets/characters/blade_guard/run/run_00.webp"),
	preload("res://assets/characters/blade_guard/run/run_01.webp"),
	preload("res://assets/characters/blade_guard/run/run_02.webp"),
	preload("res://assets/characters/blade_guard/run/run_03.webp"),
	preload("res://assets/characters/blade_guard/run/run_04.webp"),
	preload("res://assets/characters/blade_guard/run/run_05.webp"),
	preload("res://assets/characters/blade_guard/run/run_06.webp"),
	preload("res://assets/characters/blade_guard/run/run_07.webp"),
	preload("res://assets/characters/blade_guard/run/run_08.webp"),
	preload("res://assets/characters/blade_guard/run/run_09.webp"),
	preload("res://assets/characters/blade_guard/run/run_10.webp"),
	preload("res://assets/characters/blade_guard/run/run_11.webp"),
	preload("res://assets/characters/blade_guard/run/run_12.webp"),
]

const BLADE_ATTACK = [
	preload("res://assets/characters/blade_guard/attack/attack_00.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_01.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_02.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_03.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_04.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_05.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_06.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_07.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_08.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_09.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_10.webp"),
	preload("res://assets/characters/blade_guard/attack/attack_11.webp"),
]

const BLADE_DEATH = [
	preload("res://assets/characters/blade_guard/death/death_00.webp"),
	preload("res://assets/characters/blade_guard/death/death_01.webp"),
	preload("res://assets/characters/blade_guard/death/death_02.webp"),
	preload("res://assets/characters/blade_guard/death/death_03.webp"),
	preload("res://assets/characters/blade_guard/death/death_04.webp"),
	preload("res://assets/characters/blade_guard/death/death_05.webp"),
	preload("res://assets/characters/blade_guard/death/death_06.webp"),
	preload("res://assets/characters/blade_guard/death/death_07.webp"),
	preload("res://assets/characters/blade_guard/death/death_08.webp"),
	preload("res://assets/characters/blade_guard/death/death_09.webp"),
	preload("res://assets/characters/blade_guard/death/death_10.webp"),
	preload("res://assets/characters/blade_guard/death/death_11.webp"),
]

const GUNNER_IDLE = [
	preload("res://assets/characters/gunner/idle/idle_00.webp"),
]

const GUNNER_WALK = [
	preload("res://assets/characters/gunner/walk/walk_00.webp"),
	preload("res://assets/characters/gunner/walk/walk_01.webp"),
	preload("res://assets/characters/gunner/walk/walk_02.webp"),
	preload("res://assets/characters/gunner/walk/walk_03.webp"),
	preload("res://assets/characters/gunner/walk/walk_04.webp"),
	preload("res://assets/characters/gunner/walk/walk_05.webp"),
	preload("res://assets/characters/gunner/walk/walk_06.webp"),
	preload("res://assets/characters/gunner/walk/walk_07.webp"),
	preload("res://assets/characters/gunner/walk/walk_08.webp"),
	preload("res://assets/characters/gunner/walk/walk_09.webp"),
	preload("res://assets/characters/gunner/walk/walk_10.webp"),
	preload("res://assets/characters/gunner/walk/walk_11.webp"),
	preload("res://assets/characters/gunner/walk/walk_12.webp"),
]

const GUNNER_SHOOT = [
	preload("res://assets/characters/gunner/shoot/shoot_00.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_01.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_02.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_03.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_04.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_05.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_06.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_07.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_08.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_09.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_10.webp"),
	preload("res://assets/characters/gunner/shoot/shoot_11.webp"),
]

const GUNNER_DEATH = [
	preload("res://assets/characters/gunner/death/death_00.webp"),
	preload("res://assets/characters/gunner/death/death_01.webp"),
	preload("res://assets/characters/gunner/death/death_02.webp"),
	preload("res://assets/characters/gunner/death/death_03.webp"),
	preload("res://assets/characters/gunner/death/death_04.webp"),
	preload("res://assets/characters/gunner/death/death_05.webp"),
	preload("res://assets/characters/gunner/death/death_06.webp"),
	preload("res://assets/characters/gunner/death/death_07.webp"),
	preload("res://assets/characters/gunner/death/death_08.webp"),
	preload("res://assets/characters/gunner/death/death_09.webp"),
	preload("res://assets/characters/gunner/death/death_10.webp"),
	preload("res://assets/characters/gunner/death/death_11.webp"),
]
