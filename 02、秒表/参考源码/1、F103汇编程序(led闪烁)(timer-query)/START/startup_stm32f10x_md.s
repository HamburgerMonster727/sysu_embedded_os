; 查询
; 本项目实现led灯闪烁, 接线方法：
; 把一个led二极管的正极引脚(更长的那根)通过一个电阻接到实验板的A2引脚，
; 再把led二极管的正极引脚(更短的那根)接到实验板的地线(G)。
BIT2        EQU 0X00000004
LED2        EQU BIT2        ;LED2--PA.2
CFGA        EQU 0x0300      ;PA.2： 推挽输出，50MHz
	
GPIOA       EQU 0X40010800  ;GPIOA基地址
GPIOA_CRL   EQU 0X40010800  ;低配置寄存器
GPIOA_CRH   EQU 0X40010804  ;高配置寄存器
GPIOA_ODR   EQU 0X4001080C  ;输出，偏移地址0Ch
GPIOA_BSRR  EQU 0X40010810  ;低置位，高清除偏移地址10h
GPIOA_BRR   EQU 0X40010814  ;清除，偏移地址14h
GIOPAEN     EQU 0X00000004  ;GPIOA使能位
	
TIM2EN      EQU 0X00000001  ;TIM2使能位
TIM2        EQU 0X40000000  ;TIM2基地址
TIM2_ARR    EQU TIM2+0X2C   ;自动装载寄存器
TIM2_PSC    EQU TIM2+0X28   ;预分频器
TIM2_DIER   EQU TIM2+0X0C   ;DMA/中断使能寄存器
TIM2_CR1    EQU TIM2+0X00   ;控制寄存器1
TIM2_SR     EQU TIM2+0X10   ;状态寄存器
	
RCC_APB1ENR EQU 0X4002101C
RCC_APB2ENR EQU 0X40021018

STACK_TOP EQU 0X20002000
 AREA RESET,CODE,READONLY   ; AREA不能顶格写
 DCD STACK_TOP 				; MSP主堆栈指针
 DCD START   				; 复位，PC初始值 
 ENTRY         				; 指示开始执行,有了C文件，ENTRY注释掉
START                      	; 所有的标号必须顶格写，且无冒号

; 设置RCC的APB2使能寄存器，启动GPIOA时钟
 LDR    R1, =RCC_APB2ENR     ; 0X4002101C
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]             ; 使能GPIOA
 
; 设置RCC的APB1使能寄存器，启动TIM2时钟
 LDR    R1, =RCC_APB1ENR
 LDR    R0, [R1]
 LDR    R2, =TIM2EN         
 ORR    R0, R2
 STR    R0, [R1]
 
; 设置GPIO配置寄存器：GPIOA.2 (LED2)--PA.2  推挽输出，50MHz
 MOV    R0, #CFGA             ; 0X0300
 LDR    R1, =GPIOA_CRL       ; 0X40010800
 STR    R0, [R1]              
  
 ; 设置定时器Tim2的重装载寄存器
 MOV    R0, #(1000-1)
 LDR    R1, =TIM2_ARR
 STR    R0, [R1]              

 ; 设置定时器Tim2的分频器
 MOV    R0, #(7200-1)
 LDR    R1, =TIM2_PSC
 STR    R0, [R1]              

 ; 设置定时器Tim2的配置寄存器，启动计数
 MOV    R0, #1
 LDR    R1, =TIM2_CR1
 STR    R0, [R1]              

LOOP
 LDR    R1, =GPIOA_ODR 
 LDR    R2, =LED2            ;将PA.2输出高电平
 STR    R2, [R1]
 BL Delay
 MOV    R2, #0               ;将PA.2输出低电平
 STR    R2, [R1]
 BL Delay
 B LOOP
 
Delay
  PUSH {R0,R1,R2,LR}
  LDR    R1, =TIM2_SR 
Delay1
  LDR    R2, [R1]      ; 读状态寄存器
  TST    R2,#1         ; 测试是否有更新事件
  BEQ    Delay1        ; 没有则转移至Delay1

  MOV    R2, #0        ;有，则清除更新事件状态位
  STR    R2,[R1]

  POP {R0,R1,R2,PC}
  NOP
 END
