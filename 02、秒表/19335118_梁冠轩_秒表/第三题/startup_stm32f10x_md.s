; 本项目实现数码管显示, 接线方法：
; 把数码管的引脚a~g和dp连接到PA0~7，数码管的引脚1~4连至PA8~11
	
GPIOA_BASE  EQU 0X40010800      ;GPIOA基地址
GPIOA_CRL   EQU GPIOA_BASE      ;低配置寄存器
GPIOA_CRH   EQU GPIOA_BASE+4    ;高配置寄存器
GPIOA_ODR   EQU GPIOA_BASE+0XC  ;输出，偏移地址0Ch
GPIOA_BSRR  EQU GPIOA_BASE+0X10 ;低置位，高清除偏移地址10h
GPIOA_BRR   EQU GPIOA_BASE+0X14 ;清除，偏移地址14h
	
CFGAL        EQU 0x33333333      ;PA0~7：  推挽输出，50MHz
CFGAH        EQU 0x00003333      ;PA8~11： 推挽输出，50MHz

TIM2        EQU 0X40000000  ;TIM2基地址
TIM2_ARR    EQU TIM2+0X2C   ;自动装载寄存器
TIM2_PSC    EQU TIM2+0X28   ;预分频器
TIM2_DIER   EQU TIM2+0X0C   ;DMA/中断使能寄存器
TIM2_CR1    EQU TIM2+0X00   ;控制寄存器1
TIM2_SR     EQU TIM2+0X10   ;状态寄存器
	
RCC_APB2ENR EQU 0X40021018
GIOPAEN     EQU 0X00000004  ;GPIOA使能位
;GIOPBEN     EQU 0X00000008  ;GPIOB使能位
;GIOPALLEN   EQU GIOPAEN :OR: GIOPBEN

RCC_BASE    EQU 0x40021000
RCC_CR      EQU RCC_BASE+0x00
RCC_CFGR    EQU RCC_BASE+0x04
RCC_CIR     EQU RCC_BASE+0x08
RCC_CR_HSERDY EQU 0x00020000

RCC_APB1ENR EQU 0X4002101C
TIM2EN      EQU 0X00000001  ;TIM2使能位

ISER_TIM2   EQU 0xe000e100  ;
TIM2_ITEN   EQU 0x10000000

STACK_TOP EQU 0X20002000
	
 AREA MYDATA,DATA,READONLY                                               ; AREA不能顶格写
CODES    DCB 0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f,0x00,0x00 ; 数码管0~9的字模
DIGITPOS DCB 0x07,0x0b,0x0d,0x0e                                         ; 定位要显示的数字：第0~3位为数码管4个数字的控制信号，为0则显示，否则不显示

 AREA MYDATA2,DATA,READWRITE       ; AREA不能顶格写(RAM,自动初始化为0)
DIGITS    DCB 0x00,0x00,0x00,0x00  ; 正在显示的4个数字，取值0~9
CURSELECT DCB 0x00                 ; 当前显示哪个数字，取值0~3

 AREA RESET,CODE,READONLY   ; AREA不能顶格写
 DCD STACK_TOP 				; MSP主堆栈指针
 DCD START   				; 复位，PC初始值
 SPACE 0xB0-8;
 DCD   TIM2_IRQHandler      ; TIM2 
 ENTRY         				; 指示开始执行,有了C文件，ENTRY注释掉
START                      	; 所有的标号必须顶格写，且无冒号
 BL InitRamArea
 BL RCC_CONFIG_72MHZ

 ; 配置RCC的APB1使能寄存器，启动TIM2时钟
 LDR    R1, =RCC_APB1ENR
 ;LDR    R0, [R1]
 LDR    R2, =TIM2EN         
 ;ORR    R0, R2
 STR    R2, [R1]

 ; 配置RCC的APB2使能寄存器，启动GPIOA
 LDR    R1, =RCC_APB2ENR
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]             ; 使能GPIOA,GPIOB
 
; 配置GPIO配置寄存器，设置GPIOA.2 PA0~PA11为推挽输出和50MHz
 MOV    R0, #CFGAL
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]              
 MOV    R0, #CFGAH
 LDR    R1, =GPIOA_CRH
 STR    R0, [R1]            

 ; 设置定时器Tim2的重装载寄存器
 MOV    R0, #(10000-1)
 LDR    R1, =TIM2_ARR
 STR    R0, [R1]              

 ; 设置定时器Tim2的分频器
 MOV    R0, #(7200-1)
 LDR    R1, =TIM2_PSC
 STR    R0, [R1]              

 ; 设置定时器Tim2的DMA/中断允许寄存器 
 MOV    R0, #1
 LDR    R1, =TIM2_DIER
 STR    R0, [R1] 


 ; 设置NVIC的中断设置允许寄存器(ISER)
 MOV    R0, #TIM2_ITEN
 LDR    R1, =ISER_TIM2   ;0xE000E100
 STR    R0, [R1] 

 ; 设置定时器Tim2的配置寄存器，启动计数
 MOV    R0, #1
 LDR    R1, =TIM2_CR1
 STR    R0, [R1]              
 MOV    R3,#0

LOOP
 BL ShowDigits
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
    STRB R6,[R5,#2]
    STRB R6,[R5,#1]
    STRB R6,[R5,#0]
	
	POP {R5,R6,PC}
	ENDP

AddTimer PROC
  PUSH {R1,R5,LR}
  LDR    R5,=DIGITS
  
  ; 时间最低位加1，如果加到10(0xa),则本位清0，接着下一位加1，否则，过程返回
  LDRB   R1,[R5,#0]
  ADD    R1,#1
  STRB   R1,[R5,#0]
  CMP    R1, #0x0a
  BNE    EXIT2
  MOV    R1,#0
  STRB   R1,[R5,#0]
  
  ; 时间次低位加1
  LDRB   R1,[R5,#1]
  ADD    R1,#1
  STRB   R1,[R5,#1]
  CMP    R1,#0x06
  BNE    EXIT2
  MOV    R1,#0
  STRB   R1,[R5,#1]
  
  ; 时间次高位加1
  LDRB   R1,[R5,#2]
  ADD    R1,#1
  STRB   R1,[R5,#2]
  CMP    R1,#0x0a
  BNE    EXIT2
  MOV    R1,#0
  STRB   R1,[R5,#2]
  
  ; 时间最高位加1
  LDRB   R1,[R5,#3]
  ADD    R1,#1
  STRB   R1,[R5,#3]
  CMP    R1,#0x06
  BNE    EXIT2  
  MOV    R1,#0
  STRB   R1,[R5,#3]
  
EXIT2
  POP {R1,R5,PC}  
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
  
  ; 把字模和位控制输出到PA0~11
  LDR  R5, =GPIOA_ODR 
  STR  R7,[R5]   
  POP {R4,R5,R6,R7,PC}
  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;RCC  时钟配置 HCLK=72MHz=HSE*9
;;;PCLK2=HCLK  PCLK1=HCLK/2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RCC_CONFIG_72MHZ
 LDR    R1,=0X40021000 ;RCC_CR
 LDR    R0,[R1]
 LDR    R2,=0X00010000 ;HSEON
 ORR    R0,R2
 STR    R0,[R1]
WAIT_HSE_RDY
 LDR    R2,=0X00020000 ;HSERDY
 LDR    R0,[R1]
 ANDS   R0,R2
 CMP    R0,#0
 BEQ    WAIT_HSE_RDY
 LDR    R1,=0X40022000 ;FLASH_ACR
 MOV    R0,#0X12
 STR    R0,[R1]
 LDR    R1,=0X40021004 ;RCC_CFGR时钟配置寄存器
 LDR    R0,[R1]
;PLL倍频系数,PCLK2,PCLK1分频设置
;HSE 9倍频PCLK2=HCLK,PCLK1=HCLK/2
;HCLK=72MHz 0x001D0400
;HCLK=64MHz 0x00190400
;HCLK=48MHz 0x00110400
;HCLK=32MHz 0x00090400
;HCLK=24MHz 0x00050400
;HCLK=16MHz 0x00010400
 LDR    R2,=0x001D0400 
 ORR    R0,R2
 STR    R0,[R1]
 LDR    R1,=0X40021000 ;RCC_CR  
 LDR    R0,[R1]
 LDR    R2,=0X01000000 ;PLLON
 ORR    R0,R2
 STR    R0,[R1]
WAIT_PLL_RDY
 LDR    R2,=0X02000000 ;PLLRDY
 LDR    R0,[R1]
 ANDS   R0,R2
 CMP    R0,#0
 BEQ    WAIT_PLL_RDY
 LDR    R1,=0X40021004 ;RCC_CFGR
 LDR    R0,[R1]
 MOV    R2,#0X02
 ORR    R0,R2
 STR    R0,[R1]
WAIT_HCLK_USEPLL
 LDR    R0,[R1]
 ANDS   R0,#0X08
 CMP    R0,#0X08
 BNE    WAIT_HCLK_USEPLL
 BX LR    
 
TIM2_IRQHandler PROC
   PUSH {R0,R1,R2,LR}

   LDR    R0, =GPIOA_BSRR
   LDR    R1, =GPIOA_ODR  
   LDR    R2, [R1]             ; 读入PA.2的输出
   TST    R2, #0x4
   BEQ    TURNON               ; 如果为0，则灯亮 
   STR    R2, [R0]             ; 将PA.2输出低电平
   B EX
TURNON
   STR    R2, [R0]
EX
   LDR    R1, =TIM2_SR 
   BL     AddTimer
   MOV    R2, #0              ; 清除更新事件状态位
   STR    R2,[R1]

   POP {R0,R1,R2,PC}  
  ENDP
 END