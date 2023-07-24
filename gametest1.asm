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
.eqv RED		0xff0000
.eqv GREEN		0x21ff90
.eqv BLUE		0x175CDC

# dimensions
.eqv WIDTH		128	
.eqv HEIGHT		256
.eqv WIDTH_ACT		256	# actual width by px
.eqv HEIGHT_ACT		512	# actual height by px

# timing
.eqv REFRESH_RATE	100

# Game constants

.data

newline: .asciiz 	"\n"

.text

.globl main

main:
	li $t0, BASE_ADDR
	
	li $t1, RED
	li $t2, GREEN
	li $t3, BLUE
	
	# set up addr at the center
	li $t9, WIDTH
	li $t8, 32
	mult $t9, $t8
	mflo $t9
	addi $t9, $t9, 0
	
	add $t0, $t0, $t9		#1st row
	sw $t3, 0($t0)
	sw $t2, 4($t0)
	
	addi $t0, $t0, WIDTH	#2nd row
	sw $t2, 0($t0)
	sw $t3, 4($t0)
	
	# sleep for a moment
	li $v0, 32
	li $a0, 1000
	syscall
	
LOOPR:	# MOVE RIGHT >>>>>>>>>>>>>>>

	# sleep for a bit
	li $v0, 32
	li $a0, REFRESH_RATE
	syscall
	
	# clear prev
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	subi $t0, $t0, WIDTH 	# 1st row now
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	
	# draw new (shifted right)
	addi $t0, $t0, 4	#1st row
	sw $t3, 0($t0)
	sw $t2, 4($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $t2, 0($t0)
	sw $t3, 4($t0)
	
	# check if hit right
	subi $t9, $t0, BASE_ADDR # get offset from base addr
	move $a0, $t9
	addi $a0, $a0, 4	# have to make sure we are checking the rightmost edge
	
	jal HitRightBorder
	
	beq $v0, $zero, NOSWITCHR
	j LOOPL			# switch to moving left if we hit right side
NOSWITCHR:
	j LOOPR			# cont loop if didnt hit right side yet
	
	
LOOPL:	# MOVE LEFT <<<<<<<<<<<<<<<<

	# sleep for a bit
	li $v0, 32
	li $a0, REFRESH_RATE
	syscall
	
	# clear prev
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	subi $t0, $t0, WIDTH 	# 1st row now
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	
	# draw new (shifted left)
	subi $t0, $t0, 4	#1st row
	sw $t3, 0($t0)
	sw $t2, 4($t0)
	addi $t0, $t0, WIDTH	#2nd row
	sw $t2, 0($t0)
	sw $t3, 4($t0)
	
	# check if hit left
	subi $t9, $t0, BASE_ADDR # get offset from base addr
	move $a0, $t9
	
	jal HitLeftBorder
	
	beq $v0, $zero, NOSWITCHL
	j LOOPR			# switch to moving right if we hit left side
NOSWITCHL:
	j LOOPL			# cont loop if didnt hit left side yet
	
	
ENDMAIN:
	li $v0, 10	# terminate
	syscall



##########################################################################
##				FUNCTIONS				##
##########################################################################



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

