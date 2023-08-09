#####################################################################
#
# CSCB58 Summer 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Kevin Lan, 1009407143, lankevin, k.lan@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed)
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 3 
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Show health ( health will be 3 hearts ) [2]
# 2. Fail condition (fall below screen or lose all 3 hearts) [1]
# 3. Win condition (get to top of level) [1]
# 4. Moving platforms [2]
# 5. Wall Jump (double jump) [1]
# 6. Different levels (at least 3) [2]
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Video link: 		https://play.library.utoronto.ca/watch/ff7af9ac0a99ab3fcdfc08660b2a9b86
# Github Link: 		https://github.com/kevin-lann/CSCB58-Final-Project
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - Reminder: I implemented Wall Jump for the Double Jump feature
# - Have fun!
#
#####################################################################

# addresses
.eqv BASE_ADDR 		0x10008000
.eqv KEYBOARD_ADDR 	0xffff0000

# colors
.eqv PLAYER_EYE_COLOR	0xF9FF8A
.eqv PLAYER_BASE_COLOR	0x0ACE6C
.eqv PLAYER_DARK_COLOR	0x155837
.eqv PLAYER_LIGHT_COLOR 0x2CFB1A

.eqv PLAT_BASE_COLOR	0xA7A491
.eqv PLAT_DARK_COLOR	0x76746B

.eqv HEART_BASE_COLOR 	0xD22552
.eqv HEART_DARK_COLOR	0x7C132E
.eqv HEART_ICON_BASE_COLOR 	0xFF4488
.eqv HEART_ICON_DARK_COLOR	0x81134E
.eqv GOLD_HEART_ICON_BASE_COLOR 0xE8D66A
.eqv GOLD_HEART_ICON_DARK_COLOR	0x90794D

.eqv SPIKE_BASE_COLOR 	0xF7F4F8
.eqv SPIKE_DARK_COLOR	0xB6B4AA

# dimensions
.eqv WIDTH		256	
.eqv HEIGHT		256
.eqv WIDTH_ACT		512	# actual width by px
.eqv HEIGHT_ACT		512	# actual height by px
.eqv TOTAL_PIXELS	16384

# timing
.eqv REFRESH_RATE	60
.eqv GRAVITY_RATE	2	# gravity acts once per GRAVITY_RATE frames

# player attributes
.eqv PLAYER_HEIGHT	4
.eqv PLAYER_WIDTH	3
.eqv PLAYER_DEFAULT_DX  4	
.eqv PLAYER_DEFAULT_DY 	-2 	
.eqv PLAYER_SPAWN_LOC	14464	# x = 32, y = 56
.eqv PLAYER_DEFAULT_HP	3
.eqv PLAYER_MAX_HP	4

# Game constants
.eqv GRAVITY_DY		1
.eqv JUMPING_DY		-1
.eqv TOTAL_LEVELS	3


.data

newLine: .asciiz 	"\n"
Pressed: .asciiz	"Press\n"

PlayerDx: .word		0	# player speed in x direc (0 means stationary)
PlayerDy: .word		0	# player speed in y direc (0 means stationary)
PlayerJumpHeight: .word	11	# no. pixels able to be jumped by player
PlayerCoord: .word	0	# player coordinate on screen ( offset from BASE_ADDR essentially)
PlayerState: .word	0	# 0 = gravity, 1 = jumping
PlayerHP:	.word	0	# player health points (max = PLAYER_MAX_HP, 0 means dead)

CurrentHearts:	.word	0	# current hp hearts displayed 

GravityTicks: .word	0	# counter for gravity
Jumps: .word		0	# counter for jumping

Platform1X: .word	0	# moving platform X coord on screen 
Platform1Y: .word	0	# moving platform Y coord on screen 
Platform1Shifts: .word	0	# num of shifts right that moving platform 1 is currently shifted
Platform1MaxShifts: .word 0	# max shifts for plat1
Platform1Dx:	.word	4	# plat speed in x direc

Platform2X: .word	0	# moving platform X coord on screen 
Platform2Y: .word	0	# moving platform Y coord on screen 
Platform2Shifts: .word	0	# num of shifts right that moving platform 2 is currently shifted
Platform2MaxShifts: .word 0	# max shifts for plat2
Platform2Dx:	.word	4	# plat speed in x direc

LevelHasMovingPlats: .word 0	# stores whether or not the current level has moving plats or not
CurrentLevel: .word	1	# current level (1,2, or 3)

.text

.globl main

main:
	# Reset Game variables
	sw $zero, PlayerDx
	sw $zero, PlayerDy
	sw $zero, PlayerState
	sw $zero, GravityTicks
	sw $zero, Jumps
	li $t0, 11	# set to high number for no gravity
	sw $t0, PlayerJumpHeight
	li $t0, PLAYER_DEFAULT_HP
	sw $t0, PlayerHP
	sw $t0, CurrentHearts
	sw $zero, Platform1Shifts
	sw $zero, Platform2Shifts
	sw $zero, LevelHasMovingPlats
	
	li $t0, BASE_ADDR
	
	# draw HP hearts
	li $a0, 240
	li $a1, 7
	jal DrawHeartIcon
	li $a0, 240
	li $a1, 4
	jal DrawHeartIcon
	li $a0, 240
	li $a1, 1
	jal DrawHeartIcon
	
	# testing # # # # 
	# li $t1, 3
	# sw $t1, CurrentLevel
	
	# Draw the level
	lw $t1, CurrentLevel
LEVEL1: bgt $t1, 1, LEVEL2
	jal DrawLevel1
	j GameLoop
LEVEL2:	bgt $t1, 2, LEVEL3
	jal DrawLevel2
	j GameLoop
LEVEL3:
	jal DrawLevel3
	

# ----------- Game Loop -------------- #
GameLoop:
	# check lose
	jal CheckLose
	# check win
	jal CheckWin
	
NO_MOVING_PLATS:
	# check keypress
	li $t1, KEYBOARD_ADDR
	lw $t2, 0($t1)
	bne $t2, 1, NO_KEYPRESS
KEYPRESS: # keypress detected
	jal HandleKeypress
	j MOVE
NO_KEYPRESS: #keypress not detected
	j END_MOVE


# Moves x and/or y direc depending on whether dx and dy are nonzero
MOVE:
	lw $t2, PlayerDx
	lw $t3, PlayerDy
MOVE_X:	
	beq $t2, 0, MOVE_Y	# Dx = 0
	jal MovePlayerX
MOVE_Y:
	# beq $t3, 0, END_MOVE	# Dy = 0
	# jal MovePlayerY
END_MOVE:

	
# Do gravity / jumping stuff / move plat
	lw $t2, GravityTicks
	bne $t2, GRAVITY_RATE, END_GRAVITY
	
MOVEPLATS:
	# plat 1
	li $a0, 1
	jal MovePlat
	lw $t2, CurrentLevel
	beq $t2, 1, ENDMOVEPLATS
	# plat 2
	li $a0, 2
	jal MovePlat
ENDMOVEPLATS:
	
	lw $t3, PlayerState
	beq $zero, $t3, GRAVITY

JUMPING: # do jumping
	lw $t2, PlayerJumpHeight
	lw $t3, Jumps
	sw $zero, GravityTicks	# reset gravity ticks
	beq $t2, $t3, NO_JUMP # if reached max jump height, then no more jump
	
	li $t2, JUMPING_DY
	sw $t2, PlayerDy
	jal MovePlayerY
	
	# Jumps++
	lw $t3, Jumps
	addi $t3, $t3, 1
	sw $t3, Jumps
	
	j END_GRAVITY
NO_JUMP:
	sw $zero, Jumps # reset Jumps to 0
	sw $zero, PlayerState	# set state back to gravity
	j GRAVITY
GRAVITY: # do gravity
	sw $zero, Jumps # reset Jumps to 0
	li $t2, GRAVITY_DY
	sw $t2, PlayerDy
	jal MovePlayerY
	sw $zero, GravityTicks	# reset gravity ticks
END_GRAVITY:
	# set movement back to zero
	sw $zero, PlayerDx
	sw $zero, PlayerDy
	
	# GravityTicks++
	lw $t2, GravityTicks
	addi $t2, $t2, 1
	sw $t2, GravityTicks
	
	# draw HP hearts
	jal DrawHP
	
	li $v0, 32
	li $a0, REFRESH_RATE
	syscall
	
	j GameLoop
# ----------- Game Loop -------------- #
	
ENDMAIN:
	li $v0, 10	# terminate
	syscall



# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ STATE CHECKS ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

CheckJump: # checks if player able to jump. Requires player to be over platform 
	# and requires current PlayerState to be 0. Changes PlayerState to 1 if can jump
	lw $t4, PlayerState
	bne $zero, $t4, CHECK_JUMP_END	# if PlayerState is not 0, then cannot jump
	lw $t4, PlayerCoord
	add $t4, $t4, BASE_ADDR
	addi $t4, $t4, 1024	# 1 row below player
	lw $t5, 0($t4)
	beq $t5, PLAT_BASE_COLOR, CAN_JUMP
	lw $t5, 4($t4)
	beq $t5, PLAT_BASE_COLOR, CAN_JUMP
	lw $t5, 8($t4)
	beq $t5, PLAT_BASE_COLOR, CAN_JUMP
	
	sw $zero, PlayerState # no jump
	j CHECK_JUMP_END
CAN_JUMP:
	li $t4, 1
	sw $t4, PlayerState # jump
CHECK_JUMP_END:
	jr $ra
	
	
CheckWallJump: # Can wall jump even if playerstate is 0(falling)
	lw $t4, PlayerState
	bne $zero, $t4, CHECK_JUMP_END	# if PlayerState is not 0, then cannot jump
	
	lw $t4, PlayerCoord
	add $t4, $t4, BASE_ADDR
	
	addi $t4, $t4, 768
	lw $t5, -4($t4)	# bottom left side of player
	beq $t5, PLAT_BASE_COLOR, CAN_JUMP
	lw $t5, 16($t4) # bottom right side of player
	beq $t5, PLAT_BASE_COLOR, CAN_JUMP
	
	sw $zero, PlayerState # no jump
	j CHECK_WALL_JUMP_END
CAN_WALL_JUMP:
	li $t4, 1
	sw $t4, PlayerState # jump
CHECK_WALL_JUMP_END:
	jr $ra
	
CheckLose:
	lw $t0, PlayerHP
	beq $t0, 0, LOSE
	lw $t0, PlayerCoord
	li $t1, TOTAL_PIXELS
	addi $t1, $t1, -1024
	bge $t0, $t1, LOSE
	j NO_LOSE
LOSE:
	j LoseScreen
NO_LOSE:
	jr $ra
	
	
CheckWin:
	lw $t0, PlayerCoord
	bge $t0, 256, NO_WIN
WIN:
	lw $t0, CurrentLevel
	# increment level if not at last level yet
	beq $t0, TOTAL_LEVELS, WINGAME
	addi $t0, $t0, 1
	sw $t0, CurrentLevel
	j WinLevelScreen
WINGAME:
	li $t0, 1
	sw $t0, CurrentLevel # reset level back to 1
	j WinGameScreen
NO_WIN:
	jr $ra



# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ GAME SCREENS ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

# P icon
DrawP:
	li $t1, 0xFFFFFF
	li $t2, HEART_DARK_COLOR
	
	li $t0, BASE_ADDR
	# Draw "P"
	addi $t0, $t0, 116
	addi $t0, $t0, 4352
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t2, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t1, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	sw $t1, 12($t0)
	sw $t2, 16($t0)
	sw $t1, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t1, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	li $t1, 0xCCCCCC
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t2, 20($t0)
	sw $t2, 24($t0)
	
	jr $ra

# When WinlevelScreen is called, P must be pressed to continue the game (Lvl will be incremented)
WinLevelScreen:
	# no need to store ra here
	jal ClearScreen
	jal DrawP
	li $t1, 0xFFFFFF
	li $t2, HEART_DARK_COLOR
	
	li $t0, BASE_ADDR
	# Draw "Nxt Lvl" text
	addi $t0, $t0, 64
	addi $t0, $t0, 2048
	sw $t1, 0($t0) # row 1
	sw $t1, 4($t0)
	sw $t1, 20($t0)
	sw $t1, 28($t0)
	sw $t1, 44($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 84($t0)
	sw $t1, 100($t0)
	sw $t1, 116($t0)
	sw $t1, 124($t0)
	
	addi $t0, $t0, WIDTH # row 2
	sw $t1, 0($t0) 
	sw $t1, 12($t0)
	sw $t1, 20($t0)
	sw $t1, 32($t0)
	sw $t1, 40($t0)
	sw $t1, 60($t0)
	sw $t1, 84($t0)
	sw $t1, 100($t0)
	sw $t1, 116($t0)
	sw $t1, 124($t0)
	
	addi $t0, $t0, WIDTH # row 3
	sw $t1, 0($t0) 
	sw $t1, 12($t0)
	sw $t1, 20($t0)
	sw $t1, 36($t0)
	sw $t1, 60($t0)
	sw $t1, 84($t0)
	sw $t1, 100($t0)
	sw $t1, 116($t0)
	sw $t1, 124($t0)
	
	addi $t0, $t0, WIDTH # row 4
	sw $t1, 0($t0) 
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 32($t0)
	sw $t1, 40($t0)
	sw $t1, 60($t0)
	sw $t1, 84($t0)
	sw $t1, 104($t0)
	sw $t1, 112($t0)
	sw $t1, 124($t0)
	
	addi $t0, $t0, WIDTH # row 5
	sw $t1, 0($t0) 
	sw $t1, 20($t0) 
	sw $t1, 28($t0)
	sw $t1, 44($t0) 
	sw $t1, 60($t0)
	sw $t1, 84($t0)
	sw $t1, 88($t0)
	sw $t1, 92($t0)
	sw $t1, 108($t0)
	sw $t1, 124($t0)
	sw $t1, 128($t0)
	sw $t1, 132($t0) 
	
WinLevelScreenLoop: # wait for user to press "P"
	# check keypress
	li $t1, KEYBOARD_ADDR
	lw $t2, 0($t1)
	bne $t2, 1, WIN_LVL_NO_KEYPRESS
WIN_LVL_KEYPRESS: # keypress detected
	jal HandleKeypress
WIN_LVL_NO_KEYPRESS: #keypress not detected
	li $v0, 32
	li $a0, REFRESH_RATE
	syscall
	
	j WinLevelScreenLoop
	

# When WinGameScreen is called, P must be pressed to restart the game (lvl will be reset to 1)
WinGameScreen:
	# no need to store ra here
	jal ClearScreen
	# reset level to 1
	li $t2, 1
	lw $t2, CurrentLevel
	# Draw
	jal DrawP
	li $t1, 0xFFFFFF
	
	li $t0, BASE_ADDR
	# Draw "YOU WIN" text
	addi $t0, $t0, 76
	addi $t0, $t0, 2048
	sw $t1, 0($t0)	# row 1
	sw $t1, 8($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 32($t0)
	sw $t1, 40($t0)
	sw $t1, 52($t0)
	sw $t1, 68($t0)
	sw $t1, 76($t0)
	sw $t1, 84($t0)
	sw $t1, 88($t0)
	sw $t1, 100($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)	# row 2
	sw $t1, 8($t0)
	sw $t1, 16($t0)
	sw $t1, 24($t0)
	sw $t1, 32($t0)
	sw $t1, 40($t0)
	sw $t1, 52($t0)
	sw $t1, 68($t0)
	sw $t1, 76($t0)
	sw $t1, 84($t0)
	sw $t1, 92($t0)
	sw $t1, 100($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 4($t0)	# row 3
	sw $t1, 16($t0)
	sw $t1, 24($t0)
	sw $t1, 32($t0)
	sw $t1, 40($t0)
	sw $t1, 52($t0)
	sw $t1, 60($t0)
	sw $t1, 68($t0)
	sw $t1, 76($t0)
	sw $t1, 84($t0)
	sw $t1, 92($t0)
	sw $t1, 100($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 4($t0)	# row 4
	sw $t1, 16($t0)
	sw $t1, 24($t0)
	sw $t1, 32($t0)
	sw $t1, 40($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 76($t0)
	sw $t1, 84($t0)
	sw $t1, 96($t0)
	sw $t1, 100($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 4($t0)	# row 5
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 52($t0)
	sw $t1, 68($t0)
	sw $t1, 76($t0)
	sw $t1, 84($t0)
	sw $t1, 100($t0)

WinGameScreenLoop: # wait for user to press "P"
	# check keypress
	li $t1, KEYBOARD_ADDR
	lw $t2, 0($t1)
	bne $t2, 1, WIN_GAME_NO_KEYPRESS
WIN_GAME_KEYPRESS: # keypress detected
	jal HandleKeypress
WIN_GAME_NO_KEYPRESS: #keypress not detected
	li $v0, 32
	li $a0, REFRESH_RATE
	syscall
	
	j WinGameScreenLoop
	
	
# When LoseScreen is called, P must be pressed to restart the game
LoseScreen:
	# no need to store ra here
	jal ClearScreen
	# Draw Skull and Crossbones
	li $t1, 0xFFFFFF
	li $t2, HEART_DARK_COLOR
	
	li $t0, BASE_ADDR
	addi $t0, $t0, 768
	addi $t0, $t0, 112
	
	sw $t2, 4($t0)
	sw $t2, 28($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 24($t0)
	sw $t1, 28($t0)
	sw $t2, 32($t0)
	addi $t0, $t0, WIDTH
	sw $t2, -4($t0)
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t2, 36($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 4($t0)
	sw $t1, 8($t0)	
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t2, 28($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	sw $t1, 16($t0)
	sw $t2, 20($t0)
	sw $t1, 24($t0)
	sw $t2, 28($t0)
	addi $t0, $t0, WIDTH 
	sw $t2, 4($t0)
	sw $t1, 8($t0)	
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t2, 28($t0)
	addi $t0, $t0, WIDTH
	li $t1, 0xCCCCCC
	sw $t2, 8($t0) 
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t2, 32($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 20($t0)
	sw $t1, 24($t0)
	sw $t2, 28($t0)
	addi $t0, $t0, WIDTH
	sw $t2, 8($t0)
	sw $t2, 24($t0)
	
	jal DrawP
	
LoseScreenLoop: # wait for user to press "P"
	# check keypress
	li $t1, KEYBOARD_ADDR
	lw $t2, 0($t1)
	bne $t2, 1, LOSE_NO_KEYPRESS
LOSE_KEYPRESS: # keypress detected
	jal HandleKeypress
LOSE_NO_KEYPRESS: #keypress not detected
	li $v0, 32
	li $a0, REFRESH_RATE
	syscall
	
	j LoseScreenLoop
	



# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ KEY HANDLER ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

HandleKeypress:
	li $t0, KEYBOARD_ADDR
	li $t1, PLAYER_DEFAULT_DX
	li $t2, PLAYER_DEFAULT_DY
	li $t3, -1
	lw $t0, 4($t0)		# load the key
HandleKeyW:
	bne $t0, 0x77, HandleKeyA
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# push old ra into stack
	jal CheckJump		# check if able to jump
	lw $ra, 0($sp)		# pop old ra back
	addi $sp, $sp, 4
HandleKeyA:
	bne $t0, 0x61, HandleKeyD
	mult $t1, $t3
	mflo $t1
	sw $t1, PlayerDx	# set PlayerDx to default Dx (leftwards)
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# push old ra into stack
	jal CheckWallJump	# check if able to wall jump
	lw $ra, 0($sp)		# pop old ra back
	addi $sp, $sp, 4
HandleKeyD:
	bne $t0, 0x64, HandleKeyP
	sw $t1, PlayerDx	# set PlayerDy to default Dx (Rightwards)
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# push old ra into stack
	jal CheckWallJump	# check if able to wall jump
	lw $ra, 0($sp)		# pop old ra back
	addi $sp, $sp, 4
HandleKeyP:
	bne $t0, 0x70, HandleKeypressExit
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal ClearScreen	# clear the screen
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j main		# restart the game
HandleKeypressExit:
	jr $ra

# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ MOVE GAME OBJECTS ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

# move by PlayerDx and update player coord
MovePlayerX:
	# put old ra into stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# remove prev player
	jal ClearPlayer

	lw $t0, PlayerCoord
	
	# Update playercoord
	lw $t1, PlayerDx
	# check if Dx is 0
	beq $t1, 0, EndMoveX
	add $t0, $t0, $t1
	
	# check for collisions between borders
	subi $t1, $t0, BASE_ADDR	# get offset
	move $a0, $t1
	jal HitLeftBorder
	beq $v0, 1, EndMoveX
	
	subi $t1, $t0, BASE_ADDR	# get offset
	addi $t1, $t1, 8
	move $a0, $t1
	jal HitRightBorder
	beq $v0, 1, EndMoveX
	
	# check for coliisions between sides of objects
	li $t4, BASE_ADDR
	add $t4, $t4, $t0
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 8
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 248
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 8
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 248
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 8
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 248
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 8
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	
	# update new coord
	sw $t0, PlayerCoord
	j EndMoveX
CollisionHandlerX:
	move $a0, $t4
	jal CollisionHandler	
EndMoveX: 
	# Redraw 
	jal DrawPlayer
	
	#pop old ra back
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# move by PlayerDy
MovePlayerY:
	# remove prev player (put old ra into stack first)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal ClearPlayer
	
	# Update playercoord
	lw $t0, PlayerCoord
	lw $t1, PlayerDy
	beq, $t1, 0, EndMoveY	# check if Dy is 0
	li $t2, WIDTH
	mult $t1, $t2
	mflo $t1
	add $t0, $t0, $t1
	
	# check if hit objs
	li $t4, BASE_ADDR
	add $t4, $t4, $t0
	addi $t4, $t4, 768
	lw $t1, 0($t4)	# 4th row
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, 4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, 4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -256
	lw $t1, 0($t4)	# 3rd row
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -256
	lw $t1, 0($t4)	# 2nd row
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, 4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, 4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -256
	lw $t1, 0($t4)	# top row of player
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	
	# store new coord
	sw $t0, PlayerCoord
	j EndMoveY
CollisionHandlerY:
	move $a0, $t4
	jal CollisionHandler
EndMoveY:
	# Redraw 
	jal DrawPlayer
	
	#pop old ra back
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra



# params: a0 is the plat# to move
MovePlat:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	beq $a0, 2, MovePlat2
	
MovePlat1:
	# Clear Previous plat1
	lw $t1, Platform1X
	lw $t2, Platform1Y
	move $a0, $t1
	move $a1, $t2
	jal ClearSidePlatM
	
	lw $t3, Platform1Shifts
	lw $t4, Platform1Dx
	# check if hit movement bounds
CHECKRIGHT1:
	bne $t4, 4, CHECKLEFT1
	lw $t9, Platform1MaxShifts
	bne $t3, $t9, CHECKLEFT1
	li $t5, -4
	sw $t5, Platform1Dx
	j INCREMENT1
CHECKLEFT1:
	bne $t3, 0, INCREMENT1
	li $t5, 4
	sw $t5, Platform1Dx
	
INCREMENT1:
	# increment shift
	add $t3, $t3, $t4
	sw $t3, Platform1Shifts
	
	# update coords
	add $t1, $t1, $t4
	sw $t1, Platform1X
	
	# move
	move $a0, $t1
	move $a1, $t2
	jal DrawSidePlatM
	
	j EndMovePlat
	
MovePlat2:
	# Clear Previous plat2
	lw $t1, Platform2X
	lw $t2, Platform2Y
	move $a0, $t1
	move $a1, $t2
	jal ClearSidePlatM
	
	lw $t3, Platform2Shifts
	lw $t4, Platform2Dx
	# check if hit movement bounds
CHECKRIGHT2:
	bne $t4, 4, CHECKLEFT2
	lw $t9, Platform2MaxShifts
	bne $t3, $t9, CHECKLEFT2
	li $t5, -4
	sw $t5, Platform2Dx
	j INCREMENT2
CHECKLEFT2:
	bne $t3, 0, INCREMENT2
	li $t5, 4
	sw $t5, Platform2Dx
	
INCREMENT2:
	# increment shift
	add $t3, $t3, $t4
	sw $t3, Platform2Shifts
	
	# update coords
	add $t1, $t1, $t4
	sw $t1, Platform2X
	
	# move
	move $a0, $t1
	move $a1, $t2
	jal DrawSidePlatM
	
	
EndMovePlat:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ HANDLE COLLISONS ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

# params: int coord addr in a0
CollisionHandler:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	lw $a1, 0($a0)
CollisionPlat:
	# do nothing here. We already skipped moving the player.
CollisionHeart:
	bne $a1, HEART_BASE_COLOR, CollisionSpike
	jal ClearHeart	# remove heart from screen
	lw $a2, PlayerHP
	beq $a2, PLAYER_MAX_HP, CollisionHandlerEnd # max HP; cannot increase more
	addi $a2, $a2, 1 # increase PlayerHP
	sw $a2, PlayerHP
CollisionSpike:
	bne $a1, SPIKE_BASE_COLOR, CollisionHandlerEnd
	lw $a2, PlayerHP
	beq $a2, 0, CollisionHandlerEnd # min HP; cannot decrease more
	addi $a2, $a2, -1 # decrease PlayerHP
	sw $a2, PlayerHP
CollisionHandlerEnd:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra



# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ DRAW AND CLEAR GAME OBJECTS ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

DrawPlayer:
	li $t0, BASE_ADDR
	
	li $t1, PLAYER_BASE_COLOR
	li $t2, PLAYER_EYE_COLOR
	li $t3, PLAYER_DARK_COLOR
	
	lw $t4, PlayerCoord
	add $t0, $t0, $t4
	
	sw $t3, 0($t0)		#1st row
	sw $t1, 4($t0)
	sw $t3, 8($t0)
	
	li $t3, PLAYER_LIGHT_COLOR
	
	addi $t0, $t0, WIDTH	#2nd row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	
	addi $t0, $t0, WIDTH	#3rd row
	sw $t2, 0($t0)
	sw $t3, 4($t0)
	sw $t2, 8($t0)
	
	addi $t0, $t0, WIDTH	#4th row
	sw $t1, 0($t0)
	sw $t3, 4($t0)
	sw $t1, 8($t0)
	
	jr $ra
	
ClearPlayer:
	li $t0, BASE_ADDR
	lw $t1, PlayerCoord
	add $t0, $t0, $t1
	
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	
	addi $t0, $t0, WIDTH	#2nd row
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	
	addi $t0, $t0, WIDTH	#3rd row
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	
	addi $t0, $t0, WIDTH	#4th row
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	
	jr $ra
	
# Params: int x, int y
DrawSpikeUp:
	li $t0, BASE_ADDR
	
	li $t1, SPIKE_BASE_COLOR
	li $t2, SPIKE_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4 	#1st row
	sw $t1, 8($t0)
	
	addi $t0, $t0, WIDTH	#2nd row	
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	
	addi $t0, $t0, WIDTH	#3rd row
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	
	jr $ra

# Params: int x, int y
DrawSpikeDown:
	li $t0, BASE_ADDR
	
	li $t1, SPIKE_BASE_COLOR
	li $t2, SPIKE_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4 	#1st row
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	
	addi $t0, $t0, WIDTH	#2nd row	
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	
	addi $t0, $t0, WIDTH	#3rd row
	sw $t1, 0($t0)
	
	jr $ra

# Params: int x, int y
DrawSpikeLeft:
	li $t0, BASE_ADDR
	
	li $t1, SPIKE_BASE_COLOR
	li $t2, SPIKE_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4 	#1st row
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	
	addi $t0, $t0, WIDTH	#2nd row	
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	
	addi $t0, $t0, WIDTH	#3rd row
	sw $t1, 8($t0)
	
	jr $ra
	
# Params: int x, int y
DrawSpikeRight:
	li $t0, BASE_ADDR
	
	li $t1, SPIKE_BASE_COLOR
	li $t2, SPIKE_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4 	#1st row
	sw $t1, 0($t0)
	
	addi $t0, $t0, WIDTH	#2nd row	
	sw $t2, 0($t0)
	sw $t1, 4($t0)
	
	addi $t0, $t0, WIDTH	#3rd row
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	
	jr $ra

# Params: int x, int y
DrawSidePlatM:
	li $t0, BASE_ADDR
	li $t2, PLAT_BASE_COLOR
	li $t1, PLAT_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t2, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH	# 2nd row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	
	jr $ra
	
# Params: int x, int y
ClearSidePlatM:
	li $t0, BASE_ADDR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	sw $zero, 20($t0)
	sw $zero, 24($t0)
	addi $t0, $t0, WIDTH	# 2nd row
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	sw $zero, 20($t0)
	sw $zero, 24($t0)
	
	jr $ra
	
# Params: int x, int y
DrawSidePlatL:
	li $t0, BASE_ADDR
	li $t2, PLAT_BASE_COLOR
	li $t1, PLAT_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t2, 20($t0)
	sw $t2, 24($t0)
	sw $t2, 28($t0)
	sw $t2, 32($t0)
	sw $t2, 36($t0)
	sw $t2, 40($t0)
	sw $t2, 44($t0)
	sw $t2, 48($t0)
	sw $t2, 52($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	
	jr $ra
	
# Params: int x, int y
DrawSidePlatS:
	li $t0, BASE_ADDR
	li $t2, PLAT_BASE_COLOR
	li $t1, PLAT_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	
	jr $ra

# Params: int x, int y
DrawVertPlatM:
	li $t0, BASE_ADDR
	li $t1, PLAT_BASE_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	
	jr $ra

# Params: int x, int y
DrawVertPlatL:
	li $t0, BASE_ADDR
	li $t1, PLAT_BASE_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	addi $t0, $t0, WIDTH
	
	jr $ra
	
# Params: int x, int y
DrawHeart:
	li $t0, BASE_ADDR
	li $t1, HEART_BASE_COLOR
	li $t2, HEART_DARK_COLOR	
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, WIDTH  #3rd row
	sw $t1, 4($t0)
	
	jr $ra

# searches the 7x8 area around the address given by $a0 and clears heart color
ClearHeart:
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a0, $a0, -520
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	
	addi $a0, $a0, 256
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	
	addi $a0, $a0, 256
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	
	addi $a0, $a0, 256
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	
	addi $a0, $a0, 256
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	
	addi $a0, $a0, 256
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	
	addi $a0, $a0, 256
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	addi $a0, $a0, 4
	jal ClearHeartPixel
	
	addi $a0, $a0, 256
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	addi $a0, $a0, -4
	jal ClearHeartPixel
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# params: int addr is in $a0
ClearHeartPixel:
	lw $a1, 0($a0)
	# clear if pixel equals either heart color
	beq $a1, HEART_BASE_COLOR, CLEAR_PIXEL
	beq $a1, HEART_DARK_COLOR, CLEAR_PIXEL
	j NO_CLEAR_PIXEL
CLEAR_PIXEL:
	sw $zero, 0($a0)
NO_CLEAR_PIXEL:
	jr $ra


DrawHeartIcon:
	li $t0, BASE_ADDR
	li $t1, HEART_ICON_BASE_COLOR	
	li $t2, HEART_ICON_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, WIDTH  #3rd row
	sw $t1, 4($t0)
	
	jr $ra
	
DrawGoldHeartIcon:
	li $t0, BASE_ADDR
	li $t1, GOLD_HEART_ICON_BASE_COLOR	
	li $t2, GOLD_HEART_ICON_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, WIDTH  #3rd row
	sw $t1, 4($t0)
	
	jr $ra

# checks PlayerHP and draws num of hearts accordingly
DrawHP:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, CurrentHearts
	lw $t2, PlayerHP
	beq $t1, $t2, NO_DRAW_HP # if no change in hearts, then dont redraw
	
	# set Current Hearts to PlayerHP
	sw $t2, CurrentHearts
	# clear hearts first
	li $t0, BASE_ADDR
	
	addi $t0, $t0, WIDTH
	addi $t0, $t0, 240	# first heart
	sw $zero, 0($t0)	# 1st row
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, WIDTH  #3rd row
	sw $zero, 4($t0)
	
	addi $t0, $t0, WIDTH	# second heart
	sw $zero, 0($t0)	# 1st row
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, WIDTH  #3rd row
	sw $zero, 4($t0)
	
	addi $t0, $t0, WIDTH	# third heart
	sw $zero, 0($t0)	# 1st row
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, WIDTH  #3rd row
	sw $zero, 4($t0)
	
	addi $t0, $t0, WIDTH	# fourth heart
	sw $zero, 0($t0)	# 1st row
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, WIDTH  #3rd row
	sw $zero, 4($t0)
	
	# Draw heart icons
DrawHP4:
	blt $t2, 4, DrawHP3
	li $a0, 240
	li $a1, 10
	jal DrawGoldHeartIcon
DrawHP3: # 3 HP
	blt $t2, 3, DrawHP2
	li $a0, 240
	li $a1, 7
	jal DrawHeartIcon
DrawHP2: # 2 HP
	blt $t2, 2, DrawHP1
	li $a0, 240
	li $a1, 4
	jal DrawHeartIcon
DrawHP1: # 1 HP
	blt $t2, 1, NO_DRAW_HP
	li $a0, 240
	li $a1, 1
	jal DrawHeartIcon
NO_DRAW_HP:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
	

# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ Gameplay ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

# Clear screen
ClearScreen:
	li $t0, BASE_ADDR
	li $t1, TOTAL_PIXELS
	add $t1, $t0, $t1	# last pixel to clear
CLEARSCREENLOOP:
	bge $t0, $t1, CLEAREND
	sw $zero, 0($t0)
NEXT:
	addi $t0, $t0, 4
	j CLEARSCREENLOOP
CLEAREND:
	jr $ra
	


# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ COLLISIONS HANDLER FUNCTIONS ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
# Checks if hit left border
# 	$a0 is posistion
# 	$v0 is return 0 or 1
HitLeftBorder:
	addi $a1, $zero, WIDTH
	# check for divisibility by WIDTH
	div $a0, $a1
	mfhi $a1
	
	bne $zero, $a1, NOTHITL
HITL:	addi $v0, $zero, 1
	j HitLeftBorderExit
NOTHITL:addi $v0, $zero, 0

HitLeftBorderExit:
	jr $ra


# Checks if hit left border
# 	$a0 is posistion
# 	$v0 is return 0 or 1
HitRightBorder:
	addi $a0, $a0, 4
	addi $a1, $zero, WIDTH
	# check for divisibility by WIDTH after adding 4
	div $a0, $a1
	mfhi $a1
	
	bne $zero, $a1, NOTHITR
HITR:	addi $v0, $zero, 1
	j HitRightBorderExit
NOTHITR:addi $v0, $zero, 0

HitRightBorderExit:
	jr $ra
	

# Checks if hit top border
# 	$a0 is posistion
# 	$v0 is return 0 or 1
HitTopBorder:
	addi $a1, $zero, WIDTH
	bge $a0, $a1, NOTHITT
HITT:	addi $v0, $zero, 1
	j HitTopBorderExit
NOTHITT:addi $v0, $zero, 0

HitTopBorderExit:
	jr $ra
	
	
# Checks if hit top border
# 	$a0 is posistion
# 	$v0 is return 0 or 1
HitBottomBorder:
	addi $a1, $zero, WIDTH
	addi $a2, $zero, HEIGHT
	div $a2, $a2, 4
	subi $a2, $a2, 1
	mult $a1, $a2	# 128 * 63 for last row
	mflo $a1
	
	blt $a0, $a1, NOTHITB
HITB:	addi $v0, $zero, 1
	j HitBottomBorderExit
NOTHITB:addi $v0, $zero, 0

HitBottomBorderExit:
	jr $ra
	
	
	
# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ DRAW LEVELS ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

	
DrawLevel1:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# init player's coord
	li $t1, PLAYER_SPAWN_LOC
	sw $t1, PlayerCoord
	
	# Draw player
	jal DrawPlayer
	
	# Draw moving plats
	li $a0, 180
	li $a1, 27
	li $a2, 4
	sw $a0, Platform1X
	sw $a1, Platform1Y
	sw $a2, Platform1Dx
	
	jal DrawSidePlatM
	li $a0, 40
	sw $a0, Platform1MaxShifts
	
	# Draw plats
	li $a0, 120
	li $a1, 60
	jal DrawSidePlatM
	li $a0, 88
	li $a1, 52
	jal DrawSidePlatM
	li $a0, 64
	li $a1, 42
	jal DrawSidePlatS
	li $a0, 104
	li $a1, 42
	jal DrawSidePlatL
	li $a0, 160
	li $a1, 42
	jal DrawSidePlatL
	li $a0, 236
	li $a1, 37
	jal DrawSidePlatS
#
	li $a0, 196
	li $a1, 17
	jal DrawSidePlatM
	li $a0, 76
	li $a1, 5
	jal DrawSidePlatL
	li $a0, 136
	li $a1, 1
	jal DrawSidePlatL
	li $a0, 104
	li $a1, 13
	jal DrawSidePlatM
	li $a0, 0
	li $a1, 30
	jal DrawSidePlatM
	li $a0, 0
	li $a1, 20
	jal DrawSidePlatS
	li $a0, 16
	li $a1, 13
	jal DrawSidePlatS
	li $a0, 12
	li $a1, 5
	jal DrawSidePlatS
	
	
	#draw hearts
	li $a0, 208
	li $a1, 23
	jal DrawHeart
	
	#draw spikes
	li $a0, 108
	li $a1, 39
	jal DrawSpikeUp
	li $a0, 120
	li $a1, 39
	jal DrawSpikeUp
	li $a0, 148
	li $a1, 39
	jal DrawSpikeUp
	li $a0, 160
	li $a1, 39
	jal DrawSpikeUp
	li $a0, 172
	li $a1, 39
	jal DrawSpikeUp
	li $a0, 204
	li $a1, 39
	jal DrawSpikeUp
	li $a0, 4
	li $a1, 27
	jal DrawSpikeUp
	li $a0, 76
	li $a1, 2
	jal DrawSpikeUp
	li $a0, 120
	li $a1, 2
	jal DrawSpikeUp
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
DrawLevel2:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# init player's coord
	li $t1, PLAYER_SPAWN_LOC
	sw $t1, PlayerCoord
	
	# Draw player
	jal DrawPlayer
	
	# Draw moving plats
	li $a0, 96
	li $a1, 41
	li $a2, 4
	sw $a0, Platform1X
	sw $a1, Platform1Y
	sw $a2, Platform1Dx
	jal DrawSidePlatM
	li $a0, 84
	sw $a0, Platform1MaxShifts
	
	li $a0, 64
	li $a1, 20
	li $a2, -4
	sw $a0, Platform2X
	sw $a1, Platform2Y
	sw $a2, Platform2Dx
	jal DrawSidePlatM
	li $a0, 40
	sw $a0, Platform2MaxShifts
	
	# Draw plats
	li $a0, 244
	li $a1, 56
	jal DrawSidePlatS
	
	li $a0, 120
	li $a1, 60
	jal DrawSidePlatM
	li $a0, 64
	li $a1, 56
	jal DrawSidePlatM
	li $a0, 8
	li $a1, 37
	jal DrawVertPlatL
	li $a0, 64
	li $a1, 41
	jal DrawSidePlatM
	li $a0, 100
	li $a1, 45
	jal DrawSidePlatL
	li $a0, 156
	li $a1, 45
	jal DrawSidePlatL
	li $a0, 212
	li $a1, 45
	jal DrawSidePlatM
	
	li $a0, 192
	li $a1, 22
	jal DrawVertPlatL
	li $a0, 248
	li $a1, 25
	jal DrawVertPlatL
	li $a0, 192
	li $a1, 15
	jal DrawVertPlatM
	li $a0, 248
	li $a1, 11
	jal DrawVertPlatL
	
	# spike ball1
	li $a0, 148
	li $a1, 10
	jal DrawSidePlatS
	li $a0, 156
	li $a1, 10
	jal DrawSidePlatS
	li $a0, 148
	li $a1, 12
	jal DrawSidePlatS
	li $a0, 156
	li $a1, 12
	jal DrawSidePlatS
	li $a0, 148
	li $a1, 7
	jal DrawSpikeUp
	li $a0, 136
	li $a1, 11
	jal DrawSpikeLeft
	li $a0, 164
	li $a1, 10
	jal DrawSpikeRight
	li $a0, 152
	li $a1, 14
	jal DrawSpikeDown
	
	# spike ball2
	li $a0, 40
	li $a1, 25
	jal DrawSidePlatS
	li $a0, 40
	li $a1, 27
	jal DrawSidePlatS
	li $a0, 48
	li $a1, 25
	jal DrawSidePlatS
	li $a0, 48
	li $a1, 27
	jal DrawSidePlatS
	li $a0, 40
	li $a1, 22
	jal DrawSpikeUp
	li $a0, 28
	li $a1, 26
	jal DrawSpikeLeft
	li $a0, 56
	li $a1, 25
	jal DrawSpikeRight
	li $a0, 44
	li $a1, 29
	jal DrawSpikeDown
	
	# spike ball3
	li $a0, 72
	li $a1, 3
	jal DrawSidePlatS
	li $a0, 72
	li $a1, 5
	jal DrawSidePlatS
	li $a0, 80
	li $a1, 3
	jal DrawSidePlatS
	li $a0, 80
	li $a1, 5
	jal DrawSidePlatS
	li $a0, 72
	li $a1, 0
	jal DrawSpikeUp
	li $a0, 60
	li $a1, 4
	jal DrawSpikeLeft
	li $a0, 88
	li $a1, 3
	jal DrawSpikeRight
	li $a0, 76
	li $a1, 7
	jal DrawSpikeDown
	
	# Draw rest of level
	li $a0, 188
	li $a1, 13
	jal DrawSidePlatM
	li $a0, 0
	li $a1, 10
	jal DrawVertPlatL
	li $a0, 100
	li $a1, 0
	jal DrawSidePlatL
	li $a0, 156
	li $a1, 0
	jal DrawSidePlatL
	li $a0, 212
	li $a1, 0
	jal DrawSidePlatM
	li $a0, 132
	li $a1, 7
	jal DrawSidePlatS
	
	# Draw Hearts
	li $a0, 240
	li $a1, 42
	jal DrawHeart
	
	# Draw Spikes
	li $a0, 80
	li $a1, 53
	jal DrawSpikeUp
	li $a0, 12
	li $a1, 37
	jal DrawSpikeRight
	li $a0, 100
	li $a1, 43
	jal DrawSpikeUp
	li $a0, 112
	li $a1, 43
	jal DrawSpikeUp
	li $a0, 124
	li $a1, 43
	jal DrawSpikeUp
	li $a0, 136
	li $a1, 43
	jal DrawSpikeUp
	li $a0, 148
	li $a1, 43
	jal DrawSpikeUp
	li $a0, 160
	li $a1, 43
	jal DrawSpikeUp
	li $a0, 172
	li $a1, 43
	jal DrawSpikeUp
	li $a0, 184
	li $a1, 43
	jal DrawSpikeUp
	li $a0, 196
	li $a1, 43
	jal DrawSpikeUp
	
	
	li $a0, 180
	li $a1, 25
	jal DrawSpikeLeft
	li $a0, 180
	li $a1, 22
	jal DrawSpikeLeft
	
	li $a0, 196
	li $a1, 30
	jal DrawSpikeRight
	li $a0, 196
	li $a1, 27
	jal DrawSpikeRight
	li $a0, 240
	li $a1, 22
	jal DrawSpikeLeft
	li $a0, 240
	li $a1, 19
	jal DrawSpikeLeft
	li $a0, 196
	li $a1, 15
	jal DrawSpikeRight
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
DrawLevel3:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# init player's coord
	li $t1, PLAYER_SPAWN_LOC
	sw $t1, PlayerCoord
	
	# Draw player
	jal DrawPlayer
	
	# Draw moving plats
	li $a0, 4
	li $a1, 36
	li $a2, 4
	sw $a0, Platform1X
	sw $a1, Platform1Y
	sw $a2, Platform1Dx
	jal DrawSidePlatM
	li $a0, 4
	sw $a0, Platform1MaxShifts
	
	li $a0, 80
	li $a1, 24
	li $a2, 4
	sw $a0, Platform2X
	sw $a1, Platform2Y
	sw $a2, Platform2Dx
	jal DrawSidePlatM
	li $a0, 40
	sw $a0, Platform2MaxShifts
	
	# Draw level
	li $a0, 120
	li $a1, 60
	jal DrawSidePlatM
	
	li $a0, 120
	li $a1, 54
	jal DrawSidePlatL
	li $a0, 176
	li $a1, 54
	jal DrawSidePlatL
	li $a0, 204
	li $a1, 60
	jal DrawSidePlatM
	
	li $a0, 240
	li $a1, 57
	jal DrawHeart
	
	li $a0, 120
	li $a1, 40
	jal DrawSidePlatL
	li $a0, 176
	li $a1, 40
	jal DrawSidePlatL
	li $a0, 228
	li $a1, 40
	jal DrawSidePlatM
	li $a0, 172
	li $a1, 42
	jal DrawSpikeDown
	li $a0, 208
	li $a1, 42
	jal DrawSpikeDown
	li $a0, 132
	li $a1, 42
	jal DrawSpikeDown
	li $a0, 164
	li $a1, 51
	jal DrawSpikeUp
	li $a0, 200
	li $a1, 51
	jal DrawSpikeUp
	li $a0, 116
	li $a1, 50
	jal DrawSidePlatS
	li $a0, 116
	li $a1, 52
	jal DrawSidePlatS
	li $a0, 116
	li $a1, 54
	jal DrawSidePlatS
	
	li $a0, 120
	li $a1, 26
	jal DrawVertPlatL
	li $a0, 108
	li $a1, 30
	jal DrawSpikeLeft
	li $a0, 108
	li $a1, 33
	jal DrawSpikeLeft
	
	li $a0, 20
	li $a1, 60
	jal DrawSidePlatS
	li $a0, 12
	li $a1, 52
	jal DrawSidePlatS
	li $a0, 0
	li $a1, 44
	jal DrawSidePlatM
	li $a0, 0
	li $a1, 36
	jal DrawSidePlatM
	li $a0, 0
	li $a1, 30
	jal DrawSidePlatM
	li $a0, 16
	li $a1, 28
	jal DrawSpikeUp
	
	li $a0, 160
	li $a1, 7
	jal DrawVertPlatL
	li $a0, 160
	li $a1, 21
	jal DrawVertPlatL
	li $a0, 160
	li $a1, 0
	jal DrawVertPlatL
	li $a0, 148
	li $a1, 10
	jal DrawSpikeLeft
	li $a0, 148
	li $a1, 13
	jal DrawSpikeLeft

	li $a0, 168
	li $a1, 22
	jal DrawSpikeRight
	li $a0, 196
	li $a1, 19
	jal DrawSidePlatS
	li $a0, 168
	li $a1, 1
	jal DrawSpikeRight
	
	li $a0, 56
	li $a1, 14
	jal DrawHeart
	li $a0, 240
	li $a1, 30
	jal DrawHeart
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
