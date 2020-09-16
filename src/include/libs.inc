
; returns z if loaded, nz if not loaded
libload_load.inram:
   call   ti.Arc_Unarc
libload_load:
   ld   hl,libload_name
   call   ti.Mov9ToOP1
   call   ti.ChkFindSym
   jr   c,.notfound
   call   ti.ChkInRam
   jr   z,.inram
   ld   hl,9 + 3 + libload_name.len
   add   hl,de
   ld   a,(hl)
   cp   a,$1f
   jr   c,.notfound
   dec   hl
   dec   hl
   ld   de,.relocations
   ld   bc,.notfound
   push   bc
   ld   bc,$aa55aa
   jp   (hl)
.notfound:
   xor   a,a
   inc   a
   ret

.relocations:
libload_libload:
   db   $c0, "LibLoad", $00, $1f


macro maybe_include_library? file_name, lib_name
	offset=0
	local lib
	macro library name, version
		lib._name equ name
		lib._version equ version
		lib.header:
			lib.setup_header
		lib.base:
		macro export function_name, args&
			if used function_name
				function_name:
					jp offset
				iterate arg, args
					indx %%-%+1
					match any,arg
						if arg = 1
							function_name._#% = 1
						else if arg > 1
							function_name._#% = 3
						end if
					end match
				end iterate
			end if
			offset = offset + 3
		end macro
	end macro
	include file_name
	if $ > lib.base
		macro lib.setup_header
			db $C0,lib._name,0,lib._version
		end macro
	else
		macro lib.setup_header
		end macro
	end if
end macro

maybe_include_library "lib/fileioc.lib", fileioc
maybe_include_library "lib/graphx.lib", graphx
maybe_include_library "lib/keypadc.lib", keypadc
maybe_include_library "lib/fontlibc.lib", fontlibc

restore library, export, num_libs

xor   a,a      ; return z (loaded)
pop   hl      ; pop error return
ret

libload_name:
db   ti.AppVarObj, "LibLoad", 0
.len := $ - .


