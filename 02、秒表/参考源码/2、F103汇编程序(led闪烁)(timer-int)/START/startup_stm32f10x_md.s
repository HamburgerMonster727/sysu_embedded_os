; �ж�
; ����Ŀͨ���ж�ʵ��led����˸, ���߷�����
;    ��һ��led�����ܵ���������(�������Ǹ�)
;     ͨ��һ������ӵ�ʵ����A2���ţ�
;    �ٰ�led�����ܵ���������(���̵��Ǹ�)�ӵ�ʵ���ĵ���(G)��
LED2ON     EQU 0x00000004  ; GPIO_BSRR:  bit2=1-PA2 on
LED2OFF    EQU 0x00040000  ; GPIO_BSRR:  bit18=1-PA2 off
GPIOCFGA   EQU 0x0300      ;PA.2--�������(50MHz)
	
GPIOA_BASE EQU 0X40010800       ;GPIOA����ַ
GPIOA_CRL  EQU GPIOA_BASE+0x00  ;�����üĴ���
GPIOA_CRH  EQU GPIOA_BASE+0x04  ;�����üĴ���
GPIOA_IDR  EQU GPIOA_BASE+0x08  ;�������ݼĴ���
GPIOA_ODR  EQU GPIOA_BASE+0x0c  ;������ݼĴ���
GPIOA_BSRR EQU GPIOA_BASE+0x10  ;λ�˿���λ/����Ĵ���
GPIOA_BRR  EQU GPIOA_BASE+0x14  ;λ�˿�����Ĵ���
	
TIM2        EQU 0x40000000  ;TIM2����ַ
TIM2_ARR    EQU TIM2+0x2c   ;�Զ�װ�ؼĴ���
TIM2_PSC    EQU TIM2+0x28   ;Ԥ��Ƶ��
TIM2_DIER   EQU TIM2+0x0c   ;DMA/�ж�ʹ�ܼĴ���
TIM2_CR1    EQU TIM2+0x00   ;���ƼĴ���1
TIM2_SR     EQU TIM2+0x10   ;״̬�Ĵ���

RCC_BASE    EQU 0x40021000
RCC_CR      EQU RCC_BASE+0x00
RCC_CFGR    EQU RCC_BASE+0x04
RCC_CIR     EQU RCC_BASE+0x08
RCC_CR_HSERDY EQU 0x00020000
	
RCC_APB1ENR EQU 0x4002101c
TIM2EN      EQU 0x00000001  ;TIM2ʹ��λ

RCC_APB2ENR EQU 0x40021018
GIOPAEN     EQU 0x00000004  ;GPIOAʹ��λ
	
ISER_TIM2   EQU 0xe000e100  ;
TIM2_ITEN   EQU 0x10000000
	
	
STACK_TOP EQU 0X20002000
   AREA RESET,CODE,READONLY   ; AREA���ܶ���д
   DCD STACK_TOP 			  ; MSP����ջָ��
   DCD START   				  ; ��λ��PC��ʼֵ
   SPACE 0xB0-8;
   DCD   TIM2_IRQHandler      ; TIM2
   ENTRY         			  ; ָʾ��ʼִ��,����C�ļ���ENTRYע�͵�
START                      	  ; ���еı�ű��붥��д������ð��
   BL     RCC_CONFIG_72MHZ
   
   ; ����RCC��APB1ʹ�ܼĴ���������TIM2ʱ��
   LDR    R1, =RCC_APB1ENR
   ;LDR    R0, [R1]
   LDR    R2, =TIM2EN         
   ;ORR    R0, R2
   STR    R2, [R1]

   ; ����RCC��APB2ʹ�ܼĴ���������GPIOA
   LDR    R1, =RCC_APB2ENR
   ;LDR    R0, [R1]
   LDR    R2, =GIOPAEN         
   ;ORR    R0, R2
   STR    R2, [R1]
 
   ; ����GPIO�����üĴ���������GPIOA.2 (LED2)--PA.2  ���������50MHz
   MOV    R0, #GPIOCFGA
   LDR    R1, =GPIOA_CRL
   STR    R0, [R1]              
 
 
   ; ���ö�ʱ��Tim2����װ�ؼĴ���
   MOV    R0, #(10000-1)
   LDR    R1, =TIM2_ARR
   STR    R0, [R1]              

   ; ���ö�ʱ��Tim2�ķ�Ƶ��
   MOV    R0, #(7200-1)
   LDR    R1, =TIM2_PSC
   STR    R0, [R1]              

   ; ���ö�ʱ��Tim2��DMA/�ж�����Ĵ��� 
   MOV    R0, #1
   LDR    R1, =TIM2_DIER
   STR    R0, [R1] 
 

   ; ����NVIC���ж���������Ĵ���(ISER)
   MOV    R0, #TIM2_ITEN
   LDR    R1, =ISER_TIM2   ;0xE000E100
   STR    R0, [R1] 

   ; ���ö�ʱ��Tim2�����üĴ�������������
   MOV    R0, #1
   LDR    R1, =TIM2_CR1
   STR    R0, [R1]              
   MOV    R3,#0
   

LOOP
   B LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;RCC  ʱ������ HCLK=72MHz=HSE*9
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
 LDR    R1,=0X40021004 ;RCC_CFGRʱ�����üĴ���
 LDR    R0,[R1]
;PLL��Ƶϵ��,PCLK2,PCLK1��Ƶ����
;HSE 9��ƵPCLK2=HCLK,PCLK1=HCLK/2
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
   LDR    R2, [R1]             ; ����PA.2�����
   TST    R2,#0x4
   BEQ    TURNON               ; ���Ϊ0�������
   MOV    R2,#LED2OFF          ;    ���򣬵���   
   STR    R2, [R0]             ; ��PA.2����͵�ƽ
   B EX
TURNON
   LDR    R2, =LED2ON         ; ��PA.2����ߵ�ƽ
   STR    R2, [R0]
EX
   LDR    R1, =TIM2_SR 
   MOV    R2, #0              ; ��������¼�״̬λ
   STR    R2,[R1]
  
   POP {R0,R1,R2,PC}  
  ENDP
 END
