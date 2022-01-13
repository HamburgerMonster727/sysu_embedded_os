; ����Ŀʵ���������ʾ, ���߷�����
; ������ܵ�����a~g��dp���ӵ�PA0~7����������ŵ�1~4����PA8~11
	
GPIOA_BASE  EQU 0X40010800      ;GPIOA����ַ
GPIOA_CRL   EQU GPIOA_BASE      ;�����üĴ���
GPIOA_CRH   EQU GPIOA_BASE+4    ;�����üĴ���
GPIOA_ODR   EQU GPIOA_BASE+0XC  ;�����ƫ�Ƶ�ַ0Ch
GPIOA_BSRR  EQU GPIOA_BASE+0X10 ;����λ�������ƫ�Ƶ�ַ10h
GPIOA_BRR   EQU GPIOA_BASE+0X14 ;�����ƫ�Ƶ�ַ14h
	
CFGAL        EQU 0x33333333      ;PA0~7��  ���������50MHz
CFGAH        EQU 0x00003333      ;PA8~11�� ���������50MHz

	
RCC_APB2ENR EQU 0X40021018
GIOPAEN     EQU 0X00000004  ;GPIOAʹ��λ
;GIOPBEN    EQU 0X00000008  ;GPIOBʹ��λ
;GIOPALLEN  EQU GIOPAEN :OR: GIOPBEN

STACK_TOP EQU 0X20002000
	
 AREA MYDATA,DATA,READONLY   ; AREA���ܶ���д
CODES  DCB 0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f;  0~9����ģ

 AREA RESET,CODE,READONLY   ; AREA���ܶ���д
 DCD STACK_TOP 				; MSP����ջָ��
 DCD START   				; ��λ��PC��ʼֵ 
 ENTRY         				; ָʾ��ʼִ��,����C�ļ���ENTRYע�͵�
START                      	; ���еı�ű��붥��д������ð��

 ; ����RCC��APB2ʹ�ܼĴ���������GPIOA
 LDR    R1, =RCC_APB2ENR
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]             ; ʹ��GPIOA,GPIOB

; ����GPIO�����üĴ�������GPIOA.2 PA0~PA11Ϊ���������50MHz
 MOV    R0, #CFGAL
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]              
 MOV    R0, #CFGAH
 LDR    R1, =GPIOA_CRH
 STR    R0, [R1]              

LOOP
 BL SHOW_ONE_DIGIT
 B LOOP

; ��ʾ����ܵ����������
SHOW_ONE_DIGIT PROC
 PUSH   {R0,R1,LR}
 
 LDR    R0, =CODES
 ADD    R0, #0            ; ��ʾ����0�����Գ��Ը�Ϊ1~9��
 LDRB   R1, [R0]
 ADD    R1, #0x0E00       ; ��ʾ���������ߵ�����

 LDR    R0, =GPIOA_ODR    ; �����PA0~PA11
 STR    R1, [R0]
 POP    {R0,R1,LR} 
 ENDP
 NOP

 END
