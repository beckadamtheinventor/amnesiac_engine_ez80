
include 'include/macros.inc'
format ti executable "{program_name}"

clibs_program

program_start:
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

include 'draw_scripts.asm'

.key:
include 'passive_scripts.asm'
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
include 'key_scripts.asm'
	ret

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
	or a,a
	sbc hl,hl
	ld l,a
	add hl,hl
	ld bc,(tiles_ptr)
	push bc
	add hl,bc
	ld ix,sprite_pointers
	ld bc,0
	ld c,(hl)
	inc hl
	ld b,(hl)
	pop hl
	add hl,bc
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	mlt bc
	push hl
	ld hl,32768
	or a,a
	sbc hl,bc
	pop hl
	ret c
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
	push hl
	call zx7_Decompress
	pop hl
	pop hl
	
	
	xor a,a
	ret

include 'user_scripts.asm'

full_exit:
	call ti_CloseAll
	call gfx_End

end_program

sprite_pointers  := ti.pixelShadow
map_decompress_location  := ti.pixelShadow + 768


scrap_ram_ptr:
	dl map_decompress_location+32768
tilemap_layers:
	dl 8 dup 0
current_keypress:
	db 0
gfx_ptr:
	dl 0
tiles_ptr:
	dl 0

gfx_file:
	db "{gfx_appvar}",0
tiles_file:
	db "{tiles_appvar}",0

mode_r:
	db "r",0
