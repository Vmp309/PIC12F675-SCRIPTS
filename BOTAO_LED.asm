;;			    BOT�O E LED - EX1
;;    VERS�O: 1.0					DATA: 06/02/25
;;
;; AUTORA: VICTORIA MONTEIRO PONTES
;;
;;			    DESCRI��O DO ARQUIVO
;; ----------------------------------------------------------------------------
;; SISTEMA MUITO SIMPLES PARA REPRESENTAR O ESTADO DE UM BOT�O ATRAV�S DE UM
;;    LED;


;******************************************************************************
;*			ARQUIVO DE DEFINI��ES
;******************************************************************************

;; PIC12F675 Configuration Bit Settings
; Assembly source line config statements
#include "p12f675.inc"

; CONFIG
; __config 0xF1FF
 __CONFIG _FOSC_INTRCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _BOREN_OFF & _CP_OFF & _CPD_OFF

;*******************************************************************************
;*			PAGINA��O DE MEM�RIA
;*******************************************************************************

#DEFINE	    BANK0 BCF STATUS,RP0 ;SETA BANK 0 DE MEM�RIA
#DEFINE	    BANK1 BSF STATUS,RP0 ;SETA BANK 1 DE MEM�RIA


;*******************************************************************************
;*			    VARI�VEIS
;*******************************************************************************

CBLOCK	    0x20
 
    ESTADO_BOTAO
    
ENDC


;*******************************************************************************
;*			    ENTRADAS
;*******************************************************************************

;#DEFINE	    BOTAO   PORTA,2 ;PORTA DO BOTAO
;			    ;0 -> PRESSIONADO
;			    ;1 -> LIBERADO


;*******************************************************************************
;*			    SA�DAS
;*******************************************************************************
; AS SA�DAS SER�O OS ESTADOS DO LED

;#DEFINE	    LED	    PORTB,0 ;PORTA DO LED
;			    ;0 -> APAGADO
;			    ;1 -> ACESO


;*******************************************************************************
;*			   VETOR DE RESET
;*******************************************************************************
    ORG	    0X00    ;ENDERE�O INICIAL DE PROCESSAMENTO
    GOTO    INICIO


;*******************************************************************************
;*			IN�CIO DA INTERRUP��O
;*******************************************************************************
; AS INTERRUP��ES N�O SER�O UTILIZADAS, POR ISSO PODEMOS SUBSTITUIR TODO O
; SISTEMA EXISTENTE NO ARQUIVO MODELO PELO APRESENTADO ABAIXO.
; ESTE SISTEMA N�O � OBRIGAT�RIO MAS PODE EVITAR PROBLEMAS FUTUROS
    
    ORG 0X04	;ENDERELO INICIAL DA INTERRUP��O
    RETFIE	;RETORNA DA INTERRUP��O
    
    
;*******************************************************************************
;*			IN�CIO DO PROGRAMA
;*******************************************************************************
    
INICIO
    
    BANK1	    ;ALTERA PARA BANCO 1
    CLRF ANSEL	    ;Digital I/O
    MOVLW B'00000000'
    MOVWF TRISIO    ; GP0 COMO ENTRADA E O RESTO COMO SA�DA
    MOVLW B'00000000'
    MOVWF INTCON    ;TODAS AS INTERRUP��ES DESLIGADAS
    
    BANK0		;ALTERA PARA BANCO 0
    CLRF GPIO		;INCIALIZA GPIO
    MOVLW B'00000000'	; TUDO VIRA DIGITAL IO
    MOVWF CMCON		;digital IO
    
    
MAIN
    MOVF    GPIO, W         ; L� o estado atual dos pinos
    MOVLW   B'00000001'     ; Ativa GP0(ENTRADA) sem modificar GP1(SAIDA)
    MOVWF   GPIO           ; Escreve de volta no GPIO
    MOVWF   ESTADO_BOTAO
    BTFSC   ESTADO_BOTAO, 0  ;CHECA ENTRADA (BOTAO EST� PRESSIONADO?
    GOTO    BOTAO_PRES ;SIM, BOTAO EST� PRESSIONADO
    GOTO    BOTAO_LIB  ;N�O, BOT�O N�O EST� PRESSIONADO
    
    
BOTAO_LIB
    BCF	    GPIO, 0
    GOTO    MAIN
    
BOTAO_PRES
    MOVF GPIO, W         ; L� o estado atual dos pinos
    MOVLW B'00000010'     ; Ativa GP1 sem modificar GP0
    MOVWF GPIO           ; Escreve de volta no GPIO
    GOTO    MAIN
    
END