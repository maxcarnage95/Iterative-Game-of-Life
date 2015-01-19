	.data
prompt1:	.asciiz		"Welcome to conway's game of life!"
tooltip:	.asciiz		"\nTo begin please start the bitmap display tool, set your unit sizes to 8, your screen size to 512x512, and use the global pointer."
menu:		.asciiz		"\nPlease select a map (choose a number): \n1: Randomized Map \n2: Define your own!\n"
prompt2:	.asciiz		"You have chosen to define your own map. How many cells would you like to seed(1 - 20)? "
prompt3:	.asciiz		"Please enter an x value(1 - 64): "
prompt4:	.asciiz		"Please enter an y value(1 - 64): "
prompt5:	.asciiz		"Your game of life has now started..."
screenWidth:	.word		64
size:		.word		4096
deadColor:	.word		0x00000000
liveColor:	.word		0xffffffff
array:		.space		16384
new_array:	.space		16384
	
	.text
	.globl	main
	
main:	
	
	li	$v0, 4			#Prints the welcome prompt
	la	$a0, prompt1
	syscall
	
	li	$v0, 4			#Tells the user how to set up the bitmap displayt
	la	$a0, tooltip
	syscall
	
	li	$v0, 4			#Gives the user a menu
	la	$a0, menu
	syscall
	
	li	$v0, 5			#Gets the users menu option
	syscall
	
	beq	$v0, 1, randMap		#Allows the user to choose random map or load map
	beq	$v0, 2, zeroMap
	zeroMapEnd:

	li	$v0, 4			#Asks the user how many cells they would like to create
	la	$a0, prompt2
	syscall
	li	$v0, 5			#gets user input and stores it into $s1
	syscall
	move	$s1, $v0
	
	jal	seedMap
	
startPrompt:
	li	$v0, 4			#tells the user that the game has now started
	la	$a0, prompt5
	syscall
	
gameLoop:
	j	check			#Game loop that preforms checks, displays the new array, and swaps arrays for next iteration
	array_traversal_end:
	
	
	j 	displayBitMap
	displayBitMapEnd:
	
	j	swap
	swap_end:
		
	li	$v0, 32			#Force the game to sleep for 10 milliseconds. This helps see the patterns
	li	$a0, 10
	syscall
	j	gameLoop	
	
	
randMap:
	la	$a2, array
	li	$t1, 0
	
	randLoop:
		la	$v0, 42		#generates a random map of ints 0 (inclusive) to 2 (exclusive)
		li	$a1, 2
		syscall
		
		sw	$a0, 0($a2)
		addi	$a2, $a2, 4
		addi	$t1, $t1, 1
		beq	$t1, 4096, startPrompt
		j	randLoop

zeroMap:
	la	$a2, array		#generates a blank map of dead cells
	li	$t1, 0
	li	$t2, 0
	
	zeroLoop:
		
		sw	$t2, 0($a2)
		addi	$a2, $a2, 4
		addi	$t1, $t1, 1
		beq	$t1, 4096, zeroMapEnd
		j	zeroLoop

	
seedMap:	
	li	$v0, 4			#ask for the x value and store in $t1
	la	$a0, prompt3
	syscall
	li	$v0, 5
	syscall
	move	$t1, $v0
	
	subi	$t1, $t1, 1		#column index begins at zero
	
	li	$v0, 4			#ask for the y value and store in $t2
	la	$a0, prompt4
	syscall
	li	$v0, 5
	syscall
	move	$t2, $v0
	
	subi	$t2, $t2, 1		#row index begins at 0
	li	$t3, 64			#the array is 64 X 64
	mult	$t2, $t3
	mflo	$t2			#get the new row value
	
	
	li	$t5, 1			#create an int to seed into array
	la	$t4, array		#load the array address
	add	$t3, $t2, $t1		#get the index of the entered value
	add	$t3, $t3, $t3		#double the index
	add	$t3, $t3, $t3		#quadruple the index to get the byte index
	
	add	$t3, $t3, $t4		#combine the array and index components
	sw	$t5, 0($t3)		#store value of 1 into the array at new index
	
	sub	$s1, $s1, 1		#subtract 1 from the desired amount of entries
	
	bge	$s1, 1, seedMap
	jr	$ra
	

	

displayBitMap:
	lw $a0, screenWidth
	lw $s1, liveColor
	lw $s2, deadColor
	la $a3, new_array
	mul $a2, $a0, $a0 #total number of pixels on screen
	mul $a2, $a2, 4 #align addresses
	add $a2, $a2, $gp #add base of gp
	add $a0, $gp, $zero #loop counter
	
fillLoop:
	beq $a0, $a2, displayBitMapEnd
	lw $t1, 0($a3)
	beq $t1, 0, islive
	beq $t1, 1, isdead
	j fillLoop

islive:
	sw $s1, 0($a0)
	addi $a3, $a3, 4
	addiu $a0, $a0, 4
	j fillLoop
	
isdead:	
	sw $s2, 0($a0)
	addi $a3, $a3, 4
	addiu $a0, $a0, 4
	j fillLoop
	
	

#################################################
# array
# if sum is correct then modify in new_array
# My code goes through array (which is filled in by the user) and new_array
#is the array filled with all 0's
#so it traverses array and if conditions meet it will store 1 to new_array

check:
lw $t3, size
la $t1, array # get array address
li $t2, 0 # set loop counter

array_traversal:

beq $t2, $t3, array_traversal_end # check for array end

#lw $a0, ($t1)#Load the array index 
move $a0,$t2
#load $t4 with 20 to check right edge and left edges using mod,IF MOD IS 0 THEN IT IS LEFT EDGES,19 THEN RIGHT EDGES 
#If none then it has to be a middle case
li $t4,64
rem $t4,$a0,$t4

beq $a0,0,zero
beq $a0,63,top_right_edge
ble $a0,62,top_case
beq $a0,4095,bottom_edge
beq $a0,4032,bottom_left_edge
bge $a0,4033,bottom_case
beq $t4,0,left_edge
beq $t4,63,right_edge
j middle_case

back_from:
addi $t2, $t2, 1 #Advance the counter
addi $t1, $t1, 4 #Advance the address

j array_traversal #repeat the loop
#############################################################
#Calculating adjacent cells in the labels below.....
#Use $s0-$s7 $t4 $t5 $t6 $t7 registers here DO NOT USE $t0 $t1 $t2 $t3
############################################################
zero:
#$t4 is CURRENT CELL 1 0R 0
lw $t4,($t1)
#Count three neighb, $s0 = right neigh,$s1 = bottom,$s3 = diagnonal calculate using $t1 offsets
#HARD CODED 64 * 4 
lw $s0,4($t1)
lw $s1,256($t1)
lw $s2,260($t1)

#Calculate the sum $t5 has the total sum
seq $t5,$s0,1		
seq $t6,$s1,1
seq $t7,$s2,1

add $t5,$t5,$t6																								
add $t5,$t5,$t7

#otherwise it is 0, do calculations below here for dead cell 
beq $t4,1,live

#Dead 2 scenario
beq $t5,3,birth

li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

birth:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

#####
live:
#live 2 scenario
beq $t5,2,survive
beq $t5,3,survive
j will_not_survive

survive:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

will_not_survive:
li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

############################################################
top_case:

#$t4 is CURRENT CELL 1 0R 0
lw $t4,($t1)
#Count five neighb, $s0,$s1,$s2,$s3,$s4
lw $s0,-4($t1)
lw $s1,4($t1)
addi $v0,$a0,64
sll  $v0,$v0,2
la $v1,array
add $v0,$v0,$v1
lw $s2,($v0)
lw $s3,-4($v0)
lw $s4,4($v0)

#Calculate the sum $t5 has the total sum
seq $t5,$s0,1		
seq $v1,$s1,1
seq $v0,$s2,1
seq $t6,$s3,1
seq $t7,$s4,1

add $t5,$v1,$t5																								
add $t5,$t5,$v0
add $t5,$t5,$t6
add $t5,$t5,$t7

#otherwise it is 0, do calculations below here for dead cell 
beq $t4,1,live1

#Dead 2 scenario
beq $t5,3,birth1

li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

birth1:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

#####
live1:
#live 2 scenario
beq $t5,2,survive1
beq $t5,3,survive1
j will_not_survive1

survive1:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

will_not_survive1:
li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from


############################################################
top_right_edge:

#$t4 is CURRENT CELL 1 0R 0
lw $t4,($t1)
#Count three neighb, calculate using $t1 offsets
#HARD CODED 127 *4 and 126 *4
lw $s0,-4($t1)
lw $s1,508($t1)
lw $s2,504($t1)

#Calculate the sum $t5 has the total sum
seq $t5,$s0,1		
seq $t6,$s1,1
seq $t7,$s2,1

add $t5,$t5,$t6																								
add $t5,$t5,$t7

#otherwise it is 0, do calculations below here for dead cell 
beq $t4,1,live2

#Dead 2 scenario
beq $t5,3,birth2

li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

birth2:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

#####
live2:
#live 2 scenario
beq $t5,2,survive2
beq $t5,3,survive2
j will_not_survive2

survive2:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

will_not_survive2:
li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from


############################################################
bottom_left_edge:

#$t4 is CURRENT CELL 1 0R 0
lw $t4,($t1)
#Count three neighb, $s0 = right neigh,$s1 = bottom,$s3 = diagnonal calculate using $t1 offsets
#HARD CODED 4032-64 == 3968 * 4 >> 15872
lw $s0,4($t1)
lw $s1,15872($t1)
lw $s2,15876($t1)

#Calculate the sum $t5 has the total sum
seq $t5,$s0,1		
seq $t6,$s1,1
seq $t7,$s2,1

add $t5,$t5,$t6																								
add $t5,$t5,$t7

#otherwise it is 0, do calculations below here for dead cell 
beq $t4,1,live3

#Dead 2 scenario
beq $t5,3,birth3

li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

birth3:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

#####
live3:
#live 2 scenario
beq $t5,2,survive3
beq $t5,3,survive3
j will_not_survive3

survive3:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

will_not_survive3:
li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

############################################################
bottom_edge:

#$t4 is CURRENT CELL 1 0R 0
lw $t4,($t1)
#Count three neighb, $s0 = right neigh,$s1 = bottom,$s3 = diagnonal calculate using $t1 offsets
#HARD CODED 4095 - 64 == 4031 * 4 >> 16124
lw $s0,-4($t1)
lw $s1,16124($t1)
lw $s2,16120($t1)

#Calculate the sum $t5 has the total sum
seq $t5,$s0,1		
seq $t6,$s1,1
seq $t7,$s2,1

add $t5,$t5,$t6																								
add $t5,$t5,$t7

#otherwise it is 0, do calculations below here for dead cell 
beq $t4,1,live4

#Dead 2 scenario
beq $t5,3,birth4

li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

birth4:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

#####
live4:
#live 2 scenario
beq $t5,2,survive4
beq $t5,3,survive4
j will_not_survive4

survive4:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

will_not_survive4:
li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from


############################################################
bottom_case:

#$t4 is CURRENT CELL 1 0R 0
lw $t4,($t1)
#Count five neighb, $s0,$s1,$s2,$s3,$s4
lw $s0,-4($t1)
lw $s1,4($t1)
addi $v0,$a0,-64
sll  $v0,$v0,2
la $v1,array
add $v0,$v0,$v1
lw $s2,($v0)
lw $s3,-4($v0)
lw $s4,4($v0)

#Calculate the sum $t5 has the total sum
seq $t5,$s0,1		
seq $v1,$s1,1
seq $v0,$s2,1
seq $t6,$s3,1
seq $t7,$s4,1

add $t5,$v1,$t5																								
add $t5,$t5,$v0
add $t5,$t5,$t6
add $t5,$t5,$t7

#otherwise it is 0, do calculations below here for dead cell 
beq $t4,1,live5

#Dead 2 scenario
beq $t5,3,birth5

li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

birth5:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

#####
live5:
#live 2 scenario
beq $t5,2,survive5
beq $t5,3,survive5
j will_not_survive5

survive5:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

will_not_survive5:
li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

############################################################
left_edge:

#$t4 is CURRENT CELL 1 0R 0
lw $t4,($t1)
#Count five neighb, $s0,$s1,$s2,$s3,$s4
lw $s0,4($t1)
addi $v0,$a0,64
sll  $v0,$v0,2
la $v1,array
add $v0,$v0,$v1
lw $s1,($v0)
lw $s2,4($v0)

addi $v0,$a0,-64
sll $v0,$v0,2
la $v1,array
add $v0,$v0,$v1
lw $s3,($v0)
lw $s4,4($v0)

#Calculate the sum $t5 has the total sum
seq $t5,$s0,1		
seq $t6,$s1,1
seq $t7,$s2,1
seq $v0,$s3,1
seq $v1,$s4,1

add $t5,$t5,$t6																								
add $t5,$t5,$t7
add $t5,$t5,$v0
add $t5,$t5,$v1

#otherwise it is 0, do calculations below here for dead cell 
beq $t4,1,live6

#Dead 2 scenario
beq $t5,3,birth6

li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

birth6:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

#####
live6:
#live 2 scenario
beq $t5,2,survive6
beq $t5,3,survive6
j will_not_survive6

survive6:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

will_not_survive6:
li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from


############################################################
right_edge:

#$t4 is CURRENT CELL 1 0R 0
lw $t4,($t1)
#Count five neighb, $s0,$s1,$s2,$s3,$s4
lw $s0,-4($t1)
addi $v0,$a0,64
sll  $v0,$v0,2
la $v1,array
add $v0,$v0,$v1
lw $s1,($v0)
lw $s2,-4($v0)

addi $v0,$a0,-64
sll $v0,$v0,2
la $v1,array
add $v0,$v0,$v1
lw $s3,($v0)
lw $s4,-4($v0)

#Calculate the sum $t5 has the total sum
seq $t5,$s0,1		
seq $t6,$s1,1
seq $t7,$s2,1
seq $v0,$s3,1
seq $v1,$s4,1


add $t5,$t5,$t6																								
add $t5,$t5,$t7
add $t5,$t5,$v0
add $t5,$t5,$v1

#otherwise it is 0, do calculations below here for dead cell 
beq $t4,1,live7

#Dead 2 scenario
beq $t5,3,birth7

li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

birth7:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

#####
live7:
#live 2 scenario
beq $t5,2,survive7
beq $t5,3,survive7
j will_not_survive7

survive7:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

will_not_survive7:
li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from


############################################################
middle_case:

#$t4 is CURRENT CELL 1 0R 0
lw $t4,($t1)
#Count eight neighb, $s0,$s1,$s2,$s3,$s4
lw $s0,-4($t1)
lw $s1,4($t1)
addi $v0,$a0,-64
sll  $v0,$v0,2
la $v1,array
add $v0,$v0,$v1
lw $s2,($v0)
lw $s3,-4($v0)
lw $s4,4($v0)
addi $v0,$a0,64
sll  $v0,$v0,2
la $v1,array
add $v0,$v0,$v1
lw $s5,($v0)
lw $s6,4($v0)
lw $s7,-4($v0)

#Calculate the sum $t5 has the total sum
seq $t5,$s0,1		
seq $t6,$s1,1
seq $t7,$s2,1
seq $v0,$s3,1
seq $v1,$s4,1
seq $a1,$s5,1
seq $a2,$s6,1
seq $a3,$s7,1

add $t5,$t5,$t6																								
add $t5,$t5,$t7
add $t5,$t5,$v0
add $t5,$t5,$v1
add $t5,$t5,$a1
add $t5,$t5,$a2
add $t5,$t5,$a3

#otherwise it is 0, do calculations below here for dead cell 
beq $t4,1,live8

#Dead 2 scenario
beq $t5,3,birth8

li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

birth8:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

#####
live8:
#live 2 scenario
beq $t5,2,survive8
beq $t5,3,survive8
j will_not_survive8

survive8:
li $a3,1
sll $a0,$a0,2
la $a1,new_array
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from

will_not_survive8:
li $a3,0
la $a1,new_array
sll $a0,$a0,2
add $a0,$a0,$a1
sw $a3,0($a0)

j back_from


############################
# swap

swap:
#swap then jump to array traversal again
lw $t3, size

la $t1, new_array # get array address

li $t2, 0 # set loop counter

la $t5,array

swap_loop:

beq $t2, $t3, check # check for array end

#FIRST LOAD THE ELEMENT AT new_array INTO array
lw $s0,($t1)
sw $s0,($t5)
#NEXT FILL THAT new_array WITH 0'S
li $s2,0
sw $s2,($t1)

addi $t2, $t2, 1 #Advance the counter
addi $t1, $t1, 4 #Advance the address for new_array
addi $t5,$t5,4 #Advance the address for array

j swap_loop #repeat the loop
