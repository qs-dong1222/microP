begin:		
			addi r1,r0,#999  #r1=999
			addi r2,r0,#3 	 #r2=3
			div	 r23,r1,r2	 #r23=999/3=333
			sw   5(r2),r23 	 #mem(3+5)=333
			addi r3,r0,#123  #r3=123
			jal  Jalplace	 #r31=5
tryplace:	
			addi r1,r0,#8787 #r1=8787
			addi r3,r0,#5656 #r3=5656
			j	 continue	 #jump to continue
Jalplace:	
			addi r4,r0,#7	 #r4=7
			addi r5,r0,#11	 #r5=11
			beqz r0,tryplace #jump tp tryplace
continue:	
			lw 	 r6,5(r2) #r6=mem(5+3)=333
			add  r7,r2,r6 #r7=3+333=336
			add  r8,r6,r5 #r8=333+11=344
			sub  r9,r8,r7 #r9=1010-1002=8
			subi r9,r9,#1 #r9=8-1=7
			seq  r10,r9,r4 #7==7
			sgt  r11,r10,r0 #1>0
			sge  r12,r9,r2  #7>=3
			sle  r13,r2,r1  #3<=999
			subi r14,r0,#100  #r14=-100
			seqi r15,r14,#-100	#-100=-100
			snei r16,r15,#-1232 #1!=-1232
			slti r17,r16,#2
			sgti r18,r17,#-100
			slei r19,r18,#1
			sgei r20,r19,#1
			mult r21,r9,r14 	#r21=7*(-100)=-700
			sw	 10(r20),r21	#mem(10+1)=mem(11)=-700
			sw	 11(r20),r21	#mem(11+1)=mem(12)=-700
			addi r1,r0,#15		#r1=15
			xor	 r2,r2,r2		#r2=0
			addi r2,r0,#3		#r2=3
			addi r3,r0,#12		#r3=12
			beqz r3,EQto0		#do not jump
			and  r4,r1,r2		#r4=1111 and 0011 = 3
			andi r5,r1,#12		#r5=1111 and 1100 = 12
			or	 r6,r3,r2		#r6=1100 or  0011 = 15
EQto0:		
			ori  r7,r3,#1		#r7=1100 or	 0001 = 13
			xor	 r8,r1,r4		#r8=1111 xor 0011 = 12
			xori r9,r1,#4		#r9=1111 xor 0100 = 11
			bnez r9,noEQto0		#jump to noEQto0
			addi r30,r0,#666	#do not execute
noEQto0:	
			sll  r10,r9,r19		#r10=1011 <- 1 = 22
			slli r11,r9,#2		#r11=1011 <- 2 = 44
			srl	 r12,r10,r19	#r12=10110 -> 1 = 11
			srli r13,r11,#2		#r13=44 -> 2 =11
			subi r14,r0,#4	    #r14=-4
			sra	 r15,r14,r19	#r15=-4 -> 1 = -2
			srai r16,r14,#1		#r16=-4 -> 1 = -2
