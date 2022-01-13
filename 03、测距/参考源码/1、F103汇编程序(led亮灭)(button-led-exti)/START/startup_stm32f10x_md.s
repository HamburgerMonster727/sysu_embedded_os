; ������ʵ�ְ�һ�ΰ�ť����ͨ���͸ı�led�Ƶ�����
; ��ť������B0ͨ��һ������ӵ�Դ����(3.3��v3)��0
; led�� ����B1ͨ����������led�ٽӵأ��ӵص�һ��Ϊ�����ܶ̽ţ�������
PULL0DOWN  EQU 0x00010000; ODR0=0--PX0�������� (Ĭ��)  ��������PB0
PULL0UP    EQU 0x00000001; ODR0=1--PX0��������
	
LED2ON     EQU 0x00000002  ; GPIOX_BSRR:   bit1=1---PX1 on
LED2OFF    EQU 0x00020000  ; GPIOX_BSRR:  bit17=1---PX1 off
CFGB       EQU 0x0038      ; GPIOB���ã�PB0--�������룻PB1--�������(50MHz)��
	
GPIOB_BASE EQU 0x40010c00       ;GPIOB����ַ
GPIOB_CRL  EQU GPIOB_BASE+0x00  ;GPIOB�����üĴ���
GPIOB_CRH  EQU GPIOB_BASE+0x04  ;GPIOB�����üĴ���
GPIOB_IDR  EQU GPIOB_BASE+0x08  ;GPIOB�������ݼĴ���
GPIOB_ODR  EQU GPIOB_BASE+0x0c  ;GPIOB������ݼĴ���
GPIOB_BSRR EQU GPIOB_BASE+0x10  ;GPIOBλ�˿���λ/����Ĵ���

RCC_APB2ENR EQU 0x40021018      ;RCCʱ��APB2ʹ�ܼĴ���
GIOPBEN     EQU 0x00000008      ;RCCʱ��GPIOBʹ��λ	
AFIOEN      EQU 0x00000001      ;AFIOʱ��ʹ��λ	
APB2ENALL   EQU GIOPBEN :OR: AFIOEN
	
AFIO_BASE     EQU 0x40010000
AFIO_EXTICR1  EQU AFIO_BASE+0X08 ; �ⲿ�ж�(EXTI)���üĴ���1
AFIO_EXTI0_PB EQU 0x1            ; EXTI0ѡ��PB0��Ϊ����
	
EXTI_BASE  EQU 0x40010400
EXTI_IMR   EQU EXTI_BASE+0x00     ;EXTI�ж����μĴ���
EXTI_EMR   EQU EXTI_BASE+0x04     ;EXTI�¼����μĴ���
EXTI_PR    EQU EXTI_BASE+0x14     ;EXTI����Ĵ���
EXTI_RTSR  EQU EXTI_BASE+0x08     ;EXTI�����ش���ѡ��Ĵ���
RTSR_EXTI0 EQU 1                  ;EXTI0ѡ�������ش���


NVIC_ISER0  EQU 0xe000e100   ;  NVIC�ж���������Ĵ���
EXTI0_ITEN  EQU 0x40         ;  ����EXTI0�ж�
	
STACK_TOP EQU 0x20002000
 AREA RESET,CODE,READONLY  ; AREA���ܶ���д
 DCD STACK_TOP 			   ; MSP����ջָ��
 DCD START   			   ; ��λ��PC��ʼֵ
 SPACE 0x58-8;
 DCD   EXTI0_IRQHandler
 ENTRY         			   ; ָʾ��ʼִ��
START                      ; ���еı�ű��붥��д������ð��

; ����RCCAPB2ʹ�ܼĴ�������GPIOA��GPIOB��AFIO�������������ǽ��빤��״̬��
 LDR    R1, =RCC_APB2ENR
 LDR    R2, =APB2ENALL
 STR    R2, [R1]
 
; ����AFIO��EXTI���üĴ�������PB0����EXTI0
 MOV    R0, #AFIO_EXTI0_PB
 LDR    R1, =AFIO_EXTICR1
 STR    R0, [R1] 
 
; ����EXTI�ж����μĴ���������EXTI0�ж�
 MOV    R0, #1
 LDR    R1, =EXTI_IMR
 STR    R0, [R1] 
 
 ; �����¼����μĴ���������EXTI0�¼��ж�
 MOV    R0, #1
 LDR    R1, =EXTI_EMR
 STR    R0, [R1] 
 
 ; ����EXTI�����ش������üĴ�����EXTI0���������ش���
 MOV    R0, #RTSR_EXTI0
 LDR    R1, =EXTI_RTSR
 STR    R0, [R1]
 
 ; ����NVIC���ж���������Ĵ���(ISER)������EXTI0
 MOV    R0, #EXTI0_ITEN   ;��6λ
 LDR    R1, =NVIC_ISER0
 STR    R0, [R1] 
 
 ;����GPIOB�����üĴ�����PB.0 ��������
 MOV    R0, #CFGB
 LDR    R1, =GPIOB_CRL
 STR    R0, [R1]              
 LDR    R1, =GPIOB_BSRR 
 LDR    R2, =PULL0DOWN
 STR    R2, [R1]
 
 ; ��PB.1����ߵ�ƽ
 LDR    R1, =GPIOB_BSRR
 LDR    R2, =LED2ON
 STR    R2, [R1]

LOOP 
  B      LOOP
 
 
EXTI0_IRQHandler PROC
   PUSH {R0,R1,R2,LR}
 
   LDR    R1, =GPIOB_ODR 
   LDR    R2, [R1]             ; ����PA.2�����
   TST    R2,#0x2
   BEQ    TURNON               ; ���Ϊ0�������
   LDR    R1, =GPIOB_BSRR
   MOV    R2,#LED2OFF          ;    ���򣬵���   
   STR    R2, [R1]             ; ��PA.2����͵�ƽ
   B EX
TURNON
   LDR    R1, =GPIOB_BSRR
   LDR    R2, =LED2ON         ; ��PA.2����ߵ�ƽ
   STR    R2, [R1]
EX
   LDR    R1, =EXTI_PR 
   MOV    R2, #1              ; ���EXTI0�Ĵ�������
   STR    R2,[R1]
  
   POP {R0,R1,R2,PC}  
  ENDP
  NOP
 END