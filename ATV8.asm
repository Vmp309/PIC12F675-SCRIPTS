;******************************************************************************
;*			ARQUIVO DE DEFINI��ES
;******************************************************************************

;; PIC12F675 Configuration Bit Settings
; Assembly source line config statements
#include "p12f675.inc"

    
;------------------------------------------------------------------
; Configura��es do microcontrolador
;------------------------------------------------------------------
    __CONFIG _CP_OFF & _WDT_ON & _BODEN_OFF & _PWRTE_ON & _MCLRE_OFF & _INTRC_OSC_NOCLKOUT

    
;*******************************************************************************
;*			PAGINA��O DE MEM�RIA
;*******************************************************************************

#DEFINE	    BANK0 BCF STATUS,RP0 ;SETA BANK 0 DE MEM�RIA
#DEFINE	    BANK1 BSF STATUS,RP0 ;SETA BANK 1 DE MEM�RIA

    
;------------------------------------------------------------------
;			    VARI�VEIS
;------------------------------------------------------------------
    CBLOCK 0x20
        ADC_H        ; PARTE ALTA DO RESULTADO ADC
        ADC_L        ; PARTE BAIXA DO RESULTADO ADC
        TEMP         ; VARI�VEL TEMPOR�RIA
    ENDC

;------------------------------------------------------------------
;			  VETOR DE RESET
;------------------------------------------------------------------
    ORG     0x000
    GOTO    INICIO

;------------------------------------------------------------------
;			   INICIALIZA��O
;------------------------------------------------------------------
    
INICIO
    ; CONFIGURA O OSCILADOR INTERNO DE 4MHZ
    
    BANK1
    MOVLW   b'01110000'   ; IRCF2:IRCF0 = 110 (4MHz)
    MOVWF   OSCCAL
    BANK0

    ; CONFIGURA��O DOS PINOS
    BANK1
    MOVLW   b'00000001'   ; GP0 COMO ENTRADA, RESTO COMO SA�DA
    MOVWF   TRISIO
    MOVLW   b'00000001'   ; GP0 COMO ANAL�GICO
    MOVWF   ANSEL
    BANK0

    ; CONFIGURA O WDT PARA ~2s (PREESCALER 1:128)
    BANK1
    MOVLW   b'00000111'   ; PSA=0 (WDT), PS2:PS0=111 (1:128)
    MOVWF   OPTION_REG
    
    BANK0
    ; Configura o ADC
    MOVLW   b'10000001'   ; Canal AN0, ADON HABILITADO
    MOVWF   ADCON0

;------------------------------------------------------------------
; Loop principal
;------------------------------------------------------------------
MAIN_LOOP
    ; Inicia convers�o ADC
    BSF     ADCON0, GO    ; Inicia convers�o
    GOTO    WAIT_ADC	

WAIT_ADC
    BTFSC   ADCON0, GO    ; Verifica se convers�o terminou
    GOTO    WAIT_ADC    ; N�o terminou, continua esperando

    ; L� resultado do ADC
    MOVF    ADRESH, W
    MOVWF   ADC_H
    BANK1
    MOVF    ADRESL, W
    BANK0
    MOVWF   ADC_L

    ; Determina o n�vel de tens�o e aciona os LEDs apropriados
    CALL    MEDE_NIVEL

    ; Prepara para dormir
    CLRF    GPIO          ; Desliga todos os LEDs (opcional)

    ; Entra em modo SLEEP
    SLEEP

    ; O WDT vai resetar o microcontrolador ap�s ~2s
    ; e a execu��o continua a partir daqui

    GOTO    MAIN_LOOP

;------------------------------------------------------------------
; Subrotina: DeterminaNivel
; Determina o n�vel de tens�o e aciona os LEDs apropriados
;------------------------------------------------------------------
MEDE_NIVEL
    ; Verifica se tens�o < 2V (ADC < 410 para Vref=5V)
    MOVLW   HIGH(410)
    SUBWF   ADC_H, W
    BTFSS   STATUS, C     ; Carry=1 se adc_h >= HIGH(410)
    GOTO    NIVEL1        ; Tens�o < 2V

    MOVLW   LOW(410)
    SUBWF   ADC_L, W
    BTFSS   STATUS, C     ; Carry=1 se adc_l >= LOW(410)
    GOTO    NIVEL1        ; Tens�o < 2V

    ; Verifica se 2V <= tens�o < 3V (410 <= ADC < 614)
    MOVLW   HIGH(614)
    SUBWF   ADC_H, W
    BTFSS   STATUS, C
    GOTO    NIVEL2        ; Tens�o < 3V

    MOVLW   LOW(614)
    SUBWF   ADC_L, W
    BTFSS   STATUS, C
    GOTO    NIVEL2        ; Tens�o < 3V

    ; Verifica se 3V <= tens�o <= 4V (614 <= ADC <= 819)
    MOVLW   HIGH(819)
    SUBWF   ADC_H, W
    BTFSS   STATUS, C
    GOTO    NIVEL3        ; Tens�o <= 4V

    MOVLW   LOW(819)
    SUBWF   ADC_L, W
    BTFSS   STATUS, C
    GOTO    NIVEL3        ; Tens�o <= 4V

    ; Tens�o > 4V
    MOVLW   b'00100000'   ; GP5 = 1
    MOVWF   GPIO
    RETURN

NIVEL1
    MOVLW   b'00000010'   ; GP1 = 1
    MOVWF   GPIO
    RETURN

NIVEL2
    MOVLW   b'00000100'   ; GP2 = 1
    MOVWF   GPIO
    RETURN

NIVEL3
    MOVLW   b'00010000'   ; GP4 = 1
    MOVWF   GPIO
    RETURN

;------------------------------------------------------------------
;		Fim do programa
;------------------------------------------------------------------
    END