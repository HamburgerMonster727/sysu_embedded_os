; ����Ŀʵ���������ʾ, ���߷�����
; ������ܵ�����a~g��dp���ӵ�PA0~7������ܵ�����1~4����PA8~11
	
GPIOA_BASE  EQU 0X40010800      ;GPIOA����ַ
GPIOA_CRL   EQU GPIOA_BASE      ;�����üĴ���
GPIOA_CRH   EQU GPIOA_BASE+4    ;�����üĴ���
GPIOA_ODR   EQU GPIOA_BASE+0XC  ;�����ƫ�Ƶ�ַ0Ch
GPIOA_BSRR  EQU GPIOA_BASE+0X10 ;����λ�������ƫ�Ƶ�ַ10h
GPIOA_BRR   EQU GPIOA_BASE+0X14 ;�����ƫ�Ƶ�ַ14h
	
CFGAL        EQU 0x33333333      ;PA0~7��  ���������50MHz
CFGAH        EQU 0x00003333      ;PA8~11�� ���������50MHz

TIM2        EQU 0X40000000  ;TIM2����ַ
TIM2_ARR    EQU TIM2+0X2C   ;�Զ�װ�ؼĴ���
TIM2_PSC    EQU TIM2+0X28   ;Ԥ��Ƶ��
TIM2_DIER   EQU TIM2+0X0C   ;DMA/�ж�ʹ�ܼĴ���
TIM2_CR1    EQU TIM2+0X00   ;���ƼĴ���1
TIM2_SR     EQU TIM2+0X10   ;״̬�Ĵ���
	
RCC_APB2ENR EQU 0X40021018
GIOPAEN     EQU 0X00000004  ;GPIOAʹ��λ
GIOPBEN     EQU 0X00000008  ;GPIOBʹ��λ
GIOPALLEN   EQU GIOPAEN :OR: GIOPBEN

RCC_APB1ENR EQU 0X4002101C
TIM2EN      EQU 0X00000001  ;TIM2ʹ��λ

STACK_TOP EQU 0X20002000
	
 AREA MYDATA,DATA,READONLY                                               ; AREA���ܶ���д
CODES    DCB 0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f,0x00,0x00 ; �����0~9����ģ
DIGITPOS DCB 0x07,0x0b,0x0d,0x0e                                         ; ��λҪ��ʾ�����֣���0~3λΪ�����4�����ֵĿ����źţ�Ϊ0����ʾ��������ʾ

 AREA MYDATA2,DATA,READWRITE       ; AREA���ܶ���д(RAM,�Զ���ʼ��Ϊ0)
DIGITS    DCB 0x00,0x00,0x00,0x00  ; ������ʾ��4�����֣�ȡֵ0~9
CURSELECT DCB 0x00                 ; ��ǰ��ʾ�ĸ����֣�ȡֵ0~3

 AREA RESET,CODE,READONLY   ; AREA���ܶ���д
 DCD STACK_TOP 				; MSP����ջָ��
 DCD START   				; ��λ��PC��ʼֵ 
 ENTRY         				; ָʾ��ʼִ��,����C�ļ���ENTRYע�͵�
START                      	; ���еı�ű��붥��д������ð��

 BL InitRamArea
 
 ; ����RCC��APB2ʹ�ܼĴ���������GPIOA
 LDR    R1, =RCC_APB2ENR
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]             ; ʹ��GPIOA,GPIOB

; ����RCC��APB1ʹ�ܼĴ���������TIM2ʱ��
 LDR    R1, =RCC_APB1ENR
 LDR    R0, [R1]
 LDR    R2, =TIM2EN         
 ORR    R0, R2
 STR    R0, [R1]

; ����GPIO���üĴ���������GPIOA.2 PA0~PA11Ϊ���������50MHz
 MOV    R0, #CFGAL
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]              
 MOV    R0, #CFGAH
 LDR    R1, =GPIOA_CRH
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
 BL Delay
 BL AddTimer
 B LOOP
 
Delay PROC
  PUSH {R0,R1,R2,LR}
  LDR    R1, =TIM2_SR  
DelayLoop0        
  BL ShowDigits;
  LDR    R2, [R1]      ; ��״̬�Ĵ���
  TST    R2,#1         ; �����Ƿ��и����¼�
  BEQ    DelayLoop0    ; û����ת����DelayLoop0 
  MOV    R2, #0        ;�У�����������¼�״̬λ
  STR    R2,[R1]            
  POP {R0,R1,R2,PC}             
  ENDP
	  
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
    STRB R6,[R5,#2]
    STRB R6,[R5,#1]
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
  
  ; ����ģ��λ���������PA0~11
  LDR  R5, =GPIOA_ODR 
  STR  R7,[R5]   
  POP {R4,R5,R6,R7,PC}
  ENDP
		
AddTimer PROC
  PUSH {R1,R5,LR}
  LDR    R5,=DIGITS
  
  ; ʱ�����λ��1������ӵ�10(0xa),��λ��0��������һλ��1�����򣬹��̷���
  LDRB   R1,[R5,#0]
  ADD    R1,#1
  STRB   R1,[R5,#0]
  CMP    R1, #0x0a
  BNE    EXIT2
  MOV    R1,#0
  STRB   R1,[R5,#0]
  
  ; ʱ��ε�λ��1
  LDRB   R1,[R5,#1]
  ADD    R1,#1
  STRB   R1,[R5,#1]
  CMP    R1,#0x06
  BNE    EXIT2
  MOV    R1,#0
  STRB   R1,[R5,#1]
  
  ; ʱ��θ�λ��1
  LDRB   R1,[R5,#2]
  ADD    R1,#1
  STRB   R1,[R5,#2]
  CMP    R1,#0x0a
  BNE    EXIT2
  MOV    R1,#0
  STRB   R1,[R5,#2]
  
  ; ʱ�����λ��1
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

  END