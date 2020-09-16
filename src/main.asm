
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

main_draw:
	call gfx_ZeroScreen
include 'draw_scripts.asm'

.key:
include 'passive_scripts.asm'
	call ti.GetCSC
	or a,a
	jr z,.key
include 'key_scripts.asm'
	jq main_draw

include 'user_scripts.asm'

full_exit:
	call ti_CloseAll
	call gfx_End

end_program


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
