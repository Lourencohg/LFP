; =============================================================================
; Controle de Robô com Sensores - PIC16F628A
; =============================================================================
; Descrição: 
;   - 3 sensores (esquerdo, direito, centro) conectados em RA0, RA1, RA2.
;   - 4 saídas em PORTB para controle de motores.
;   - Lógica: Seguir linha; parar se perder a linha; virar em intersecções.
; =============================================================================

#INCLUDE <P16F628A.INC>
__CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

#DEFINE BANK0    BCF STATUS, RP0   ; Banco de memória 0
#DEFINE BANK1    BSF STATUS, RP0   ; Banco de memória 1

; Sensores (entradas em PORTA):
#DEFINE SENSOR_ESQUERDO   PORTA, 0
#DEFINE SENSOR_DIREITO    PORTA, 1
#DEFINE SENSOR_CENTRO     PORTA, 2

; Padrões de movimento (saídas em PORTB):
#DEFINE FRENTE    b'00000101'   ; RB0 e RB2 ativos (motores para frente)
#DEFINE ESQUERDA  b'00000001'   ; RB0 ativo (virar à esquerda)
#DEFINE DIREITA   b'00000100'   ; RB2 ativo (virar à direita)
#DEFINE PARADA    b'00000000'   ; Motores desligados

; =============================================================================
; Vetores de Interrupção/Reset
; =============================================================================
ORG 0x0000
    GOTO INICIO          ; Vetor de Reset: inicia no programa principal
ORG 0x0004
    RETFIE               ; Sem interrupções habilitadas

; =============================================================================
; Inicialização
; =============================================================================
INICIO
    BANK1                ; Configura portas (Banco 1)
    MOVLW   B'11110000'  ; RB0-RB3 como saídas, RB4-RB7 como entradas
    MOVWF   TRISB
    MOVLW   B'00000111'  ; RA0, RA1, RA2 como entradas (sensores)
    MOVWF   TRISA
    BANK0                ; Retorna ao Banco 0
    CLRF    PORTB        ; Desliga todas as saídas
    CLRF    PORTA        ; Limpa PORTA
    MOVLW   0x07
    MOVWF   CMCON        ; Desativa comparadores para uso digital de PORTA

; =============================================================================
; Loop Principal
; =============================================================================
LOOP
    BTFSS   SENSOR_CENTRO    ; Sensor central ativo?
    GOTO    PARAR            ; Não: parar robô
    ;GOTO    VERIFICA_INTERSECCAO ; Sim: verificar intersecção

; -----------------------------------------------------------------------------
; Verifica se há uma intersecção (sensores laterais ativos)
; -----------------------------------------------------------------------------
;VERIFICA_INTERSECCAO
    BTFSS   SENSOR_ESQUERDO  ; Sensor esquerdo ativo?
    GOTO    MOVER_FRENTE     ; Não: seguir em frente
    BTFSS   SENSOR_DIREITO   ; Sensor direito ativo?
    GOTO    MOVER_FRENTE     ; Não: seguir em frente
    GOTO    VIRAR_ESQUERDA   ; Ambos ativos: virar à esquerda

; -----------------------------------------------------------------------------
; Ações de Controle
; -----------------------------------------------------------------------------
MOVER_FRENTE
    MOVLW   FRENTE       ; Carrega padrão "frente"
    MOVWF   PORTB        ; Ativa motores
    GOTO    LOOP         ; Repete o loop

VIRAR_ESQUERDA
    MOVLW   ESQUERDA     ; Carrega padrão "esquerda"
    MOVWF   PORTB        ; Vira o robô
    CALL    AGUARDAR_SAIDA_INTERSECCAO ; Espera sair da intersecção
    GOTO    VERIFICA_SENSOR_CENTRO ; Verifica se o sensor central está ativo antes de retornar

PARAR
    MOVLW   PARADA       ; Carrega padrão "parada"
    MOVWF   PORTB        ; Desliga motores
    GOTO    LOOP         ; Repete o loop (aguarda retomar linha)

; -----------------------------------------------------------------------------
; Subrotina: Aguarda até o robô sair da intersecção
; -----------------------------------------------------------------------------
AGUARDAR_SAIDA_INTERSECCAO
    BTFSC   SENSOR_CENTRO    ; Aguarda sensor central ser desativado
    GOTO    $-1              ; (loop enquanto ativo)
    RETURN

; -----------------------------------------------------------------------------
; Verifica se o sensor central está ativo antes de retornar ao loop principal
; -----------------------------------------------------------------------------
VERIFICA_SENSOR_CENTRO
    BTFSS   SENSOR_CENTRO    ; Sensor central ativo?
    GOTO    VERIFICA_SENSOR_CENTRO ; Não: aguarda até que esteja ativo
    GOTO    LOOP             ; Sim: retorna ao loop principal

; =============================================================================
; Fim do Programa
; =============================================================================
END
