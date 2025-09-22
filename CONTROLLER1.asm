#include <p12f675.inc>
 __CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BODEN_ON & _CP_OFF & _CPD_OFF

#DEFINE	    BANK0 BCF STATUS,RP0 ;SETA BANK 0 DE MEM�RIA
#DEFINE	    BANK1 BSF STATUS,RP0 ;SETA BANK 1 DE MEM�RIA
#DEFINE	    LIMIAR_4V   .204
 
; Vari�veis
CBLOCK 0x20
    W_TEMP, STATUS_TEMP  ; Para salvamento do contexto durante interrup��o
    CONTADOR_TRANSBORDO	; Conta npumero de overflows, 156 transbordos de necess�rios
    CONTADOR_TEMP	; Conta vezes que contador_transbordo chegou a 156 (2.5s)
    
ENDC

ORG 0x000
    GOTO    INICIO

;--- Rotina de interrup��o (se necess�rio) ---
ORG 0x004
    RETFIE

INICIO
    ; Controller1 sempre ser� o segundo pic a ser acordado. Ele s� sa�ra do
    ; modo sleep e come�ar suas opera��es quando receber o Master Clear do Controller0
    SLEEP
    NOP
    
    ; Configura��o inicial
    BANK1
    MOVLW   b'01110000'   ; IRCF2:IRCF0 = 110 (4MHz)
    MOVWF   OSCCAL
    MOVLW   B'00011000'   ; GP5 sa�da alarme - GP4 recebe sinal anal�gico - GP3 recebe Master Clear RX - GP2 envia sinal de Master Clear TX
    MOVWF   TRISIO
    MOVLW   B'00011000'	  ; GP4 como AN3 e todas as sa�das digitais
    MOVWF   ANSEL
    MOVLW   B'00000111'   ; Timer0 habilitado
    MOVWF   OPTION_REG
    CLRF    INTCON	   ; Desliga todas as interrup��es
    
    BANK0
    CLRF    GPIO
    BSF	    GPIO, GP2
    
    ;Inicializa contador
    MOVLW   .76             ; 156 transbordos para ~2.5s
    MOVWF   CONTADOR_TRANSBORDO
    CLRF    TMR0
    MOVLW   .2
    MOVWF    CONTADOR_TEMP  ; onta 156 duas vezes para chegar a 5s
    
MAIN_LOOP
   
    CALL    CONVERSOR_AD
    
    BTFSS   INTCON, T0IF    ; Verifica transbordo do Timer0 
    GOTO    MAIN_LOOP       ; Se n�o houve overflow, continua esperando

    ; Overflow ocorreu:
    BCF     INTCON, T0IF    ; Limpa a flag de overflow
    CLRF    TMR0            ; Reinicia Timer0
    DECFSZ  CONTADOR_TRANSBORDO, F ; Decrementa o contador
    GOTO    MAIN_LOOP            ; Se n�o chegou a zero, continua

;Se o contrador de transbordo chegou a zero, ent�o chegou a 2.5s
    DECFSZ  CONTADOR_TEMP, F ; Decrementa o contador
    GOTO    MAIN_LOOP            ; Se n�o chegou a zero, continua

;Se o contador_temp chegou a zero ent�o chegou 5s, envia sinal de acordar para o outro pic
SEND_WAKEUP_SIGNAL
; Avisa Controller0 que vai dormir (pulso em GP2) e que controller1 deve acordar
; Envia pulso LOW (reset) por ~2�s
    BCF     GPIO, GP2       ; Seta LOW para reset
    CALL    DELAY_2US       ; Delay m�nimo de 2�s
    BSF     GPIO, GP2       ; Volta para HIGH
    
    ; Entra em Sleep Mode
    SLEEP
    NOP                   ; P�s-SLEEP
    ; Ao acordar (ap�s ~5s), repete o processo
    GOTO    MAIN_LOOP

CONVERSOR_AD
    ; Configura e inicia a convers�o ADC no canal AN1 (GP1)
    MOVLW   b'01000001'     ; Canal AN1 (bit 0-2 = '001'), ADC ligado (bit 0 = '1')
    MOVWF   ADCON0
    BSF     ADCON0, GO      ; Inicia convers�o
    
AGUARDA_ADC
    BTFSC   ADCON0, GO      ; Aguarda fim da convers�o (~20�s)
    GOTO    AGUARDA_ADC

    ; L� o resultado de 8 bits (ADRESH) e compara com 204 (equivalente a 4V)
    MOVF    ADRESH, W       ; Carrega o valor convertido (8 bits)
    SUBLW   LIMIAR_4V       ; Subtrai 204 (W = LIMIAR_4V - ADRESH)
    BTFSS   STATUS, C       ; Se C=0 (ADRESH > LIMIAR_4V), tens�o > 4V
    BCF     GPIO, GP5	    ;  SET GP5 DESLIGA ALARME
    BSF     GPIO, 5	    ;Sen�o, clear GP5LIGA ALARME
    
    RETURN
    
DELAY_2US
    ; Implemente um delay de ~3us aqui
    NOP
    NOP
    NOP
    RETURN
    
END