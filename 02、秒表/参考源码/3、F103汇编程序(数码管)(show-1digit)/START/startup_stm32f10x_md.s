; 本项目实现数码管显示, 接线方法：
; 把数码管的引脚a~g和dp连接到PA0~7，数码管引脚的1~4连至PA8~11
	
GPIOA_BASE  EQU 0X40010800      ;GPIOA基地址
GPIOA_CRL   EQU GPIOA_BASE      ;低配置寄存器
GPIOA_CRH   EQU GPIOA_BASE+4    ;高配置寄存器
GPIOA_ODR   EQU GPIOA_BASE+0XC  ;输出，偏移地址0Ch
GPIOA_BSRR  EQU GPIOA_BASE+0X10 ;低置位，高清除偏移地址10h
GPIOA_BRR   EQU GPIOA_BASE+0X14 ;清除，偏移地址14h
	
CFGAL        EQU 0x33333333      ;PA0~7：  推挽输出，50MHz
CFGAH        EQU 0x00003333      ;PA8~11： 推挽输出，50MHz

	
RCC_APB2ENR EQU 0X40021018
GIOPAEN     EQU 0X00000004  ;GPIOA使能位
;GIOPBEN    EQU 0X00000008  ;GPIOB使能位
;GIOPALLEN  EQU GIOPAEN :OR: GIOPBEN

STACK_TOP EQU 0X20002000
	
 AREA MYDATA,DATA,READONLY   ; AREA不能顶格写
CODES  DCB 0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f;  0~9的字模

 AREA RESET,CODE,READONLY   ; AREA不能顶格写
 DCD STACK_TOP 				; MSP主堆栈指针
 DCD START   				; 复位，PC初始值 
 ENTRY         				; 指示开始执行,有了C文件，ENTRY注释掉
START                      	; 所有的标号必须顶格写，且无冒号

 ; 配置RCC的APB2使能寄存器，启动GPIOA
 LDR    R1, =RCC_APB2ENR
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]             ; 使能GPIOA,GPIOB

; 设置GPIO的配置寄存器，令GPIOA.2 PA0~PA11为推挽输出和50MHz
 MOV    R0, #CFGAL
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]              
 MOV    R0, #CFGAH
 LDR    R1, =GPIOA_CRH
 STR    R0, [R1]              

LOOP
 BL SHOW_ONE_DIGIT
 B LOOP

; 显示数码管的最左边数字
SHOW_ONE_DIGIT PROC
 PUSH   {R0,R1,LR}
 
 LDR    R0, =CODES
 ADD    R0, #0            ; 显示数字0（可以尝试改为1~9）
 LDRB   R1, [R0]
 ADD    R1, #0x0E00       ; 显示数码管最左边的数字

 LDR    R0, =GPIOA_ODR    ; 输出到PA0~PA11
 STR    R1, [R0]
 POP    {R0,R1,LR} 
 ENDP
 NOP

 END
