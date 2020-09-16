
include 'ez80.inc'
include 'ti84pceg.inc'
include 'tiformat.inc'

macro clibs_program?
	local program
	program.iy_modified=1

	jp program_start
		if defined __icon__
			db $02,__icon__
		else if defined __description__
			db $01,__description__,0
		end if

	lib_load:
		include 'include/libs.inc'


	program_start:
		ld iy,ti.flags
		call ti.HomeUp
		call ti.RunIndicOff
		call libload_load
		ret nz


	macro store_data? arg*,rr:hl
		postpone
			section data_section
			data_str:
				db arg,0
		end postpone
		ld rr,data_str
	end macro

	macro c_call? function*,args&
		local amt
		amt=0
		program.iy_modified=1
		iterate arg, args
			indx %%-%+1
			match any,arg
				amt = amt+1
				match ( addr ), arg
					ld bc,arg
					push bc
				else if arg eq hl
					push hl
				else if arg eq de
					push de
				else if arg eq bc
					push bc
				else match addr, arg & defined arg
					ld bc,arg
					push bc
				else if arg eqtype "a"
					store_data arg
					ld bc,data_section
					data_section = data_section + lengthof arg
					push bc
				else if arg eq 0
					if function._#% = 1
						ld c,0
						push bc
					else
						or a,a
						sbc hl,hl
						push hl
					end if
				else if arg eqtype amt
					if arg
						if arg.isStatic
							ld bc,arg.val
						else
							ld bc,(arg)
						end if
					else
						if function._#% = 1
							ld c,arg
						else
							ld bc,arg
						end if
					end if
					push bc
				else if arg scale 0
					pea arg
				end if
			end match
		end iterate
		call function
		repeat amt
			pop bc
		end repeat
	end macro

	macro vardef_inline? var_name*,var_len:3
		var_name:=$-var_len
		var_name.len=var_len
		var_name.isStatic=0
	end macro

	macro vardef_standalone? var_name*,var_len:3
		var_name.len=var_len
		var_name:
			emit_var var_name
		var_name.isStatic=0
	end macro

	macro vardef_datasection? var_name*,var_len:3
		var_name.len=var_len
		postpone
			section data_section
			var_name:
				emit_var var_name
		end postpone
		var_name.isStatic=0
	end macro

	macro emit_var? var_name
		if used var_name.val
			if var_name.len=1
				db var_name.val
			else if var_name.len=2
				dw var_name.val
			else if var_name.len=3
				dl var_name.val
			end if
		else
			rb var_name.len
		end if
	end macro

	macro varstore? var_name*,reg:hl
		if var_name.isStatic
			vardef_datasection
		end
			ld (var_name.addr),reg
	end macro

	macro dataload? var_name*,data_str*
		postpone
			section data_section
			var_name:
				db data_str,0
		end postpone
		var_name.len=3
		var_name.val=var_name
		var_name.isStatic=1
	end macro

	macro ld_iy? val
		ld iy,val
		program.iy_modified=1
	end macro

	macro os_call? function*
		if program.iy_modified
			ld iy,ti.flags
			program.iy_modified=0
		end if
		call function
	end macro

	macro end_program?
		program_end:
			os_call ti.DrawStatusBar
			res ti.onInterrupt, (iy+ti.onFlags)
			jp ti.HomeUp
		data_section=$
	end macro
end macro
