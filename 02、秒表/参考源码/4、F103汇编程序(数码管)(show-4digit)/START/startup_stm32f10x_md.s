; 本项目实现数码管显示0123, 接线方法：
; 把数码管的引脚a~g和dp连接到PA0~7，数码管的引脚1~4连至PA8~11
	
GPIOA_BASE   EQU 0x40010800      ;GPIOA基地址
GPIOA_CRL    EQU GPIOA_BASE      ;低配置寄存器
GPIOA_CRH    EQU GPIOA_BASE+4    ;高配置寄存器
GPIOA_ODR    EQU GPIOA_BASE+0x0c ;输出数据寄存器
GPIOA_BSRR   EQU GPIOA_BASE+0x10 ;按位设置和复位寄存器：低16为1的则置位ODR的相应位，高16为1的则复位ODR的相应位
GPIOA_BRR    EQU GPIOA_BASE+0x14 ;按位复位寄存器：低16为1的则复位ODR的相应位
	
CFGAL        EQU 0x33333333      ;PA0~7：  推挽输出，50MHz
CFGAH        EQU 0x00003333      ;PA8~11： 推挽输出，50MHz

RCC_APB2ENR  EQU 0x40021018
GIOPAEN      EQU 0x00000004  ; GPIOA使能位

STACK_TOP    EQU 0x20002000
	
 AREA MYDATA,DATA,READONLY   ; AREA不能顶格写
CODES    DCB 0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f,0x00,0x00 ; 数码管0~9的字模
DIGITPOS DCB 0x07,0x0b,0x0D,0x0e                                         ; 定位要显示的数字：第0~3位为数码管4个数字的控制信号，为0则显示，否则不显示

 AREA MYDATA2,DATA,READWRITE       ; RAM,必须初始化
DIGITS    DCB 0x00,0x00,0x00,0x00  ; 正在显示的4个数字，取值0~9
CURSELECT DCB 0x00                 ; 当前显示哪个数字，取值0~3

 AREA RESET,CODE,READONLY   ; AREA不能顶格写
 DCD STACK_TOP 				; MSP主堆栈指针
 DCD START   				; 复位，PC初始值 
 ENTRY         				; 指示开始执行,有了C文件，ENTRY注释掉
START                      	; 所有的标号必须顶格写，且无冒号

 BL InitRamArea
 
 ; 配置RCC的使能寄存器，启动GPIOA
 LDR    R1, =RCC_APB2ENR
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]
 
; 设置GPIO的配置寄存器，令GPIOA.2 PA0~PA11为推挽输出和50MHz
 MOV    R0, #CFGAL
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]              
 MOV    R0, #CFGAH
 LDR    R1, =GPIOA_CRH
 STR    R0, [R1]            
 
LOOP
 BL ShowDigits;
 B LOOP
 
; 所有RAM(MYDATA2)中的数据必须进行初始化
InitRamArea PROC
	PUSH {R5,R6,LR}
	
	; 初始化CURSELECT
	LDR  R5,=CURSELECT
    MOV  R6,#0
    STRB R6,[R5]   

    ; 初始化DIGITS
    LDR R5,=DIGITS	
	MOV R6,#0
    STRB R6,[R5,#3]
	MOV R6,#1
    STRB R6,[R5,#2]
	MOV R6,#2
    STRB R6,[R5,#1]
	MOV R6,#3
    STRB R6,[R5,#0]
	
	POP {R5,R6,PC}
	ENDP
	  
; 每次显示下一个数字(由CURSELECT指出)
ShowDigits PROC
  PUSH {R4,R5,R6,R7,LR}
  
  ; 确定下一个当前要显示的数字
  LDR  R5,=CURSELECT
  LDRB R6,[R5]
  ADD  R6,#1     ; 每个数字4个字节
  CMP  R6,#4
  BNE  SGNEXT
  MOV  R6,#0  
SGNEXT
  STRB R6,[R5]  
  
  ; 取出字模
  LDR  R5,=DIGITS
  LDRB R7,[R6,R5]
  LDR  R5, =CODES  
  LDRB R7,[R5,R7]
  
  ; 形成数字控制线
  LDR  R5,=DIGITPOS 
  LDRB R4,[R5,R6] 
  LSL  R4,R4,#8  
  ADD  R7,R4
  
  ; 把数据输出到PA0~11
  LDR  R5, =GPIOA_ODR 
  STR  R7,[R5]   
  POP {R4,R5,R6,R7,PC}
  ENDP

  NOP
  END