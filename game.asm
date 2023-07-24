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
.eqv REFRESH_RATE	30

# player attributes
.eqv PLAYER_HEIGHT	4
.eqv PLAYER_WIDTH	3

# Game constants

.data

newLine: .asciiz 	"\n"

PlayerDx: .word		0	# player speed in x direc (0 means stationary)
PlayerDy: .word		0	# player speed in y direc (0 means stationary)
PlayerJumpHeight: .word	11	# no. pixels able to be jumped by player
PlayerCoord: .word	0	# player coordinate on screen ( which is its address in memory)

.text

.globl main

main:
	li  $t0, BASE_ADDR
	
	# Draw player
	
	li $a0, 64
	li $a1, 56
	
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
	
GameLoop:
	
	# check keypress

	
	
ENDMAIN:
	li $v0, 10	# terminate
	syscall







# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ KEY HANDLER ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

HandleKeypress:
	li $t0, KEYBOARD_ADDR
	lw $t0, 0($t0)		# load the key
HandleKeyW:
	
HandleKeyA:

HandleKeyS:

HandleKeyD:

# ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ DRAW GAME OBJECTS ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

# Params: int x, int y
DrawPlayer:
	li $t0, BASE_ADDR
	
	li $t1, PLAYER_BASE_COLOR
	li $t2, PLAYER_EYE_COLOR
	li $t3, PLAYER_DARK_COLOR
	
	# set up addr at the coords (x,y)
	move $t4, $a0
	move $t5, $a1
	li $t6, WIDTH
	mult $t5, $t6
	mflo $t5
	add $t4, $t5, $t4
	
	add $t0, $t0, $t4	#1st row
	sw $t3, 0($t0)
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
	sw $t3, 0($t0)
	sw $t2, 4($t0)
	sw $t3, 8($t0)
	sw $t2, 12($t0)
	sw $t3, 16($t0)
	sw $t2, 20($t0)
	sw $t3, 24($t0)
	
	li $t3, PLAT_DARK_COLOR
	
	add $t0, $t0, WIDTH	#2nd row
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t3, 16($t0)
	sw $t3, 20($t0)
	sw $t1, 24($t0)
	
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

