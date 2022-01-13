; ��ѯ
; ����Ŀʵ��led����˸, ���߷�����
; ��һ��led�����ܵ���������(�������Ǹ�)ͨ��һ������ӵ�ʵ����A2���ţ�
; �ٰ�led�����ܵ���������(���̵��Ǹ�)�ӵ�ʵ���ĵ���(G)��
BIT2        EQU 0X00000004
LED2        EQU BIT2        ;LED2--PA.2
CFGA        EQU 0x0300      ;PA.2�� ���������50MHz
	
GPIOA       EQU 0X40010800  ;GPIOA����ַ
GPIOA_CRL   EQU 0X40010800  ;�����üĴ���
GPIOA_CRH   EQU 0X40010804  ;�����üĴ���
GPIOA_ODR   EQU 0X4001080C  ;�����ƫ�Ƶ�ַ0Ch
GPIOA_BSRR  EQU 0X40010810  ;����λ�������ƫ�Ƶ�ַ10h
GPIOA_BRR   EQU 0X40010814  ;�����ƫ�Ƶ�ַ14h
GIOPAEN     EQU 0X00000004  ;GPIOAʹ��λ
	
TIM2EN      EQU 0X00000001  ;TIM2ʹ��λ
TIM2        EQU 0X40000000  ;TIM2����ַ
TIM2_ARR    EQU TIM2+0X2C   ;�Զ�װ�ؼĴ���
TIM2_PSC    EQU TIM2+0X28   ;Ԥ��Ƶ��
TIM2_DIER   EQU TIM2+0X0C   ;DMA/�ж�ʹ�ܼĴ���
TIM2_CR1    EQU TIM2+0X00   ;���ƼĴ���1
TIM2_SR     EQU TIM2+0X10   ;״̬�Ĵ���
	
RCC_APB1ENR EQU 0X4002101C
RCC_APB2ENR EQU 0X40021018

STACK_TOP EQU 0X20002000
 AREA RESET,CODE,READONLY   ; AREA���ܶ���д
 DCD STACK_TOP 				; MSP����ջָ��
 DCD START   				; ��λ��PC��ʼֵ 
 ENTRY         				; ָʾ��ʼִ��,����C�ļ���ENTRYע�͵�
START                      	; ���еı�ű��붥��д������ð��

; ����RCC��APB2ʹ�ܼĴ���������GPIOAʱ��
 LDR    R1, =RCC_APB2ENR     ; 0X4002101C
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]             ; ʹ��GPIOA
 
; ����RCC��APB1ʹ�ܼĴ���������TIM2ʱ��
 LDR    R1, =RCC_APB1ENR
 LDR    R0, [R1]
 LDR    R2, =TIM2EN         
 ORR    R0, R2
 STR    R0, [R1]
 
; ����GPIO���üĴ�����GPIOA.2 (LED2)--PA.2  ���������50MHz
 MOV    R0, #CFGA             ; 0X0300
 LDR    R1, =GPIOA_CRL       ; 0X40010800
 STR    R0, [R1]              
  
 ; ���ö�ʱ��Tim2����װ�ؼĴ���
 MOV    R0, #(1000-1)
 LDR    R1, =TIM2_ARR
 STR    R0, [R1]              

 ; ���ö�ʱ��Tim2�ķ�Ƶ��
 MOV    R0, #(7200-1)
 LDR    R1, =TIM2_PSC
 STR    R0, [R1]              

 ; ���ö�ʱ��Tim2�����üĴ�������������
 MOV    R0, #1
 LDR    R1, =TIM2_CR1
 STR    R0, [R1]              

LOOP
 LDR    R1, =GPIOA_ODR 
 LDR    R2, =LED2            ;��PA.2����ߵ�ƽ
 STR    R2, [R1]
 BL Delay
 MOV    R2, #0               ;��PA.2����͵�ƽ
 STR    R2, [R1]
 BL Delay
 B LOOP
 
Delay
  PUSH {R0,R1,R2,LR}
  LDR    R1, =TIM2_SR 
Delay1
  LDR    R2, [R1]      ; ��״̬�Ĵ���
  TST    R2,#1         ; �����Ƿ��и����¼�
  BEQ    Delay1        ; û����ת����Delay1

  MOV    R2, #0        ;�У�����������¼�״̬λ
  STR    R2,[R1]

  POP {R0,R1,R2,PC}
  NOP
 END
