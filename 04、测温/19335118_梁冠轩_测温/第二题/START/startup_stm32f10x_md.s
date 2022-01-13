GPIOA_BASE  EQU 0x40010800      ; GPIOA基地址
GPIOA_CRL   EQU GPIOA_BASE      ; 低配置寄存器
GPIOA_CRH   EQU GPIOA_BASE+4    ; 高配置寄存器
GPIOA_IDR   EQU GPIOA_BASE+0x08 ; 输入数据寄存器
GPIOA_ODR   EQU GPIOA_BASE+0x0c ; 输出数据寄存器
GPIOA_BSRR  EQU GPIOA_BASE+0x10 ; 端口位置位/清除寄存器
GPIOA_BRR   EQU GPIOA_BASE+0x14 ; 端口位清除寄存器

CFGAL       EQU 0x33333333      ; PA0~7：  推挽输出，50MHz
CFGAH       EQU 0x00000333      ; PA8~10： 推挽输出，50MHz     

RCC_APB2ENR EQU 0x40021018
GIOPAEN     EQU 0x00000004  	; GPIOA 使能位			 
APB2ENALL   EQU GIOPAEN					

CLEAR		EQU 0x01
RESETCUR	EQU	0x02
INMODE		EQU	0x06
DISPON		EQU	0x0c
DISPMODE	EQU 0x38
CRLF		EQU	0xc0
WRTDIGIT	EQU 0x0230
WRTLETTER	EQU 0x0241
WRTDOT		EQU	0x022e
WRTSPACE	EQU	0x0220

DIGREE1     EQU 0X0210
DIGREE2     EQU 0X0206
DIGREE3     EQU 0X0209
DIGREE4     EQU 0X0208
DIGREE5     EQU 0X0208
DIGREE6     EQU 0X0209
DIGREE7     EQU 0X0206
DIGREE8     EQU 0X0200
ROW         EQU 0X58

STACK_TOP EQU 0X20002000
 AREA RESET,CODE,READONLY   ; AREA不能顶格写
 DCD STACK_TOP 				; MSP主堆栈指针
 DCD START   				; 复位，PC初始值 
 ENTRY         				; 指示开始执行,有了C文件，ENTRY注释掉
START                      	; 所有的标号必须顶格写，且无冒号                  	

; 设置RCC的APB2使能寄存器，启动GPIOA
    LDR    R1, =RCC_APB2ENR     
    LDR    R0, =APB2ENALL
    STR    R0, [R1]       

; 设置GPIO配置寄存器，令PA0~PA10设置为推挽输出(50MHz)
    MOV    R0, #CFGAL
    LDR    R1, =GPIOA_CRL
    STR    R0, [R1]
    LDR    R0, =CFGAH
    LDR    R1, =GPIOA_CRH
    STR    R0, [R1]
 
    BL InitLED
	LDR R1, =GPIOA_ODR
	MOV R0, #WRTDIGIT
	
	ADD R2,R0,#2
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#0
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#2
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#0
	STR R2,[R1]
	BL EXCCMD
	
	MOV R2,#WRTDOT
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#1
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#1
	STR R2,[R1]
	BL EXCCMD
	
	MOV R2,#WRTDOT
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#8
	STR R2,[R1]
	BL EXCCMD
	
	MOV R2,#WRTSPACE
	STR R2,[R1]
	BL EXCCMD
	STR R2,[R1]
	BL EXCCMD
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#2
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#3
	STR R2,[R1]
	BL EXCCMD
	
	MOV R2,#WRTSPACE
	STR R2,[R1]
	BL EXCCMD
	
	MOV R0,#WRTLETTER
	
	MOV R2,#0x0203
	STR R2,[R1]
	BL EXCCMD
	
	MOV R2,#CRLF
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#('S'-'A')
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#('Y'-'A')
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#('S'-'A')
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#('U'-'A')
	STR R2,[R1]
	BL EXCCMD
	
	MOV R2,#WRTDOT
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#('E'-'A')
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#('D'-'A')
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#('U'-'A')
	STR R2,[R1]
	BL EXCCMD
	
	MOV R2,#WRTDOT
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#('C'-'A')
	STR R2,[R1]
	BL EXCCMD
	
	ADD R2,R0,#('N'-'A')
	STR R2,[R1]
	BL EXCCMD
	
LOOP
	 B LOOP
 
;设置自定义的字符显示
InitLED PROC
	PUSH{R0,R1,R2,R3,LR}
	LDR R1,=GPIOA_ODR
	
	MOV R0,#ROW
	STR R0,[R1]
	BL EXCCMD
	
	MOV R2,#DIGREE1
	STR R2,[R1]
	BL EXCCMD
	
	ADD R0,R0,#1
	STR R0,[R1]
	BL EXCCMD
	
	MOV R2,#DIGREE2
	STR R2,[R1]
	BL EXCCMD
	
	ADD R0,R0,#1
	STR R0,[R1]
	BL EXCCMD
	
	MOV R2,#DIGREE3
	STR R2,[R1]
	BL EXCCMD
	
	ADD R0,R0,#1
	STR R0,[R1]
	BL EXCCMD
	
	MOV R2,#DIGREE4
	STR R2,[R1]
	BL EXCCMD
	
	ADD R0,R0,#1
	STR R0,[R1]
	BL EXCCMD
 	
	MOV R2,#DIGREE5
	STR R2,[R1]
	BL EXCCMD
	
	ADD R0,R0,#1
	STR R0,[R1]
	BL EXCCMD
	
	
	MOV R2,#DIGREE6
	STR R2,[R1]
	BL EXCCMD
	
	ADD R0,R0,#1
	STR R0,[R1]
	BL EXCCMD
	
	
	MOV R2,#DIGREE7
	STR R2,[R1]
	BL EXCCMD
	
	ADD R0,R0,#1
	STR R0,[R1]
	BL EXCCMD
	
	MOV R2,#DIGREE8
	STR R2,[R1]
	BL EXCCMD
	
	
	MOV R0, #DISPMODE
	STR R0,[R1]
	BL EXCCMD
	
	MOV R0,#DISPON
	STR R0,[R1]
	BL EXCCMD
	
	MOV	R0, #INMODE
	STR	R0, [R1]
	BL EXCCMD
 
	MOV	R0, #CLEAR
	STR	R0, [R1]
	BL EXCCMD
 
	MOV	R0, #RESETCUR
	STR	R0, [R1]
	BL	EXCCMD
	
	POP{R0,R1,R2,R3,LR}
ENDP
	
EXCCMD 
    PUSH	{R0, R1, LR}
    
    LDR	R1, =GPIOA_BSRR
    MOV	R0, #0x00000400;set enable 
    STR	R0, [R1]
    MOV	R0, #0x04000000;reset enable
    STR	R0, [R1]
    BL Delay
    
    POP	{R0, R1, PC}
	
Delay
    PUSH {R0,R1,R2,LR}      
    MOVS R0,#0
    MOVS R1,#0
    MOVS R2,#0
                
DelayLoop0        
    ADDS R0,#1

    CMP R0,#33
    BCC DelayLoop0
    
    MOVS R0,#0
    ADDS R1,#1
    CMP R1,#33
    BCC DelayLoop0

    MOVS R0,#0
    MOVS R1,#0
    ADDS R2,#1
    CMP R2,#3
    BCC DelayLoop0                
    POP {R0,R1,R2,PC}  
END
