
include 'include/macros.inc'
format ti executable "X{0}"

clibs_program

	call ti_CloseAll
	c_call ti_Open, gfx_file, mode_r
	or a,a
	jq z,full_exit
	ld c,a
	push bc
	call ti_GetDataPtr
	ld (gfx_ptr),hl
	call ti_Close
	pop bc

	c_call ti_Open, tiles_file, mode_r
	or a,a
	jq z,full_exit
	ld c,a
	push bc
	call ti_GetDataPtr
	ld (tiles_ptr),hl
	call ti_Close
	pop bc

	call gfx_Begin
	call gfx_ZeroScreen
	c_call gfx_SetDraw,1

	xor a,a
load_map:
	call _load_map


main_draw:
	call gfx_ZeroScreen
	ld hl,tilemap_layers
	ld b,8
.loop:
	push bc
	push hl
	ld hl,(hl)
	add hl,de
	or a,a
	sbc hl,de
	jr z,.skip_layer
	ld de,(player_position_x)
	ld bc,(player_position_y)
	push bc
	push de
	push hl
	c_call gfx_TransparentTilemap_NoClip
	pop hl
	pop de
	pop bc
.skip_layer:
	pop hl
	pop bc
	djnz .loop

	call draw_scripts

.key:
	call passive_scripts
	call ti.GetCSC
	or a,a
	jr z,.key
	ld hl,.key
	push hl
	ld (current_keypress),a
	cp a,1
	jq z,move_north
	cp a,2
	jq z,move_west
	cp a,3
	jq z,move_east
	cp a,4
	jq z,move_south
	jp key_scripts

move_north:
	ld hl,(player_position_y)
	ld bc,-player_speed
	add hl,bc
	jq set_player_y
move_south:
	ld hl,(player_position_y)
	ld bc,player_speed
	add hl,bc
set_player_y:
	ld (player_position_y),hl
	ret

move_east:
	ld hl,(player_position_x)
	ld bc,player_speed
	add hl,bc
	jq set_player_x
move_west:
	ld hl,(player_position_x)
	ld bc,-player_speed
	add hl,bc
set_player_x:
	ld (player_position_x),hl
	ret

_load_map:
	ld bc,scrap_ram_location
	ld (scrap_ram_ptr),bc
	ld ix,sprite_pointers
	ld hl,(current_tile_layer)
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	mlt bc
	ex hl,de
	ld hl,32768
	or a,a
	sbc hl,bc
	add hl,de
	ld (.end_map_ptr),hl
	ex hl,de
	ret c

.load_sprite_loop:
	or a,a
	sbc hl,hl
	ld l,a
	add hl,hl
	ld bc,(gfx_ptr)
	push bc
	add hl,bc
	ld bc,0
	ld c,(hl)
	inc hl
	ld b,(hl)
	pop hl
	add hl,bc
	push hl
	push hl
	ld hl,map_decompress_location
	push hl
	call zx7_Decompress
	pop bc
	pop bc
	ld ix,map_decompress_location
	ld hl,(gfx_ptr)
	ld b,(ix)
.find_sprite_loop:
	ld a,(hl)
	call ti.AddHLAndA
	djnz .find_sprite_loop
	push hl
	ld hl,(scrap_ram_ptr)
	ld (ix),hl
	lea ix,ix+3
	push hl
	call zx7_Decompress
	pop hl
	pop bc
	ld b,(hl)
	inc hl
	ld c,(hl)
	mlt bc
	inc hl
	add hl,bc
	ld (scrap_ram_ptr),hl
	pop hl

	ld bc,0
.end_map_ptr:=$-3
	or a,a
	sbc hl,bc
	add hl,bc
	jr c,.load_sprite_loop
	
	xor a,a
	ret

full_exit:
	call ti_CloseAll
	call gfx_End

end_program

sprite_pointers  := ti.pixelShadow
map_decompress_location  := ti.pixelShadow + 768
scrap_ram_location   := ti.pixelShadow+768+32768

scrap_ram_ptr:
	dl scrap_ram_location
tilemap_layers:
	dl 8 dup 0
current_tile_layer:
	dl 0
current_keypress:
	db 0
player_position_x:
	dl 0
player_position_y:
	dl 0
player_speed := 2

include 'draw_scripts.asm'
include 'passive_scripts.asm'
include 'key_scripts.asm'
include 'user_scripts.asm'


gfx_ptr:
	dl 0
tiles_ptr:
	dl 0

tiles_file:
	db "Y{0}",0
gfx_file:
	db "Z{0}",0

mode_r:
	db "r",0


zx7_Decompress:
        pop     bc
        pop     de
        pop     hl
        push    hl
        push    de
        push    bc

        ld      a, 128

zx7t_copy_byte_loop:

        ldi                             ; copy literal byte

zx7t_main_loop:

        add     a, a                    ; check next bit
        call    z, zx7t_load_bits      ; no more bits left?
        jr      nc, zx7t_copy_byte_loop ; next bit indicates either literal or sequence

; determine number of bits used for length (Elias gamma coding)

        push    de
        ld      de, 0
        ld      bc, 1

zx7t_len_size_loop:

        inc     d
        add     a, a                    ; check next bit
        call    z, zx7t_load_bits      ; no more bits left?
        jr      nc, zx7t_len_size_loop
        jp      zx7t_len_value_start

; determine length

zx7t_len_value_loop:

        add     a, a                    ; check next bit
        call    z, zx7t_load_bits      ; no more bits left?
        rl      c
        rl      b
        jr      c, zx7t_exit           ; check end marker

zx7t_len_value_start:

        dec     d
        jr      nz, zx7t_len_value_loop
        inc     bc                      ; adjust length

; determine offset

        ld      e, (hl)                 ; load offset flag (1 bit) + offset value (7 bits)
        inc     hl

        sla e
        inc e

        jr      nc, zx7t_offset_end    ; if offset flag is set, load 4 extra bits
        add     a, a                    ; check next bit
        call    z, zx7t_load_bits      ; no more bits left?
        rl      d                       ; insert first bit into D
        add     a, a                    ; check next bit
        call    z, zx7t_load_bits      ; no more bits left?
        rl      d                       ; insert second bit into D
        add     a, a                    ; check next bit
        call    z, zx7t_load_bits      ; no more bits left?
        rl      d                       ; insert third bit into D
        add     a, a                    ; check next bit
        call    z, zx7t_load_bits      ; no more bits left?
        ccf
        jr      c, zx7t_offset_end
        inc     d                       ; equivalent to adding 128 to DE

zx7t_offset_end:

        rr      e                       ; insert inverted fourth bit into E

; copy previous sequence

        ex      (sp), hl                ; store source, restore destination
        push    hl                      ; store destination
        sbc     hl, de                  ; HL = destination - offset - 1
        pop     de                      ; DE = destination
        ldir

zx7t_exit:

        pop     hl                      ; restore source address (compressed data)
        jp      nc, zx7t_main_loop

zx7t_load_bits:

        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret
