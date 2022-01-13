; 中断
; 本项目通过中断实现led灯闪烁, 接线方法：
;    把一个led二极管的正极引脚(更长的那根)
;     通过一个电阻接到实验板的A2引脚，
;    再把led二极管的正极引脚(更短的那根)接到实验板的地线(G)。
LED2ON     EQU 0x00000004  ; GPIO_BSRR:  bit2=1-PA2 on
LED2OFF    EQU 0x00040000  ; GPIO_BSRR:  bit18=1-PA2 off
GPIOCFGA   EQU 0x0300      ;PA.2--推挽输出(50MHz)
	
GPIOA_BASE EQU 0X40010800       ;GPIOA基地址
GPIOA_CRL  EQU GPIOA_BASE+0x00  ;低配置寄存器
GPIOA_CRH  EQU GPIOA_BASE+0x04  ;高配置寄存器
GPIOA_IDR  EQU GPIOA_BASE+0x08  ;输入数据寄存器
GPIOA_ODR  EQU GPIOA_BASE+0x0c  ;输出数据寄存器
GPIOA_BSRR EQU GPIOA_BASE+0x10  ;位端口置位/清零寄存器
GPIOA_BRR  EQU GPIOA_BASE+0x14  ;位端口清零寄存器
	
TIM2        EQU 0x40000000  ;TIM2基地址
TIM2_ARR    EQU TIM2+0x2c   ;自动装载寄存器
TIM2_PSC    EQU TIM2+0x28   ;预分频器
TIM2_DIER   EQU TIM2+0x0c   ;DMA/中断使能寄存器
TIM2_CR1    EQU TIM2+0x00   ;控制寄存器1
TIM2_SR     EQU TIM2+0x10   ;状态寄存器

RCC_BASE    EQU 0x40021000
RCC_CR      EQU RCC_BASE+0x00
RCC_CFGR    EQU RCC_BASE+0x04
RCC_CIR     EQU RCC_BASE+0x08
RCC_CR_HSERDY EQU 0x00020000
	
RCC_APB1ENR EQU 0x4002101c
TIM2EN      EQU 0x00000001  ;TIM2使能位

RCC_APB2ENR EQU 0x40021018
GIOPAEN     EQU 0x00000004  ;GPIOA使能位
	
ISER_TIM2   EQU 0xe000e100  ;
TIM2_ITEN   EQU 0x10000000
	
	
STACK_TOP EQU 0X20002000
   AREA RESET,CODE,READONLY   ; AREA不能顶格写
   DCD STACK_TOP 			  ; MSP主堆栈指针
   DCD START   				  ; 复位，PC初始值
   SPACE 0xB0-8;
   DCD   TIM2_IRQHandler      ; TIM2
   ENTRY         			  ; 指示开始执行,有了C文件，ENTRY注释掉
START                      	  ; 所有的标号必须顶格写，且无冒号
   BL     RCC_CONFIG_72MHZ
   
   ; 配置RCC的APB1使能寄存器，启动TIM2时钟
   LDR    R1, =RCC_APB1ENR
   ;LDR    R0, [R1]
   LDR    R2, =TIM2EN         
   ;ORR    R0, R2
   STR    R2, [R1]

   ; 配置RCC的APB2使能寄存器，启动GPIOA
   LDR    R1, =RCC_APB2ENR
   ;LDR    R0, [R1]
   LDR    R2, =GIOPAEN         
   ;ORR    R0, R2
   STR    R2, [R1]
 
   ; 配置GPIO的配置寄存器：设置GPIOA.2 (LED2)--PA.2  推挽输出，50MHz
   MOV    R0, #GPIOCFGA
   LDR    R1, =GPIOA_CRL
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
   B LOOP

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
   TST    R2,#0x4
   BEQ    TURNON               ; 如果为0，则灯亮
   MOV    R2,#LED2OFF          ;    否则，灯灭   
   STR    R2, [R0]             ; 将PA.2输出低电平
   B EX
TURNON
   LDR    R2, =LED2ON         ; 将PA.2输出高电平
   STR    R2, [R0]
EX
   LDR    R1, =TIM2_SR 
   MOV    R2, #0              ; 清除更新事件状态位
   STR    R2,[R1]
  
   POP {R0,R1,R2,PC}  
  ENDP
 END
