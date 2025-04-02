;******************************************************************************
;*			ARQUIVO DE DEFINIÇÕES
;******************************************************************************

;; PIC12F675 Configuration Bit Settings
; Assembly source line config statements
#include "p12f675.inc"

; CONFIG
; __config 0xF1FF
 __CONFIG _FOSC_INTRCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _BOREN_OFF & _CP_OFF & _CPD_OFF

;*******************************************************************************
;*			PAGINAÇÃO DE MEMÓRIA
;*******************************************************************************

#DEFINE	    BANK0 BCF STATUS,RP0 ;SETA BANK 0 DE MEMÓRIA
#DEFINE	    BANK1 BSF STATUS,RP0 ;SETA BANK 1 DE MEMÓRIA


;*******************************************************************************
;*			    VARIÁVEIS
;*******************************************************************************
; $,34 V como valor dde referência
 
CBLOCK	    0x20
 
    VALOR_REFERENCIA
    
ENDC

;;VAMOS USAR CONVERSOR A/D
;*******************************************************************************
;*			    ENTRADAS
;*******************************************************************************
; DUAS ENTRADAS: O VALOR DE REFERÊNCIA E O SINAL ANALÓGICO
; GP2 É ENTRADA DE SINAL ANALÓGICO
    
;*******************************************************************************
;*			    SAÍDAS
;*******************************************************************************


;*******************************************************************************
;*			   VETOR DE RESET
;*******************************************************************************
    ORG	    0X00    ;ENDEREÇO INICIAL DE PROCESSAMENTO
    GOTO    INICIO


;*******************************************************************************
;*			INÍCIO DA INTERRUPÇÃO
;*******************************************************************************
; AS INTERRUPÇÕES NÃO SERÃO UTILIZADAS, POR ISSO PODEMOS SUBSTITUIR TODO O
; SISTEMA EXISTENTE NO ARQUIVO MODELO PELO APRESENTADO ABAIXO.
; ESTE SISTEMA NÃO É OBRIGATÓRIO MAS PODE EVITAR PROBLEMAS FUTUROS
    
    ORG 0X04	;ENDERELO INICIAL DA INTERRUPÇÃO
    RETFIE	;RETORNA DA INTERRUPÇÃO
    
    
;*******************************************************************************
;*			INÍCIO DO PROGRAMA
;*******************************************************************************
    
INICIO
    BANK1		;ALTERA PARA BANCO 1
    MOVLW B'01010100'
    MOVWF ANSEL	        ; I/O ANALÓGICCO NO GP2 - SINAL ANALÓGICO
    MOVLW B'00000100'
    MOVWF TRISIO	;GP2 COMO ENTRADA DO SINAL ANALÓGICO E GP1 SAÍDA DIGITAL
    MOVLW B'00000000'
    MOVWF INTCON	;TODAS AS INTERRUPÇÕES DESLIGADAS
    
    BANK0		;ALTERA PARA BANCO 0
    MOVLW B'11011101'   ;INICIALIZA A VARIÁVEL VALOR_REFERENCIA
    MOVWF VALOR_REFERENCIA
    MOVLW B'00001001'	; CONFIGURAÇÃO DO CONVERSOR AD - LEFT-JUSTIFIED - ADRESL
    MOVWF ADCON0
    CLRF GPIO		;INCIALIZA GPIO
    GOTO DISPARA_CONVERSAO
    
DISPARA_CONVERSAO
    BSF ADCON0, GO     ;CONVERSÃO A/D
    GOTO ESPERA_CONVERSAO
    
    
    
ESPERA_CONVERSAO
    BTFSC ADCON0, 1	     ;CONVERSÃO ESTÁ ACONTECENDO?
    GOTO ESPERA_CONVERSAO    ;SIM, ENTÃO VAI PARA CHECAGEM DE RESULTADO DA CONVERSÃO
    GOTO CONVERSAO   ;VOLTA PARA O INÍCIO DESTA SUB-ROTINA
    

CONVERSAO
    MOVFW ADRESH  ; CHECO SE O SINAL MEDIDO É MAIOR QUE VALOR_REFERENCIA
    SUBWF VALOR_REFERENCIA, W	    ;SUBTRAI WORK DE ADRESH E SALVA EM WORK
    BTFSS STATUS,  C	    ;HOUVE CARRY (VALR DE ADRESH É MAIOR)?
    GOTO  SINAL_1	    ;SE SIM, SINAL HIGH PARA SAÍDA
    GOTO  SINAL_0	    ;SE NÃO, SINAL LOW PARA SAÍDA
SINAL_1
    BSF	GPIO,1
    GOTO DISPARA_CONVERSAO
    
SINAL_0
    BCF	GPIO,1
    GOTO DISPARA_CONVERSAO
    
END