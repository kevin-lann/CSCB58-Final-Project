#####################################################################
#
# CSCB58 Summer 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Kevin Lan, 1009407143, lankevin, k.lan@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
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

.eqv PLAT_BASE_COLOR	0x22336D
.eqv PLAT_LIGHT_COLOR	0x637AD4
.eqv PLAT_DARK_COLOR	0x192858
.eqv PLAT_HIGHLIGHT_COLOR 0x9595EF

.eqv HEART_BASE_COLOR 	0xD22552
.eqv HEART_DARK_COLOR	0x7C132E
.eqv HEART_ICON_BASE_COLOR 	0xFF4488
.eqv HEART_ICON_DARK_COLOR	0x81134E
.eqv GOLD_HEART_ICON_BASE_COLOR 0xD8C65A
.eqv GOLD_HEART_ICON_DARK_COLOR	0x80693D

.eqv SPIKE_BASE_COLOR 	0xC7C4B8
.eqv SPIKE_DARK_COLOR	0x86847A

# dimensions
.eqv WIDTH		128	
.eqv HEIGHT		256
.eqv WIDTH_ACT		256	# actual width by px
.eqv HEIGHT_ACT		512	# actual height by px
.eqv TOTAL_PIXELS	8192

# timing
.eqv REFRESH_RATE	60
.eqv GRAVITY_RATE	2	# gravity acts once per GRAVITY_RATE frames

# player attributes
.eqv PLAYER_HEIGHT	4
.eqv PLAYER_WIDTH	3
.eqv PLAYER_DEFAULT_DX  4	
.eqv PLAYER_DEFAULT_DY 	-2 	
.eqv PLAYER_SPAWN_LOC	7232	# x = 64, y = 56
.eqv PLAYER_DEFAULT_HP	3
.eqv PLAYER_MAX_HP	4

# Game constants
.eqv GRAVITY_DY		1
.eqv JUMPING_DY		-1


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

.text

.globl main

main:

	# Reset Game variables
	sw $zero, PlayerDx
	sw $zero, PlayerDy
	sw $zero, PlayerState
	sw $zero, GravityTicks
	sw $zero, Jumps
	li $t0, 11
	sw $t0, PlayerJumpHeight
	li $t0, PLAYER_DEFAULT_HP
	sw $t0, PlayerHP
	sw $t0, CurrentHearts
	
	li $t0, BASE_ADDR
	
	# init player's coord
	li $t1, PLAYER_SPAWN_LOC
	sw $t1, PlayerCoord
	
	# Draw player
	jal DrawPlayer
	
	# Draw plats
	li $a0, 56
	li $a1, 60
	jal DrawPlat1
	
	li $a0, 4
	li $a1, 52
	jal DrawPlat1
	
	li $a0, 40
	li $a1, 42
	jal DrawPlat1
	
	#draw hearts
	li $a0, 12
	li $a1, 48
	jal DrawHeart
	li $a0, 64
	li $a1, 50
	jal DrawHeart
	
	#draw spikes
	li $a0, 48
	li $a1, 39
	jal DrawSpikeUp
	
	# draw HP hearts
	li $a0, 112
	li $a1, 7
	jal DrawHeartIcon
	li $a0, 112
	li $a1, 4
	jal DrawHeartIcon
	li $a0, 112
	li $a1, 1
	jal DrawHeartIcon
	


# ----------- Game Loop -------------- #
GameLoop:
	# check lose
	jal CheckLose
	# check win
	# jal CheckWin
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

	
# Do gravity / jumping stuff
	lw $t3, PlayerState
	lw $t2, GravityTicks
	bne $t2, GRAVITY_RATE, END_GRAVITY
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

CheckJump: # checks if player able to jump. Requires player to be over platform and for current PlayerState
	# to be 0. Changes PlayerState to 1 if can jump
	lw $t4, PlayerState
	bne $zero, $t4, CHECK_JUMP_END	# if PlayerState is not 0, then cannot jump
	lw $t4, PlayerCoord
	add $t4, $t4, BASE_ADDR
	addi $t4, $t4, 512	# 1 row below player
	lw $t5, 0($t4)
	beq $t5, PLAT_LIGHT_COLOR, CAN_JUMP
	lw $t5, 4($t4)
	beq $t5, PLAT_LIGHT_COLOR, CAN_JUMP
	lw $t5, 8($t4)
	beq $t5, PLAT_LIGHT_COLOR, CAN_JUMP
	sw $zero, PlayerState # no jump
	j CHECK_JUMP_END
CAN_JUMP:
	li $t4, 1
	sw $t4, PlayerState # jump
CHECK_JUMP_END:
	jr $ra
	
CheckLose:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	lw $t0, PlayerHP
	beq $t0, 0, LOSE
	lw $t0, PlayerCoord
	li $t1, TOTAL_PIXELS
	bgt $t0, $t1, LOSE
	j NO_LOSE
LOSE:
	j LoseScreen
NO_LOSE:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
CheckWin:

NO_WIN:
	jr $ra



# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ GAME SCREENS ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

LoseScreen:
	# no need to store ra here
	# Draw Skull and Crossbones
	
	li $t1, 0xFFFFFF
	li $t2, HEART_DARK_COLOR
	
	li $t0, BASE_ADDR
	addi $t0, $t0, 384
	addi $t0, $t0, 44
	
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
	
	# Draw "P"
	addi $t0, $t0, 260
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t2, 20($t0)
	sw $t2, 24($t0)
	addi $t0, $t0, WIDTH
	li $t1, 0xFFFFFF
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
HandleKeyD:
	bne $t0, 0x64, HandleKeyP
	sw $t1, PlayerDx	# set PlayerDy to default Dx (Rightwards)
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
	addi $t4, $t4, 120
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 8
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 120
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 8
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerX
	addi $t4, $t4, 120
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
	addi $t4, $t4, 384
	lw $t1, 0($t4)	# 4th row
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, 4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, 4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -128
	lw $t1, 0($t4)	# 3rd row
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -128
	lw $t1, 0($t4)	# 2nd row
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, 4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, 4
	lw $t1, 0($t4)
	bne $t1, 0, CollisionHandlerY
	addi $t4, $t4, -128
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
	sw $t1, 12($t0)
	
	addi $t0, $t0, WIDTH	#3rd row
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t1, 16($t0)
	
	jr $ra

# Params: int x, int y
DrawPlat1:
	li $t0, BASE_ADDR
	li $t2, PLAT_LIGHT_COLOR
	
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
	
	addi $a0, $a0, -264
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
	
	addi $a0, $a0, 128
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
	
	addi $a0, $a0, 128
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
	
	addi $a0, $a0, 128
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
	
	addi $a0, $a0, 128
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
	
	addi $a0, $a0, 128
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
	
	addi $a0, $a0, 128
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
	
	addi $a0, $a0, 128
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
	addi $t0, $t0, 112	# first heart
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
	li $a0, 112
	li $a1, 10
	jal DrawGoldHeartIcon
DrawHP3: # 3 HP
	blt $t2, 3, DrawHP2
	li $a0, 112
	li $a1, 7
	jal DrawHeartIcon
DrawHP2: # 2 HP
	blt $t2, 2, DrawHP1
	li $a0, 112
	li $a1, 4
	jal DrawHeartIcon
DrawHP1: # 1 HP
	blt $t2, 1, NO_DRAW_HP
	li $a0, 112
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
	# check for divisibility by 128
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
	# check for divisibility by 128 after adding 4
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

