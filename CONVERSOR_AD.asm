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
; $,34 V como valor dde refer�ncia
 
CBLOCK	    0x20
 
    VALOR_REFERENCIA
    
ENDC

;;VAMOS USAR CONVERSOR A/D
;*******************************************************************************
;*			    ENTRADAS
;*******************************************************************************
; DUAS ENTRADAS: O VALOR DE REFER�NCIA E O SINAL ANAL�GICO
; GP2 � ENTRADA DE SINAL ANAL�GICO
    
;*******************************************************************************
;*			    SA�DAS
;*******************************************************************************


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
    BANK1		;ALTERA PARA BANCO 1
    MOVLW B'01010100'
    MOVWF ANSEL	        ; I/O ANAL�GICCO NO GP2 - SINAL ANAL�GICO
    MOVLW B'00000100'
    MOVWF TRISIO	;GP2 COMO ENTRADA DO SINAL ANAL�GICO E GP1 SA�DA DIGITAL
    MOVLW B'00000000'
    MOVWF INTCON	;TODAS AS INTERRUP��ES DESLIGADAS
    
    BANK0		;ALTERA PARA BANCO 0
    MOVLW B'11011101'   ;INICIALIZA A VARI�VEL VALOR_REFERENCIA
    MOVWF VALOR_REFERENCIA
    MOVLW B'00001001'	; CONFIGURA��O DO CONVERSOR AD - LEFT-JUSTIFIED - ADRESL
    MOVWF ADCON0
    CLRF GPIO		;INCIALIZA GPIO
    GOTO DISPARA_CONVERSAO
    
DISPARA_CONVERSAO
    BSF ADCON0, GO     ;CONVERS�O A/D
    GOTO ESPERA_CONVERSAO
    
    
    
ESPERA_CONVERSAO
    BTFSC ADCON0, 1	     ;CONVERS�O EST� ACONTECENDO?
    GOTO ESPERA_CONVERSAO    ;SIM, ENT�O VAI PARA CHECAGEM DE RESULTADO DA CONVERS�O
    GOTO CONVERSAO   ;VOLTA PARA O IN�CIO DESTA SUB-ROTINA
    

CONVERSAO
    MOVFW ADRESH  ; CHECO SE O SINAL MEDIDO � MAIOR QUE VALOR_REFERENCIA
    SUBWF VALOR_REFERENCIA, W	    ;SUBTRAI WORK DE ADRESH E SALVA EM WORK
    BTFSS STATUS,  C	    ;HOUVE CARRY (VALR DE ADRESH � MAIOR)?
    GOTO  SINAL_1	    ;SE SIM, SINAL HIGH PARA SA�DA
    GOTO  SINAL_0	    ;SE N�O, SINAL LOW PARA SA�DA
SINAL_1
    BSF	GPIO,1
    GOTO DISPARA_CONVERSAO
    
SINAL_0
    BCF	GPIO,1
    GOTO DISPARA_CONVERSAO
    
END