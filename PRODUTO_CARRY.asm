;******************************************************************************
;*			ARQUIVO DE DEFINIÇÕES
;******************************************************************************

;; PIC12F675 Configuration Bit Settings
; Assembly source line config statements
;;			    PRODUTO COM E SEM CARRY - EX1
;;    VERSÃO: 1.0					DATA: 27/02/25
;;
;; AUTORA: VICTORIA MONTEIRO PONTES
;;
;;			    DESCRIÇÃO DO ARQUIVO
;; ----------------------------------------------------------------------------
;; SISTEMA MUITO SIMPLES PARA IMPLEMENNTAR PRODUTO SEM CARRY EM QUE O RESULTADO
;; NÃO PODE SER MAIOR QUE 1 BYTE OU 0XFF E UM PRODUTO COM CARRY EM QUE O RESUL-
;; TADO SERÁ ARMAZENADO EM DUAS VARIÁVEIS, UMA COM O BYTE MENOS SIGNIFICATIVO E
;; OUTRA COM O MAIS SIGNIFICATIVO

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

CBLOCK	    0x20
 
    X1	;VARIÁVEL DE ENTRADA DE 1 BYTE
    X2	;VARIÁVEL DE ENTRADA DE 1 BYTE
    AUX ;VARIÁVEL AUXILIAR PARA PRESERVAR VALORES DA ENTRADA 
    R1	;VARIÁVEL DE SAÍDA DO BYTE MENOS SIGNIFICATIVO
    R2	;VARIÁVEL DE SAÍFA DO BYTE MAIS SIGNIFICATIVO
    
ENDC

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

; TODO ADD INTERRUPTS HERE IF USED

MAIN_PROG CODE                      ; let linker place main program

START
    ; LIMPA WREG E VARIÁVEIS DE SAÍDA
    CLRW 
    CLRF    R1
    CLRF    R2
    
    MOVLW   0xC9
    MOVWF   X1
    MOVLW   0x77
    MOVWF   X2
    
    MOVFW   X1 
    MOVWF   AUX ;UTILIZAMOS O AUX PARA PRESERVAR O VALOR DE X1
    MOVFW   X2	;TRABALHAMOS COM O X2 SNEOD MULTIPLICADO
    DECF    AUX	;DECREMEENTAMOS UM DO AUX POIS PARA IMPLEMENTAR O PRODUTO A NÚ-
		;MERO DE TERMOS DA SOMA SERÁ AUX -1
		;
    ;VAI PARA SUBROTINA DE PRODUTO SEM CARRY
    ;GOTO PRODUTO
    
    ;VAI PARA SUBROTINA DE PRODUTO COM CARRY
    GOTO PRODUTO_CARRY
 
    GOTO START	;VOLTA PARA O INÍCIO
    
PRODUTO
    ;AQUI É UTILIZADA A SOMA DE FORMA REPETIDA PARA IMPLEMENTAR O PRODUTO
    MOVFW   X2
    ADDWF   X2, 0
    DECF    AUX
    BTFSS   STATUS, Z ;OPERAÇÃO CHEGOU A ZERO?
    GOTO PRODUTO ;SE NÃO VOLTA PARA O INÍCIO DA SUBROTINA
    
    MOVWF   R1	;ARMAZENA RESULTADO NA VARIÁVEL DE SAÍDA MENOS SIGNIFICATIVA
    GOTO START
    
    
    
PRODUTO_CARRY
    ADDWF   X2, 0
    BTFSC   STATUS, C
    CALL CARRY
    
    DECF    AUX
    BTFSS STATUS, Z
    GOTO PRODUTO_CARRY
    
    MOVWF   R1
    MOVFW   R2	;PARA VISUALIZAÇÃO DA VARIÁVEL MAIS SIGNIFICATIVA
    CLRW
    GOTO START
    
CARRY
    INCF    R2
    RETURN
    
END