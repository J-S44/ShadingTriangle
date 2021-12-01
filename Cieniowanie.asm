	.data
	.align 4
size: 	.space 4 #dane do wczytania obrazka
empty:	.space 4
offset: .space 4
width: 	.space 4
height:	.space 4
address:	.space 4
padding:	.space 4
zpadding:	.space 4
coords:	.space 24 # tablica wspolrzednych
red:	.space 3 # tablice kolorów
green: .space 3
blue: .space 3


fname: .asciiz "src.bmp"
outname: .asciiz "out.bmp"


PromptDef: 	.ascii "Algorytm cieniujacy trojkat\n"
		.asciiz "Autor: Jakub Sarna\n"

PromptX: .asciiz "Podaj wspolrzedna X: \n"
PromptY: .asciiz "Podaj wspolrzedna Y: \n"
PromptR: .asciiz "Podaj kolor czerwony (0 - 255): \n"
PromptG: .asciiz "Podaj kolor zielony (0 - 255): \n"
PromptB: .asciiz "Podaj kolor niebieski (0 - 255): \n"

InputError: .asciiz "Podano zle dane"
FileError: .asciiz "Podano zly plik"

	.text
	.globl main
main:
### SHADING TRIANGLE PROGRAM
### USING BARYCENTRIC COORIDNATES

read_file_data:
	li $v0, 13	#open
	la $a0, fname	
	li $a1, 0
	li $a2, 0
	syscall
	
	move $t0, $v0 # $t0 - file descriptor!!!!
	bltz $t0, file_error
	
	# saving important BMP data #
	li $v0, 14
	move $a0, $t0
	la $a1, empty	#everything in empty doesn't matter for the program
	li $a2, 2
	syscall
	
	li $v0, 14
	move $a0, $t0
	la $a1, size
	li $a2, 4
	syscall
	lw $t1, size
	
	li $v0, 9
	move $a0, $t1
	syscall
	move $s0, $v0  # $s0 - FILE ADDRESS
	la $s1, address
	sw $s0, ($s1)
	
	li $v0, 14
	move $a0, $t0
	la $a1, empty
	li $a2, 4
	syscall
	
	li $v0, 14
	move $a0, $t0
	la $a1, offset
	li $a2, 4
	syscall
	
	li $v0, 14
	move $a0, $t0
	la $a1, empty
	li $a2, 4
	syscall
	
	li $v0, 14
	move $a0, $t0
	la $a1, width
	li $a2, 4
	syscall
	
	li $v0, 14
	move $a0, $t0
	la $a1, height
	li $a2, 4
	syscall
	
	li $v0, 16
	move $a0, $t0
	syscall

read_file_content:

	li $v0, 13
	la $a0, fname
	li $a1, 0
	li $a2, 0
	syscall
	
	move $t0, $v0
	bltz $t0, file_error
	
	lw $t1, size
	
	li $v0, 14
	move $a0, $t0
	la $a1, ($s0)
	la $a2, ($t1)
	syscall
	
	li $v0, 16
	move $a0, $t0
	syscall
	
	lw $t3, width
	
	lw $t0, offset
	add $t0, $s0, $t0 # t0 = adress + offset
	move $t5, $t3
	sll $t1, $t3, 1
	add $t1, $t1, $t5 # ssl and add is quicker than multiplication
	li $t4, 0x4
	and $t1, $t1, 0x3
	#div $t1, $t4 # POPRAWIC NA AND 0X3
	#mfhi $t1
	beqz $t1, zero_padding
	li $t2, 4
	sub $t1, $t2, $t1
	
zero_padding:
	# this part of code calculates padding offset, as well as (width * 3) + padding
	sll $t3, $t3, 1
	add $t3, $t3, $t5
	add $t3, $t3, $t1
	sw $t3, zpadding
	sw $t1, padding
	
	li $t3, 1
	li $t7, 1
	lw $t0, offset
	add $t0, $s0, $t0
	
	#load arrays for read
	li $t0, 2
	la $t1, coords
	la $t2, red
	la $t3, green
	la $t4, blue

welcome:
	li $v0, 4
	la $a0, PromptDef
	syscall
	
get_inputs:

	
	li $v0, 4
	la $a0, PromptX
	syscall
	li $v0, 5
	syscall
	sw $v0, ($t1)
	addi $t1, $t1, 4
	
	li $v0, 4
	la $a0, PromptY
	syscall
	li $v0, 5
	syscall
	sw $v0, ($t1)
	addi $t1, $t1, 4
	
	li $v0, 4
	la $a0, PromptR
	syscall
	li $v0, 5
	syscall
	sb $v0, ($t2)
	addi $t2, $t2, 1
	
	li $v0, 4
	la $a0, PromptG
	syscall
	li $v0, 5
	syscall
	sb $v0, ($t3)
	addi $t3, $t3, 1
	
	li $v0, 4
	la $a0, PromptB
	syscall
	li $v0, 5
	syscall
	sb $v0, ($t4)
	addi $t4, $t4, 1
	
	beqz $t0, load_cords
	subi $t0, $t0, 1
	
	b get_inputs

load_cords:
	la $t0, coords
	lw $t1, ($t0)
	lw $t2, 8($t0)
	lw $t3, 16($t0)
	lw $t4, 4($t0)
	lw $t5, 12($t0)
	lw $t6, 20($t0)
	
calculate_min: # calculate lowest possible point (xmin, ymin)
	blt $t1, $t2, cmin1
	blt $t2, $t3, cmin2
	move $a0, $t3
	b cmin4
cmin1:
	blt $t1, $t3, cmin3
	move $a0, $t3
	b cmin4
cmin2:
	move $a0, $t2
	b cmin4
cmin3:
	move $a0, $t1
cmin4:
	blt $t4, $t5, cmin5
	blt $t5, $t6, cmin6
	move $a1, $t6
	b calculate_max
cmin5:
	blt $t4, $t6, cmin7
	move $a1, $t6
	b calculate_max
cmin6:
	move $a1, $t5
	b calculate_max
cmin7:
	move $a1, $t4
	
	
calculate_max: #calculate highest possible point (xmax, ymax)
	bgt $t1, $t2, cmax1
	bgt $t2, $t3, cmax2
	move $a2, $t3
	b cmax4
cmax1:
	bgt $t1, $t3, cmax3
	move $a2, $t3
	b cmax4
cmax2:
	move $a2, $t2
	b cmax4
cmax3:
	move $a2, $t1
cmax4:
	bgt $t4, $t5, cmax5
	bgt $t5, $t6, cmax6
	move $a3, $t6
	b count_minmax_values
cmax5:
	bgt $t4, $t6, cmax7
	move $a3, $t6
	b count_minmax_values
cmax6:
	move $a3, $t5
	b count_minmax_values
cmax7:
	move $a3, $t4

count_minmax_values:
	# calculates boundaries for iterating
	lw $t0, zpadding
	mul $a0, $a0, 3
	mul $a2, $a2, 3
	mul $a1, $a1, $t0
	mul $a3, $a3, $t0
	
	add $a1, $a0, $a1 # lower limit of possible points
	add $a3, $a2, $a3
	add $a3, $a3, $a0 # upper limit of possible points
	
	lw $s7, zpadding # move between rows
	sub $s7, $s7, $a2
	add $s7, $s7, $a0
	subi $s7, $s7, 3
	
draw_start:
	lw $t0, address
	lw $t1, offset
	add $t0, $t0, $t1 # get address + offset = pointer
	add $t9, $t0, $a3 # set the upper limit
	move $t8, $a2
	addi $t8, $t8, 2
	add $t0, $t0, $a1 # set pointer at the lowest limit
	move $t1, $a0 # set bit counter to start
	#load data
	la $s0, coords
	la $s3, blue
	la $s4, green
	la $s5, red
	### RESERVED REGISTERS:
	### T0, T1 T9, T8, S0, S3, S4, S5, A0
	# T0 = CURRENT POSITION
	# T1 = BIT COUNTER
	# T9 = UPPER LIMIT
	# T8 = ROW LIMIT
	# A0 = ROW START
	# S0, S3, S4, S5 - DATA
iter:
edges:
	
	lw $t3, zpadding
	lw $t4, address
	sub $t6, $t0, $t4
	lw $t4, offset
	sub $t6, $t6, $t4
	div $t6, $t3
	mflo $s2
	mfhi $s1
	li $t4, 3
	div $s1, $t4
	mflo $s1 # s1 -> current x, s2 -> current y
	
	#loading coordinates
	lw $a3, ($s0)
	lw $t2, 8($s0)
	lw $t3, 16($s0)
	lw $t4, 4($s0)
	lw $t5, 12($s0)
	lw $t6, 20($s0)
	
	# cross produkt of pc, p1, p2
	sub $t7, $s1, $a3
	sub $s6, $t5, $t4
	mul $t7, $t7, $s6
	sub $s6, $t2, $a3
	sub $a1, $s2, $t4
	mul $s6, $s6, $a1
	sub $a1, $t7, $s6
	
	# cross produkt of pc, p2, p3
	sub $t7, $s1, $t2
	sub $s6, $t6, $t5
	mul $t7, $t7, $s6
	sub $s6, $t3, $t2
	sub $a2, $s2, $t5
	mul $s6, $s6, $a2
	sub $a2, $t7, $s6
	
	# cross produkt of pc, p3, p1
	sub $t7, $s1, $t3
	sub $s6, $t4, $t6
	mul $t7, $t7, $s6
	sub $s6, $a3, $t3
	sub $a3, $s2, $t6
	mul $s6, $s6, $a3
	sub $a3, $t7, $s6
	
	#mul $a1, $a1, $a2
	#mul $a1, $a1, $a3
pos_check_neg:
	bgtz $a1, pos_check_pos
	bgtz $a2, pos_check_pos
	bgtz $a3, pos_check_pos
	
	mul $a1, $a1, -1
	mul $a2, $a2, -1
	mul $a3, $a3, -1
	srl $a3, $a3, 1
	srl $a2, $a2, 1
	srl $a1, $a1, 1
	add $s6, $a1, $a2
	add $s6, $s6, $a3
	b draw
pos_check_pos:
	bltz $a1, next
	bltz $a2, next
	bltz $a3, next

	srl $a3, $a3, 1
	srl $a2, $a2, 1
	srl $a1, $a1, 1	
	add $s6, $a1, $a2
	add $s6, $s6, $a3
	b draw
next:
	bgt $t1, $t8, new_row
	bgt $t0, $t9, save_file
	
	addi $t1, $t1, 3
	addi $t0, $t0, 3
	

	#and $t5, $a1, 0x00000000
	#bge $t5, 0x00000000, draw
	#li $v0, 1
	#move $a0, $t3
	#syscall
	b iter
draw: 

	#BLUE
	li $t6, 0
	lb $t4, 2($s3)
	sll $t4, $t4, 24
	srl $t4, $t4, 24
	#mtc1 $t4, $f0  # float version, more accurate. ASK ABOUT SPACE REQUIREMENTS
	#mtc1 $s6, $f1
	#mtc1 $a1, $f2
	#cvt.s.w $f0, $f0
	#cvt.s.w $f1, $f1
	#cvt.s.w $f2, $f2
	#div.s $f1, $f2, $f1
	#mul.s $f0, $f0, $f1
	#cvt.w.s $f0, $f0
	#mfc1 $t5, $f0
	mul $t5, $a1, $t4
	div $t5, $s6
	mflo $t5
	add $t6, $t6, $t5
	
	
	lb $t4, ($s3)
	sll $t4, $t4, 24
	srl $t4, $t4, 24
	mul $t5, $a2, $t4
	div $t5, $s6
	mflo $t5
	add $t6, $t6, $t5
	
	lb $t4, 1($s3)
	sll $t4, $t4, 24
	srl $t4, $t4, 24
	mul $t5, $a3, $t4
	div $t5, $s6
	mflo $t5
	add $t6, $t6, $t5
	
	sb $t6, ($t0)
	
	
	#GREEN
	li $t6, 0
	lb $t4, 2($s4)
	sll $t4, $t4, 24
	srl $t4, $t4, 24
	mul $t5, $a1, $t4
	div $t5, $s6
	mflo $t5
	add $t6, $t6, $t5
	
	lb $t4, ($s4)
	sll $t4, $t4, 24
	srl $t4, $t4, 24
	mul $t5, $a2, $t4
	div $t5, $s6
	mflo $t5
	add $t6, $t6, $t5
	
	lb $t4, 1($s4)
	sll $t4, $t4, 24
	srl $t4, $t4, 24
	mul $t5, $a3, $t4
	div $t5, $s6
	mflo $t5
	add $t6, $t6, $t5
	
	sb $t6, 1($t0)
	
	#RED
	li $t6, 0
	lb $t4, 2($s5)
	sll $t4, $t4, 24
	srl $t4, $t4, 24
	mul $t5, $a1, $t4
	div $t5, $s6
	mflo $t5
	add $t6, $t6, $t5
	
	lb $t4, ($s5)
	sll $t4, $t4, 24
	srl $t4, $t4, 24
	mul $t5, $a2, $t4
	div $t5, $s6
	mflo $t5
	add $t6, $t6, $t5
	
	lb $t4, 1($s5)
	sll $t4, $t4, 24
	srl $t4, $t4, 24
	mul $t5, $a3, $t4
	div $t5, $s6
	mflo $t5
	add $t6, $t6, $t5
	sb $t6, 2($t0)
	
	li $t4, 0

	
	bgt $t1, $t8, new_row
	bgt $t0, $t9, save_file
	
	addi $t1, $t1, 3
	addi $t0, $t0, 3
	
	b iter
new_row:
	add $t0, $t0, $s7 # go to new row's starting position on t0
	move $t1, $a0 # set row counter to start pos
	b iter
save_file:
	li $v0, 13
	la $a0, outname
	li $a1, 1
	li $a2, 2
	syscall
	
	move $t0, $v0
	lw $t1, size
	bltz $t0, file_error
	la $s0, address
	
	li $v0, 15
	move $a0, $t0
	lw $a1, ($s0)
	la $a2, ($t1)
	syscall
	
	li $v0, 16
	move $a0, $t0
	syscall
	
	b end
	
file_error:
	li $v0, 4
	la $a0, FileError
	syscall
end:
	#li $v0, 1
	#lw $a0, zpadding
	#syscall
	
	li $v0, 10
	syscall
	

	
	
	
	
	
	
	
	
	
