; ����Ŀʵ���������ʾ0123, ���߷�����
; ������ܵ�����a~g��dp���ӵ�PA0~7������ܵ�����1~4����PA8~11
	
GPIOA_BASE   EQU 0x40010800      ;GPIOA����ַ
GPIOA_CRL    EQU GPIOA_BASE      ;�����üĴ���
GPIOA_CRH    EQU GPIOA_BASE+4    ;�����üĴ���
GPIOA_ODR    EQU GPIOA_BASE+0x0c ;������ݼĴ���
GPIOA_BSRR   EQU GPIOA_BASE+0x10 ;��λ���ú͸�λ�Ĵ�������16Ϊ1������λODR����Ӧλ����16Ϊ1����λODR����Ӧλ
GPIOA_BRR    EQU GPIOA_BASE+0x14 ;��λ��λ�Ĵ�������16Ϊ1����λODR����Ӧλ
	
CFGAL        EQU 0x33333333      ;PA0~7��  ���������50MHz
CFGAH        EQU 0x00003333      ;PA8~11�� ���������50MHz

RCC_APB2ENR  EQU 0x40021018
GIOPAEN      EQU 0x00000004  ; GPIOAʹ��λ

STACK_TOP    EQU 0x20002000
	
 AREA MYDATA,DATA,READONLY   ; AREA���ܶ���д
CODES    DCB 0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f,0x00,0x00 ; �����0~9����ģ
DIGITPOS DCB 0x07,0x0b,0x0D,0x0e                                         ; ��λҪ��ʾ�����֣���0~3λΪ�����4�����ֵĿ����źţ�Ϊ0����ʾ��������ʾ

 AREA MYDATA2,DATA,READWRITE       ; RAM,�����ʼ��
DIGITS    DCB 0x00,0x00,0x00,0x00  ; ������ʾ��4�����֣�ȡֵ0~9
CURSELECT DCB 0x00                 ; ��ǰ��ʾ�ĸ����֣�ȡֵ0~3

 AREA RESET,CODE,READONLY   ; AREA���ܶ���д
 DCD STACK_TOP 				; MSP����ջָ��
 DCD START   				; ��λ��PC��ʼֵ 
 ENTRY         				; ָʾ��ʼִ��,����C�ļ���ENTRYע�͵�
START                      	; ���еı�ű��붥��д������ð��

 BL InitRamArea
 
 ; ����RCC��ʹ�ܼĴ���������GPIOA
 LDR    R1, =RCC_APB2ENR
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]
 
; ����GPIO�����üĴ�������GPIOA.2 PA0~PA11Ϊ���������50MHz
 MOV    R0, #CFGAL
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]              
 MOV    R0, #CFGAH
 LDR    R1, =GPIOA_CRH
 STR    R0, [R1]            
 
LOOP
 BL ShowDigits;
 B LOOP
 
; ����RAM(MYDATA2)�е����ݱ�����г�ʼ��
InitRamArea PROC
	PUSH {R5,R6,LR}
	
	; ��ʼ��CURSELECT
	LDR  R5,=CURSELECT
    MOV  R6,#0
    STRB R6,[R5]   

    ; ��ʼ��DIGITS
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
	  
; ÿ����ʾ��һ������(��CURSELECTָ��)
ShowDigits PROC
  PUSH {R4,R5,R6,R7,LR}
  
  ; ȷ����һ����ǰҪ��ʾ������
  LDR  R5,=CURSELECT
  LDRB R6,[R5]
  ADD  R6,#1     ; ÿ������4���ֽ�
  CMP  R6,#4
  BNE  SGNEXT
  MOV  R6,#0  
SGNEXT
  STRB R6,[R5]  
  
  ; ȡ����ģ
  LDR  R5,=DIGITS
  LDRB R7,[R6,R5]
  LDR  R5, =CODES  
  LDRB R7,[R5,R7]
  
  ; �γ����ֿ�����
  LDR  R5,=DIGITPOS 
  LDRB R4,[R5,R6] 
  LSL  R4,R4,#8  
  ADD  R7,R4
  
  ; �����������PA0~11
  LDR  R5, =GPIOA_ODR 
  STR  R7,[R5]   
  POP {R4,R5,R6,R7,PC}
  ENDP

  NOP
  END