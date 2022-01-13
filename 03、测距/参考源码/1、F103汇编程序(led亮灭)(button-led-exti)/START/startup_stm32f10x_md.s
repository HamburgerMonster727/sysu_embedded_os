; 本工程实现按一次按钮（接通）就改变led灯的亮灭：
; 按钮：引脚B0通过一个电阻接电源引脚(3.3或v3)，0
; led： 引脚B1通过电阻连接led再接地，接地的一端为二极管短脚（负极）
PULL0DOWN  EQU 0x00010000; ODR0=0--PX0输入下拉 (默认)  这里用于PB0
PULL0UP    EQU 0x00000001; ODR0=1--PX0输入上拉
	
LED2ON     EQU 0x00000002  ; GPIOX_BSRR:   bit1=1---PX1 on
LED2OFF    EQU 0x00020000  ; GPIOX_BSRR:  bit17=1---PX1 off
CFGB       EQU 0x0038      ; GPIOB配置：PB0--下拉输入；PB1--推挽输出(50MHz)；
	
GPIOB_BASE EQU 0x40010c00       ;GPIOB基地址
GPIOB_CRL  EQU GPIOB_BASE+0x00  ;GPIOB低配置寄存器
GPIOB_CRH  EQU GPIOB_BASE+0x04  ;GPIOB高配置寄存器
GPIOB_IDR  EQU GPIOB_BASE+0x08  ;GPIOB输入数据寄存器
GPIOB_ODR  EQU GPIOB_BASE+0x0c  ;GPIOB输出数据寄存器
GPIOB_BSRR EQU GPIOB_BASE+0x10  ;GPIOB位端口置位/清零寄存器

RCC_APB2ENR EQU 0x40021018      ;RCC时钟APB2使能寄存器
GIOPBEN     EQU 0x00000008      ;RCC时钟GPIOB使能位	
AFIOEN      EQU 0x00000001      ;AFIO时钟使能位	
APB2ENALL   EQU GIOPBEN :OR: AFIOEN
	
AFIO_BASE     EQU 0x40010000
AFIO_EXTICR1  EQU AFIO_BASE+0X08 ; 外部中断(EXTI)配置寄存器1
AFIO_EXTI0_PB EQU 0x1            ; EXTI0选择PB0作为输入
	
EXTI_BASE  EQU 0x40010400
EXTI_IMR   EQU EXTI_BASE+0x00     ;EXTI中断屏蔽寄存器
EXTI_EMR   EQU EXTI_BASE+0x04     ;EXTI事件屏蔽寄存器
EXTI_PR    EQU EXTI_BASE+0x14     ;EXTI挂起寄存器
EXTI_RTSR  EQU EXTI_BASE+0x08     ;EXTI上升沿触发选择寄存器
RTSR_EXTI0 EQU 1                  ;EXTI0选择上升沿触发


NVIC_ISER0  EQU 0xe000e100   ;  NVIC中断设置允许寄存器
EXTI0_ITEN  EQU 0x40         ;  允许EXTI0中断
	
STACK_TOP EQU 0x20002000
 AREA RESET,CODE,READONLY  ; AREA不能顶格写
 DCD STACK_TOP 			   ; MSP主堆栈指针
 DCD START   			   ; 复位，PC初始值
 SPACE 0x58-8;
 DCD   EXTI0_IRQHandler
 ENTRY         			   ; 指示开始执行
START                      ; 所有的标号必须顶格写，且无冒号

; 设置RCCAPB2使能寄存器：打开GPIOA、GPIOB和AFIO部件（启动它们进入工作状态）
 LDR    R1, =RCC_APB2ENR
 LDR    R2, =APB2ENALL
 STR    R2, [R1]
 
; 设置AFIO的EXTI配置寄存器：把PB0连至EXTI0
 MOV    R0, #AFIO_EXTI0_PB
 LDR    R1, =AFIO_EXTICR1
 STR    R0, [R1] 
 
; 设置EXTI中断屏蔽寄存器：允许EXTI0中断
 MOV    R0, #1
 LDR    R1, =EXTI_IMR
 STR    R0, [R1] 
 
 ; 设置事件屏蔽寄存器：允许EXTI0事件中断
 MOV    R0, #1
 LDR    R1, =EXTI_EMR
 STR    R0, [R1] 
 
 ; 设置EXTI上升沿触发设置寄存器：EXTI0采用上升沿触发
 MOV    R0, #RTSR_EXTI0
 LDR    R1, =EXTI_RTSR
 STR    R0, [R1]
 
 ; 设置NVIC的中断设置允许寄存器(ISER)：允许EXTI0
 MOV    R0, #EXTI0_ITEN   ;第6位
 LDR    R1, =NVIC_ISER0
 STR    R0, [R1] 
 
 ;设置GPIOB低配置寄存器：PB.0 下拉输入
 MOV    R0, #CFGB
 LDR    R1, =GPIOB_CRL
 STR    R0, [R1]              
 LDR    R1, =GPIOB_BSRR 
 LDR    R2, =PULL0DOWN
 STR    R2, [R1]
 
 ; 将PB.1输出高电平
 LDR    R1, =GPIOB_BSRR
 LDR    R2, =LED2ON
 STR    R2, [R1]

LOOP 
  B      LOOP
 
 
EXTI0_IRQHandler PROC
   PUSH {R0,R1,R2,LR}
 
   LDR    R1, =GPIOB_ODR 
   LDR    R2, [R1]             ; 读入PA.2的输出
   TST    R2,#0x2
   BEQ    TURNON               ; 如果为0，则灯亮
   LDR    R1, =GPIOB_BSRR
   MOV    R2,#LED2OFF          ;    否则，灯灭   
   STR    R2, [R1]             ; 将PA.2输出低电平
   B EX
TURNON
   LDR    R1, =GPIOB_BSRR
   LDR    R2, =LED2ON         ; 将PA.2输出高电平
   STR    R2, [R1]
EX
   LDR    R1, =EXTI_PR 
   MOV    R2, #1              ; 清除EXTI0的触发请求
   STR    R2,[R1]
  
   POP {R0,R1,R2,PC}  
  ENDP
  NOP
 END