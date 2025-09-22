
#INCLUDE <p12f675.inc>
    
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _MCLRE_OFF & _INTRC_OSC_NOCLKOUT

; --- Constantes ---
#DEFINE VALOR_ALVO   0x73     ; Byte alvo (73h)
#DEFINE LED_PIN      GP5      ; LED em GP5
#DEFINE PRESCALER    0x02     ; Timer0 prescaler 1:8 (para 9600 bps @4MHz)

; --- Variáveis ---
CBLOCK 0x20
    SERIAL_DATA
    BIT_COUNTER
    ADC_VALUE
    TIMER_TEMP
ENDC

; --- Inicialização ---
ORG 0x000
GOTO    INICIO

INICIO
    ; Configura portas
    BSF     STATUS, RP0      ; Banco 1
    MOVLW   b'00000001'      ; GP0 (RX) input, GP1 (TX) e GP5 output
    MOVWF   TRISIO
    BCF     STATUS, RP0      ; Banco 0
    CLRF    GPIO             ; Inicializa todos os pins em LOW

    ; Configura Timer0 para baud rate (Banco 0)
    MOVLW   PRESCALER        ; Prescaler 1:8
    MOVWF   OPTION_REG

    ; Configura ADC (Banco 0)
    MOVLW   b'10000001'      ; Canal AN0, ADON=1, Fosc/8
    MOVWF   ADCON0

MAIN_LOOP
    CALL    SERIAL_RECEIVE   ; Recebe um byte
    MOVWF   SERIAL_DATA

    ; Verifica se o byte é 73h
    SUBLW   VALOR_ALVO
    BTFSS   STATUS, Z
    GOTO    MAIN_LOOP         ; Se não for, volta ao loop

    ; Aciona LED por 50ms (usando Timer0)
    BSF     GPIO, LED_PIN
    CALL    DELAY_50MS_T0    ; Delay preciso com Timer0
    BCF     GPIO, LED_PIN

    ; Realiza e transmite o ADC
    CALL    READ_ADC
    MOVF    ADC_VALUE, W
    CALL    SERIAL_SEND

    GOTO    MAIN_LOOP

; --- Sub-rotinas com Timer0 ---

SERIAL_RECEIVE
    ; Espera start bit (LOW em GP0)
    BTFSC   GPIO, GP0
    GOTO    $-1

    ; Delay de meio bit usando Timer0
    CALL    DELAY_HALFBIT_T0

    ; Lê 8 bits (LSB first)
    MOVLW   .8
    MOVWF   BIT_COUNTER

RECEIVE_BITS
    CALL    DELAY_FULLBIT_T0 ; Delay de 1 bit via Timer0
    BCF     STATUS, C
    BTFSC   GPIO, GP0
    BSF     STATUS, C
    RRF     SERIAL_DATA, F
    DECFSZ  BIT_COUNTER, F
    GOTO    RECEIVE_BITS

    ; Espera stop bit
    CALL    DELAY_FULLBIT_T0
    MOVF    SERIAL_DATA, W
    RETURN

SERIAL_SEND
    MOVWF   SERIAL_DATA
    ; Start bit (LOW)
    BCF     GPIO, GP1
    CALL    DELAY_FULLBIT_T0

    ; Envia 8 bits
    MOVLW   .8
    MOVWF   BIT_COUNTER

SEND_BITS
    BTFSC   SERIAL_DATA, 0
    BSF     GPIO, GP1
    BTFSS   SERIAL_DATA, 0
    BCF     GPIO, GP1
    CALL    DELAY_FULLBIT_T0
    RRF     SERIAL_DATA, F
    DECFSZ  BIT_COUNTER, F
    GOTO    SEND_BITS

    ; Stop bit (HIGH)
    BSF     GPIO, GP1
    CALL    DELAY_FULLBIT_T0
    RETURN

READ_ADC
    BSF     ADCON0, GO       ; Inicia conversão
    BTFSC   ADCON0, GO       ; Espera conclusão
    GOTO    $-1
    MOVF    ADRESH, W        ; Lê 8 bits MSB
    MOVWF   ADC_VALUE
    RETURN

; --- Delays Baseados no Timer0 ---
DELAY_FULLBIT_T0            ; Delay para 1 bit (104µs @9600 bps)
    MOVLW   .208             ; 256 - (104µs / (1µs * prescaler 8))
    MOVWF   TMR0
    BCF     INTCON, T0IF
    BTFSS   INTCON, T0IF
    GOTO    $-1
    RETURN

DELAY_HALFBIT_T0            ; Delay para 0.5 bit (52µs)
    MOVLW   .234             ; 256 - (52µs / (1µs * prescaler 8))
    MOVWF   TMR0
    BCF     INTCON, T0IF
    BTFSS   INTCON, T0IF
    GOTO    $-1
    RETURN

DELAY_50MS_T0               ; Delay de 50ms (usando loops com Timer0)
    MOVLW   .100
    MOVWF   TIMER_TEMP
    
DELAY_50MS_LOOP
    CALL    DELAY_FULLBIT_T0 ; ~500µs por loop
    DECFSZ  TIMER_TEMP, F
    GOTO    DELAY_50MS_LOOP
    RETURN

    END