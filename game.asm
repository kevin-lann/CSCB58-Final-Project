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

# dimensions
.eqv WIDTH		128	
.eqv HEIGHT		256
.eqv WIDTH_ACT		256	# actual width by px
.eqv HEIGHT_ACT		512	# actual height by px

# timing
.eqv REFRESH_RATE	60
.eqv GRAVITY_RATE	4	# gravity acts once per GRAVITY_RATE frames

# player attributes
.eqv PLAYER_HEIGHT	4
.eqv PLAYER_WIDTH	3
.eqv PLAYER_DEFAULT_DX  4	
.eqv PLAYER_DEFAULT_DY 	-2 	
.eqv PLAYER_SPAWN_LOC	7232	# x = 64, y = 56

# Game constants
.eqv GRAVITY_DY		1


.data

newLine: .asciiz 	"\n"
Pressed: .asciiz	"Press\n"

PlayerDx: .word		0	# player speed in x direc (0 means stationary)
PlayerDy: .word		0	# player speed in y direc (0 means stationary)
PlayerJumpHeight: .word	11	# no. pixels able to be jumped by player
PlayerCoord: .word	0	# player coordinate on screen ( which is its address in memory)

GravityTicks: .word	0	# counter for gravity

.text

.globl main

main:
	li  $t0, BASE_ADDR
	
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


# ----------- Game Loop -------------- #
GameLoop:
	
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
	beq $t3, 0, END_MOVE	# Dy = 0
	jal MovePlayerY
	
END_MOVE:
	lw $t2, GravityTicks
	bne $t2, GRAVITY_RATE, END_GRAVITY
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
	
	li $v0, 32
	li $a0, REFRESH_RATE
	syscall
	
	j GameLoop
# ----------- Game Loop -------------- #
	
ENDMAIN:
	li $v0, 10	# terminate
	syscall







# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ KEY HANDLER ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

HandleKeypress:
	li $t0, KEYBOARD_ADDR
	li $t1, PLAYER_DEFAULT_DX
	li $t2, PLAYER_DEFAULT_DY
	li $t3, -1
	lw $t0, 4($t0)		# load the key
HandleKeyW:
	bne $t0, 0x77, HandleKeyA
	sw $t2, PlayerDy	# set PlayerDy to default Dy (upwards)
HandleKeyA:
	bne $t0, 0x61, HandleKeyS
	mult $t1, $t3
	mflo $t1
	sw $t1, PlayerDx	# set PlayerDx to default Dx (leftwards)
HandleKeyS:
	bne $t0, 0x73, HandleKeyD
	mult $t2, $t3
	mflo $t2
	sw $t2, PlayerDy	# set PlayerDx to default Dx (rightwards)
HandleKeyD:
	bne $t0, 0x64, HandleKeypressExit
	sw $t1, PlayerDx	# set PlayerDy to default Dy (downwards)
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
	beq $t1, 0, NoMoveX
	add $t0, $t0, $t1
	
	# check for collisions between borders
	subi $t1, $t0, BASE_ADDR	# get offset
	move $a0, $t1
	jal HitLeftBorder
	beq $v0, 1, NoMoveX
	
	subi $t1, $t0, BASE_ADDR	# get offset
	addi $t1, $t1, 8
	move $a0, $t1
	jal HitRightBorder
	beq $v0, 1, NoMoveX
	
	# check for coliisions between sides of platforms
	li $t4, BASE_ADDR
	add $t4, $t4, $t0
	lw $t1, 0($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 128($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 256($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 384($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	
	lw $t1, 8($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 136($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 264($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 392($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	
	# update new coord
	sw $t0, PlayerCoord
	
NoMoveX: 
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
	beq, $t1, 0, NoMoveY	# check if Dy is 0
	li $t2, WIDTH
	mult $t1, $t2
	mflo $t1
	add $t0, $t0, $t1
	
	# check if hit plats
	li $t4, BASE_ADDR
	add $t4, $t4, $t0
	lw $t1, 384($t4)	# 4th row
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 388($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 392($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 256($t4)	# 3rd row
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 260($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 264($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 128($t4)	# 2nd row
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 132($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 136($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 0($t4)	# top row of player
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 4($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	lw $t1, 8($t4)
	beq $t1, PLAT_LIGHT_COLOR, NoMoveY
	
	# store new coord
	sw $t0, PlayerCoord

NoMoveY:
	# Redraw 
	jal DrawPlayer
	
	#pop old ra back
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# move by PlayerDy
MovePlayerY2:
	# put old ra into stack first
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# remove prev player 
	jal ClearPlayer
	
	lw $t0, PlayerCoord
	
	# Update playercoord
	lw $t1, PlayerDy
	li $t2, WIDTH
	mult $t1, $t2
	mflo $t1
	add $t0, $t0, $t1
	
	# check for collisions between borders
	subi $t1, $t0, BASE_ADDR	# get offset
	move $a0, $t1
	# addi $a0, $a0, 8 		# make sure checking the rightmost edge
	jal HitTopBorder
	beq $v0, 1, NoMoveY2
	
	#li $t1, WIDTH
	#li $t2, 3
	#mult $t2, $t1
	#mflo $t1
	#add $t1, $t0, $t1
	#subi $t1, $t1, BASE_ADDR	# get offset
	#move $a0, $t1
	#jal HitBottomBorder
	#beq $v0, 1, NoMoveY2
	
	# store new coord
	sw $t0, PlayerCoord

NoMoveY2:
	# Redraw 
	jal DrawPlayer

	li $v0, 1
	li $a0, 0
	syscall
	#pop old ra back
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
DrawPlat1:
	li $t0, BASE_ADDR
	
	li $t1, PLAT_BASE_COLOR
	li $t2, PLAT_LIGHT_COLOR
	li $t3, PLAT_HIGHLIGHT_COLOR
	
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

