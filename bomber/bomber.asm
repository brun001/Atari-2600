    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Incluir arquivos importantes com registros de memoria e macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declarar as variaveis importantes de um codigo com ebdereco $80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80

JetXPos         byte         ; player0 x-poicao 
JetYPos         byte         ; player0 y-posicao 
BomberXPos      byte         ; player1 x-posicao
BomberYPos      byte         ; player1 y-posicao
JetSpritePtr    word         ; ponteiro para a tabela de sprites do jogador
JetColorPtr     word         ; ponteiro para a tabela de cores do jogador
BomberSpritePtr word         ; ponteiro para atabela de sprites do inimigo
BomberColorPtr  word         ; ponteiro para a tabela de cores do inimigo
JetAnimOffset   byte         ; animacao do jogador quando vira a navinha 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declarar constantes 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JET_HEIGHT = 9               ; altura do sprite do jogador  (# linhas de acordo com a tabela de sprites) 
BOMBER_HEIGHT = 9            ; altura di sprite inimigo (# em linhas de acordo com a tabela de sprites)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicia nosso codigo da ROM com o endereco F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START              ; chama o macro para resetar memoria e registros 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicia as variaveis da RAM e registros TIA 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #10
    sta JetYPos              ; JetYPos = 10
    lda #60
    sta JetXPos              ; JetXPos = 60
    lda #83
    sta BomberYPos           ; BomberYPos = 83
    lda #54
    sta BomberXPos           ; BomberXPos = 54

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicializa os ponteiros para os enderecos corretos das tabelas
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #<JetSprite
    sta JetSpritePtr         ; pointeiro lo-byte para a tabela do jogador 
    lda #>JetSprite
    sta JetSpritePtr+1       ; ponteiro hi-bight para a tabela do jogador 

    lda #<JetColor
    sta JetColorPtr          ; pointeiro lo-byte para a tabela de cores
    lda #>JetColor
    sta JetColorPtr+1        ; ponteiro hi-byte para a tabela de cores 

    lda #<BomberSprite
    sta BomberSpritePtr      ; ponteiro lo-byte oara a tabela de sprites do jogador
    lda #>BomberSprite
    sta BomberSpritePtr+1    ; ponteiro hi-byte para a tabela de sprites do jogador

    lda #<BomberColor
    sta BomberColorPtr       ; ponteiro lo-byte para a tabela de cores do inimigo
    lda #>BomberColor
    sta BomberColorPtr+1     ; ponteiro h-byte par atabela de cores do inimigo 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicia o loop principal de renderuzacao dos frames 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculos e durante pre-VBLANK                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda JetXPos
    ldy #0
    jsr SetObjectXPos        ; configurar a posicao horizontal do jogador

    lda BomberXPos
    ldy #1
    jsr SetObjectXPos        ; configurar a posicao horizontal do inimigo

    sta WSYNC
    sta HMOVE                ; aplicar o offset horizontal anteriornmebte configurado

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; mostrar VSYNC e o VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK               ; liga o VBLANK 
    sta VSYNC                ; liga o VSYNC 
    REPEAT 3
        sta WSYNC            ; mostra as 3 linhas recomendadas do VSYNC
    REPEND
    lda #0
    sta VSYNC                ; desliga VSYNC 
    REPEAT 37
        sta WSYNC            ; mostra as 37 linhas recomendadas do VBLANK 
    REPEND
    sta VBLANK               ; desliga o VBLANK 



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mostra o placar de pontos                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #0 ;limpa registros TIA antes cada frame
    sta PF0  
    sta PF1
    sta PF2
    sta GRP0
    sta GRP1
    sta COLUPF
    REPEAT 20
        sta WSYNC  ;mostra os 20 scanlines onde vai aparecer o  placar
    REPEND


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mostra as 96 scanlines visiveis do nosso jogo (contando com o kernel de 2 linhas)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameVisibleLine:
    lda #$84
    sta COLUBK               ; configura a cor do rio para azul  
    lda #$C2
    sta COLUPF               ; configura a cor da grama  para verde 
    lda #%00000001
    sta CTRLPF               ; liga o recurso de refletir o campo de jogo
    lda #$F0
    sta PF0                  ; configurandio o padrao de bits do PF0
    lda #$FC
    sta PF1                  ; configurando o padrao de bits do PF1
    lda #0
    sta PF2                  ; configurando o  padrao de bits do PF2

    ldx #84                  ; X conta o numero restante de scanlines    
.GameLineLoop:
.AreWeInsideJetSprite:
    txa                      ; transfere X para A 
    sec                      ; certeza que o carry flag é declarado antes de fazer subtração
    sbc JetYPos              ; subtrai as coordenadas Y do sprite 
    cmp JET_HEIGHT           ; estramos dentro da altura do sprite recomendado?
    bcc .DrawSpriteP0        ; se o resutltado for menor qye a altura, chamar a rotina de desenhar sprite
    lda #0                   ; senao, configurar para 0      
.DrawSpriteP0:
    clc                      ; limpar o flag antes da aducao   
    adc JetAnimOffset        ; ir para o endereço da  memoria correto do sprite
    tay                      ; carrega Y entao podemos trabalhar com o ponteiro
    lda (JetSpritePtr),Y     ; carrega o bitmap do player0 da tabela     
    sta WSYNC                ; espera pelo scanline 
    sta GRP0                 ; configura os graficos do player 0 
    lda (JetColorPtr),Y      ; carrega as cores do jogador na tabela 
    sta COLUP0               ; configura a cor do player 0

.AreWeInsideBomberSprite:
    txa                      ; transfere X para A 
    sec                      ; certeza que o carry flag é declarado antes de subtrair
    sbc BomberYPos           ; subtrair as cordenadas Y    
    cmp BOMBER_HEIGHT        ; estramos dentro da altura do sprite?   
    bcc .DrawSpriteP1        ; se o resultado for menor que altura, chamar a rotina de desenho
    lda #0                   ; senao, configura o index para 0 
.DrawSpriteP1:
    tay                      ; carregando Y podemos usar  o ponteiro  

    lda #%00000101
    sta NUSIZ1               ; esticar o sprite do player 1

    lda (BomberSpritePtr),Y  ; carrega os bitmaps da tabela              
    sta WSYNC                ; espera o scanline 
    sta GRP1                 ; configura os graficos do jogador 1
    lda (BomberColorPtr),Y   ; carega as cores do player 1          
    sta COLUP1               ; configura as cores do player 1

    dex                      ; X--
    bne .GameLineLoop        ; repetir o proximo scanline ate ser finalizado 

    lda #0
    sta JetAnimOffset        ; reiniciar a  aanimacao para 0 cada frame      

    sta WSYNC                ; espera pelo scanline final 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display Overscan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK               ; liga o VBLANK de novo 
    REPEAT 30
        sta WSYNC            ; mostra as 30 linhas recomendadas do Overscan de VBLANK 
    REPEND
    lda #0
    sta VBLANK               ; desliga o VBLANK 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; configura os controles de Joystick do player 0 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    lda #%00010000           ; player0 joystick cima 
    bit SWCHA
    bne CheckP0Down          ; checa botao                                 
    inc JetYPos
    lda #0
    sta JetAnimOffset        ; reseta a animacao para o primeiro frame 

CheckP0Down:
    lda #%00100000           ; player0 joystick baixo 
    bit SWCHA
    bne CheckP0Left          ; checao botao                                    
    dec JetYPos
    lda #0
    sta JetAnimOffset        ; resetao sprite para o primeiro frame da animacao

CheckP0Left:
    lda #%01000000           ; player0 joystick esquerda
    bit SWCHA
    bne CheckP0Right         ; checa o  botao                                
    dec JetXPos
    lda JET_HEIGHT           ; 9
    sta JetAnimOffset        ; anima para o segundo frame               

CheckP0Right:
    lda #%10000000           ; player0 joystick direita 
    bit SWCHA
    bne EndInputCheck        ; checa o botao                                  
    inc JetXPos
    lda JET_HEIGHT           ; 9
    sta JetAnimOffset        ; configura a animacao para o segundo frame 

EndInputCheck:               ; finaliza quando nenhum input for pressionado

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculos para atualizar posicao no proximo frame                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




UpdateBomberPosition:
    lda BomberYPos
    clc
    cmp #0                   ; compara a posicao - y do inimigo para 0
    bmi .ResetBomberPosition ; se é menor que 0 resetar a posicao para o topo
    dec BomberYPos           ; senao decrementar posicao y do inimigo par o proximo frame 
    jmp EndPositionUpdate
.ResetBomberPosition
    lda #96
    sta BomberYPos
                              ; TODO: configurar a posicao X para o um numero aleatorio 
EndPositionUpdate:           ; finaliza o codigo de atualizar posicao  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Detectando colisões                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckCollisionP0P1:
    lda #%10000000	;CXPPMM detecta colisão do P0 e P1
    bit CXPPMM                  ; testa o padrão de bits da colsão
    bne .CollisionP0P1          ; se a colisão do P0 e P1 acontecer, Game Over
    jmp CheckCollisionP0PF      ; senão. pula pro próximo teste
.CollisionP0P1:
    jsr GameOver                ; chama a subrotina do GameOver
CheckCollisionP0PF:
    lda #%10000000
    bit CXP0FB
    bne .CollisionP0PF
    jmp EndCollisionCheck
.CollisionP0PF:
    jsr GameOver
    
EndCollisionCheck:
    sta CXCLR
    







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Voltar o  loop para um loop de um novo frame 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame           ;Continua a mostrar o proximo frame 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subrotina  para gerenciar a posicao horizontal com a animacao correta
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A é  o alvo da posicao X em pixels de nosso objeto              
;; Y é o tipo de objeto (0:player0, 1:player1, 2:missile0, 3:missile1, 4:ball)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetObjectXPos subroutine
    sta WSYNC                ; comeca um novo scanline      
    sec                      ; certeza que o carry flag é declarado antes da subtracao 
.Div15Loop
    sbc #15                  ; subtrair para 15 no acumulador 
    bcs .Div15Loop           ; fazer  loop do carry y ate se limpo
    eor #7                   ; gerenciar o range do offset de -8 para 7 
    asl
    asl
    asl
    asl                      ; quatro movme para esquerda tendo somente 4 bits
    sta HMP0,Y              
    sta RESP0,Y              ; fix object position in 15-step increment
    rts
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Game Over Subrotina                                                       ;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameOver subroutine
    lda #$30
    sta COLUBK
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tabelas da ROM 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JetSprite:
    .byte #%00000000         ;
    .byte #%00010100         ;   # #
    .byte #%01111111         ; #######
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

JetSpriteTurn:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

BomberSprite:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00101010         ;  # # #
    .byte #%00111110         ;  #####
    .byte #%01111111         ; #######
    .byte #%00101010         ;  # # #
    .byte #%00001000         ;    #
    .byte #%00011100         ;   ###

JetColor:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$08

JetColorTurn:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$0E
    .byte #$0E
    .byte #$08

BomberColor:
    .byte #$00
    .byte #$32
    .byte #$32
    .byte #$0E
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Completar o  tamanho da ROM exatamente para 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC                ; move para posicao $FFC
    word Reset               ; escreve 2 bytes o endereço reset             
    word Reset               ; escreve 2 bytes                              
