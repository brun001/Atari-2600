	processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Incluir arquivos importantes como macros e definições           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include "vcs.h"
	include "macro.h"

	seg code
	org $F000      ; Define a orgigem da ROM para $F000   
	
Reset:
	CLEAN_START    ; Chama o macro para limpar a memoria    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mostra o loop principal de render                                                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IniciaFrame:

        lda #2
        sta VBLANK
        sta VSYNC
        REPEAT 3
        sta WSYNC
        REPEND
        lda #0
        sta VSYNC
        REPEAT 37
          sta WSYNC
        REPEND
         sta VBLANK
         
         
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mostrar 192 scanlines                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         

MostraJogo:
      lda #$22
      sta COLUBK
      lda #$C2
      sta COLUPF
      ldx #192
      
      
.LoopLinha:
      sta WSYNC
      dex
      bne .LoopLinha
      
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Overscan                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;          
       
       lda #2
       sta VBLANK
       REPEAT 30
         sta WSYNC
       REPEND
       lda #0
       sta VBLANK
       jmp IniciaFrame
       

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Preenche a ROM para exatos 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC                                    
    .word Reset                                                     
    .word Reset 