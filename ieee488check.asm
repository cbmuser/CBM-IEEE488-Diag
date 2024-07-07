!to "diagbeta.prg",cbm

pia1_porta = $e810 ; PA6: IEEE EOI in  
pia1_cra   = $e811 ; CA2: IEEE EOI out
pia1_portb = $e812  
pia1_crb   = $e813

pia2_porta = $e820 ; Input buffer for IEEE data lines
pia2_cra   = $e821 ; CA2: IEEE NDAC out, CA1: IEEE ATN in 
pia2_portb = $e822 ; Output buffer for IEEE data lines
pia2_crb   = $e823 ; CB2: IEEE DAV out, CB1: IEEE SRQ in

via_portb  = $e840 ; PB0:NDAC in, PB1 NRFD out, PB2: ATN out, PB6:NRFD in, PB7: DAV in  
via_porta  = $e841  
via_ddrb   = $e842  
via_ddra   = $e843  
via_timr1h = $e845
via_pcr    = $e84c
via_ifr    = $e84d

screen     = $8000

source_lo  = $0a  
source_hi  = $0b
target_lo  = $0c
target_hi  = $0d 
line       = $0e
outbuf     = $0f
help_lo    = $11
help_hi    = $12
screen_lo  = $13
screen_hi  = $14
counter    = $15

get        = $ffe4
chrout     = $ffd2

; Basicstart
*= $0400
!byte $00,$0c,$08,$0a,$00,$9e,$31,$30,$33,$39,$00,$00,$00,$00
; main
*=$040f
     

      lda #$ff  
      sta outbuf
      lda #$c0
      sta screen_lo
      lda #$83
      sta screen_hi
      lda #$1e               ; upper case and graphics
      sta via_pcr
      and #$00
      sta counter  
      tay
      tax
      sta target_lo
      ora #$80
      sta target_hi 
      lda #<mainscreen
      sta source_lo
      lda #>mainscreen
      sta source_hi
      jsr copy   
main_keys:
-     jsr get
      cmp #$41
      beq j_set_atn
      cmp #$43
      beq j_set_eoi
      cmp #$44
      beq j_set_ndac
      cmp #$45
      beq j_edit        
      cmp #$48
      beq j_help
      cmp #$4e
      beq j_set_nrfd
      cmp #$52
      beq j_read_ports 
      cmp #$53
      beq j_set_port 
      cmp #$56
      beq j_set_dav 
      cmp #$58
      beq exit        
      bne - 
exit: lda #$93 
      jsr chrout  
      jmp $e116      
      rts 
j_edit
      jsr edit
j_read_ports
      jsr read_ports    
j_set_port
      jsr set_port    
j_set_nrfd
      jsr set_nrfd    
j_set_atn
      jsr set_atn
j_set_eoi
      jsr set_eoi
j_set_ndac
      jsr set_ndac
j_set_dav
      jsr set_dav
j_help:
      lda #<mainscreen       ; fetch current configuration 
      sta target_lo
      lda #>mainscreen
      sta target_hi 
      lda #$00
      tax
      sta source_lo
      lda #$80
      sta source_hi

      jsr copy
      lda #<helpscreen       ; show help screen
      sta help_lo
      lda #>helpscreen
      sta help_hi
      and #$00
      sta counter
--    lda counter
      cmp #$18 
      bne +
-     and #$00    
      sta counter
      jsr get
      cmp #$20
      beq ++
      bne -
+     jsr help               ; scroll in help 
      inc counter
      jmp --       
++    lda #<mainscreen+40    ; scroll in fetched configuration
      sta help_lo
      lda #>mainscreen+40
      sta help_hi
-     lda counter
      cmp #$18 
      bne +
      jmp main_keys         
+     jsr help
      inc counter       
      jmp -

edit: 
--    lda #$20
      sta $834a
      and #$00 
      sta $8232
      sta line
      lda #$32
      sta target_lo
      lda #$82
      sta target_hi
ed_keys:     
      jsr get
      cmp #$11
      beq scroll 
      cmp #$91
      beq scroll_up 
      cmp #$20
      beq toggle_bit
      cmp #$45
      beq eend 
      bne ed_keys
eend: lda #$20
      ldy #$00
      sta (target_lo),y 
      jmp main_keys
scroll: 
      lda line
      cmp #$07
      beq l0 
      inc line
      and #$00
      tay  
      pha      
      lda #$20
      sta (target_lo),y
      clc
      lda target_lo
      adc #$28
      sta target_lo
      bcc +
      inc target_hi
+     pla
      sta (target_lo),y         
      jmp ed_keys
l0:   lda #$20
      sta $834a
      and #$00 
      sta $8232
      sta line
      lda #$32
      sta target_lo
      lda #$82
      sta target_hi
      jmp ed_keys
scroll_up:
      lda line
      beq l7 
      dec line
      and #$00
      tay  
      pha      
      lda #$20
      sta (target_lo),y
      sec
      lda target_lo
      sbc #$28
      sta target_lo
      bcs +
      dec target_hi
+     pla
      sta (target_lo),y         
      jmp ed_keys
l7:   ora #$07
      sta line
      lda #$00
      sta $834a      
      ora #$20
      sta $8232   
      lda #$4a
      sta target_lo
      lda #$83
      sta target_hi
      jmp ed_keys
toggle_bit:
      clc
      lda target_lo
      adc #$0d
      sta target_lo
      bcc +
      inc target_hi
+     ldy #$00       
      lda (target_lo),y         
      cmp #"0"
      beq ++
      lda #"0"
      sta (target_lo),y         
      lda line
      tax
      lda outbuf
      and and_table,x
      sta outbuf    
      jmp +++    
++    lda line       
      tax
      lda outbuf
      ora or_table,x
      sta outbuf
      lda #"1"
      sta (target_lo),y         
+++   and #$00
      tay
      sec
      lda target_lo         
      sbc #$0d
      sta target_lo    
      bcs +              
      dec target_hi 
+     jmp ed_keys 
         
copy:
      ldy #$00 
-     lda (source_lo),y
      sta (target_lo),y
      iny
      bne -   
      inc target_hi
      inc source_hi
      inx
      cpx #$04
      bne -
      rts 
;------------------------------------------------
; scrolls in text from line 2 to 25 , one line up
help: 
;      lda $8f                ; compare inctime value
;-     cmp $8f                ; to slow down scroll 
;      beq -         
      ldx #$00
      ldy #$00
      lda #$28
      sta target_lo
      lda #$80
      sta target_hi 
      lda #$50
      sta source_lo 
      lda #$80
      sta source_hi 
--    ldy #$00 
-     lda (source_lo),y
      sta (target_lo),y
      iny
      cpy #$28  
      bne -   
      clc 
      lda source_lo
      adc #$28
      bcc +
      inc source_hi
+     sta source_lo           
      clc 
      lda target_lo
      adc #$28
      bcc +
      inc target_hi
+     sta target_lo           
      inx
      cpx #$18
      bne --
      ldy #$00
-     lda (help_lo),y 
      sta (screen_lo),y
      iny
      cpy #$28
      bne - 
      clc 
      lda help_lo
      adc #$28 
      bcc +
      inc help_hi
+     sta help_lo  
      rts
read_ports
      lda via_portb
      and 0b00000001 
      cmp #$01
      beq +
      lda #"0"
      sta $80c4  
      jmp _b7
+     lda #"1"
      sta $80c4  

_b7:  lda via_portb
      and 0b10000000 
      cmp #$80
      beq +
      lda #"0"
      sta $8114  
      jmp _b6
+     lda #"1"
      sta $8114  

_b6:  lda via_portb
      and 0b01000000 
      cmp #$40
      beq +
      lda #"0"
      sta $80ec  
      jmp pia
+     lda #"1"
      sta $80ec  
pia:  lda pia2_porta       
      and 0b00000001 
      cmp #$01
      beq +
      lda #"0"
      sta $80af  
      jmp b1
+     lda #"1"
      sta $80af  
b1:   lda pia2_porta 
      and 0b00000010 
      cmp #$02
      beq +
      lda #"0"
      sta $80d7  
      jmp b2
+     lda #"1"
      sta $80d7  
b2:   lda pia2_porta 
      and 0b00000100 
      cmp #$04
      beq +
      lda #"0"
      sta $80ff  
      jmp b3
+     lda #"1"
      sta $80ff  
b3:   lda pia2_porta 
      and 0b00001000 
      cmp #$08
      beq +
      lda #"0"
      sta $8127  
      jmp b4
+     lda #"1"
      sta $8127  
b4:   lda pia2_porta 
      and 0b00010000 
      cmp #$10
      beq +
      lda #"0"
      sta $814f  
      jmp b5
+     lda #"1"
      sta $814f  
b5:   lda pia2_porta 
      and 0b00100000 
      cmp #$20
      beq +
      lda #"0"
      sta $8177  
      jmp b6
+     lda #"1"
      sta $8177  
b6:   lda pia2_porta 
      and 0b01000000 
      cmp #$40
      beq +
      lda #"0"
      sta $819f  
      jmp b7
+     lda #"1"
      sta $819f  
b7:   lda pia2_porta 
      and 0b10000000 
      cmp #$80
      beq +
      lda #"0"
      sta $81c7  
      jmp eoi_in
+     lda #"1"
      sta $81c7  
eoi_in: 
      lda pia1_porta
      and 0b01000000
      cmp #$40
      beq eoi       
      lda #"0"
      sta $82a4  
;      jmp animation
eoi:  lda #"1"
      sta $82a4  
;      jmp animation

set_port:
      lda outbuf
      sta pia2_portb
;      jmp animation
 
set_nrfd:
      lda $8164
      cmp #"0"
      bne +
      lda via_portb 
      ora #$02
      sta via_portb 
      lda #"1" 
      sta $8164  
      jmp main_keys        
+     lda via_portb 
      and #$fd
      sta via_portb 
      lda #"0" 
      sta $8164
      jmp main_keys    

set_atn:
      lda $81dc
      cmp #"0"
      bne +
      lda via_portb
      ora #$04        
      sta via_portb   
      lda #"1" 
      sta $81dc  
      jmp main_keys        
+     lda via_portb 
      and #$fb
      sta via_portb 
      lda #"0" 
      sta $81dc
      jmp main_keys    

set_eoi:
      lda $82cc
      cmp #"0"
      bne +
      lda #$34
      sta pia1_cra
      lda #"1" 
      sta $82cc  
      jmp main_keys        
+     lda #$3c
      sta pia1_cra
      lda #"0" 
      sta $82cc
      jmp main_keys    


set_ndac:
      lda $836c
      cmp #"0"
      bne +
      lda #$3c
      sta pia2_cra
      lda #"1" 
      sta $836c  
      jmp main_keys        
+     lda #$34
      sta pia2_cra
      lda #"0" 
      sta $836c
      jmp main_keys    

set_dav:
      lda $8394
      cmp #"0"
      bne +
      lda #$3c
      sta pia2_crb
      lda #"1" 
      sta $8394  
      jmp main_keys        
+     lda #$34
      sta pia2_crb
      lda #"0" 
      sta $8394
      jmp main_keys    

animation:
      ldy #$00
--    lda $8f            ; compare inctime value
-     cmp $8f            ; to slow down scroll 
      beq -         
      lda $8003,y
      ora #$80 
      sta $8003,y  
      lda $8002,y
      and #$7f 
      sta $8002,y  
      iny
      cpy #$22
      bne --
      lda $8002,y
      and #$7f 
      sta $8002,y  
      jmp main_keys 


and_table:!by $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f
or_table: !by $01,$02,$04,$08,$10,$20,$40,$80

mainscreen:
!pet"   cbm pet 2001n ieee-488 diagnostic    "
!pet"                                        "
!pet"      pia 2             via 6522        "
!pet"                                        "
!pet"   pa0   di-1  x    pb0    ndac in  0   "
!pet"   pa1   di-2  x    pb6    nrfd in  0   "
!pet"   pa2   di-3  x    pb7    dav  in  0   "
!pet"   pa3   di-4  x                        "
!pet"   pa4   di-5  x    pb1    nrfd out 1   "
!pet"   pa5   di-6  x    set Nrfd            "
!pet"   pa6   di-7  x                        "
!pet"   pa7   di-8  x    pb2    atn  out 1   "
!pet"   Read ports (in)  set Atn             "
!pet"                                        "
!pet"   pb0   do-1  1         pia 1          "
!pet"   pb1   do-2  1                        "
!pet"   pb2   do-3  1    pa6     eoi in  0   "
!pet"   pb3   do-4  1    Ca2     eoi out 1   "
!pet"   pb4   do-5  1                        "
!pet"   pb5   do-6  1        pia 2           " 
!pet"   pb6   do-7  1                        "  
!pet"   pb7   do-8  1    ca2    nDac out 1   "
!pet"   Edit port        cb2    daV  out 1   "
!pet"                                        "
!pet"   Set port         eXit tool  Help     "


helpscreen:
!pet"                                        "
!pet"   R = read port and handshake lines    "
!pet"                                        "
!pet"   E = edit output port-bits            "
!pet"     cursor to move and space to toggle "
!pet"   E ends also editing                  "
!pet"                                        "
!pet"   S = sets current bits to port        "
!pet"                                        "
!pet"   handshake lines seperately driveable "
!pet"   by choosen keys:                     "
!pet"                                        "
!pet"   N = set or toggle nrfd               "
!pet"   A = set or toggle atn                "
!pet"   C = set or toggle eoi                "
!pet"   D = set or toglle ndac               "
!pet"   V = set or toggle dav                "
!pet"                                        "
!pet"   X to end the diagnostic-tool         "
!pet"                                        "
!pet"   H shows this help-screen             "
!pet"                                        "
!pet"      press space to go back            "
!pet"                                        "




