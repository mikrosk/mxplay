; Structures definitions etc

			rsreset
XM_old_inst:		rs.w	1
XM_old_vol:		rs.w	1
XM_play_vol:		rs.w	1
XM_old_period:		rs.l	1
XM_play_period:		rs.l	1
XM_play_note:		rs.w	1
XM_old_note:		rs.w	1
XM_pulsar_vol:		rs.w	1
XM_fadeout:		rs.w	1
XM_venv_vol:		rs.w	1
XM_vsld:		rs.w	1
XM_porta:		rs.w	1
XM_penv:		rs.w	1
XM_pan:			rs.w	1
XM_lpan:		rs.w	1
XM_appreg_1:		rs.w	1
XM_appreg_2:		rs.w	1
XM_appreg_3:		rs.w	1
XM_appreg_flag:		rs.w	1
XM_temp_period:		rs.l	1
XM_vib_last:		rs.w	1
XM_vib_depth2:		rs.w	1
XM_vib_pos:		rs.w	1
XM_vib_rate2:		rs.w	1
XM_vib_flag:		rs.w	1
XM_tone_last:		rs.w	1
XM_org_period:		rs.l	1
XM_tone_flag:		rs.w	1
XM_tone_speed:		rs.w	1
XM_tremolo_depth:	rs.w	1
XM_tremolo_pos:		rs.w	1
XM_tremolo_rate:	rs.w	1
XM_tremolo_flag:	rs.w	1
XM_tremolo_last:	rs.w	1
XM_temp_vol		rs.w	1
XM_retrig_flag:		rs.w	1
XM_retrig_count:	rs.w	1
XM_retrig_int:		rs.w	1
XM_Sample_ptr:		rs.l	1
XM_fine_vl:		rs.w	1
XM_fine_vl2:		rs.w	1
XM_fine_pl:		rs.w	1
XM_Sample_len:		rs.l	1
XM_vib_wave:		rs.l	1
XM_tremolo_wave:	rs.l	1
XM_wave_flags:		rs.w	1
XM_inst_ptr:		rs.l	1
XM_spl_h_ptr:		rs.l	1
XM_cut_flag:		rs.w	1
_note			rs.b	1
_instrument		rs.b	1
_volume			rs.b	1
_effect			rs.b	1
_value			rs.b	1
_even_1:		rs.b	1
_even_2			rs.w	1	
XM_dont_flag:		rs.w	1
XM_note_period:		rs.l	1
XM_spl_force:		rs.w	1
XM_offset_ptr:		rs.l	1
XM_offset_flag:		rs.w	1
XM_was_flag:		rs.w	1
XM_ftune:		rs.w	1
XM_spl_raw_ptr:		rs.l	1
XM_const_period:	rs.l	1
XM_inst_init:		rs.w	1

XM_venv_pts:		rs.w	1
XM_venv_time:		rs.w	1
XM_venv_ltime:		rs.w	1
XM_venv_lsize:		rs.w	1
XM_venv_sus_flag:	rs.w	1

XM_penv_pts:		rs.w	1
XM_penv_time:		rs.w	1
XM_penv_ltime:		rs.w	1
XM_penv_lsize:		rs.w	1
XM_penv_sus_flag:	rs.w	1

XM_voice_vol:		rs.w	1

XM_delay_flag:		rs.w	1
XM_key_off:		rs.w	1

channel_size:		rs.b	1


; XM instrument description

XM_isize:		equ	0
XM_iname:		equ	4
XM_itype:		equ	26
XM_snum:		equ	27

XM_shs:			equ	29
XM_stabnum:		equ	33
XM_vol_env:		equ	129
XM_pan_env:		equ	177
XM_num_vol:		equ	225
XM_num_pan:		equ	226
XM_vol_sust:		equ	227
XM_vol_lp:		equ	228
XM_vol_elp:		equ	229
XM_pan_sust:		equ	230
XM_pan_lp:		equ	231
XM_pan_elp:		equ	232
XM_vol_type:		equ	233
XM_pan_type:		equ	234
XM_vib_type:		equ	235
XM_vib_sweep:		equ	236
XM_vib_depth:		equ	237
XM_vib_rate:		equ	238
XM_vol_fadeout:		equ	239
XM_reserved:		equ	241


; XM sample header
			rsreset
XM_spl_len:		rs.l	1
XM_spl_ls:		rs.l	1
XM_spl_ll:		rs.l	1
XM_spl_vol:		rs.b	1
XM_spl_fine:		rs.b	1
XM_spl_type:		rs.b	1
XM_spl_panning		rs.b	1
XM_spl_rnn:		rs.b	1
XM_spl_res:		rs.b	1
XM_spl_name:		rs.b	22


; XM commands

Command_Appregio:	equ	$0
Command_Porta_up:	equ	$2
Command_Porta_down:	equ	$1
Command_Tone_porta:	equ	$3
Command_Vibrato:	equ	$4
Command_Tone_vol:	equ	$5
Command_Vib_vol:	equ	$6
Command_Tremolo:	equ	$7
Command_Set_panning:	equ	$8
Command_Set_offset:	equ	$9
Command_Volume_slide:	equ	$a
Command_Set_volume:	equ	$c
Command_patt_break:	equ	$d
Command_E_comms:	equ	$e
Command_Set_tempo_BPM:	equ	$f
Command_Set_gvol:	equ	$10
Command_Slide_gvol	equ	$11
Command_Panning_sld:	equ	$19
Command_Multi_rtg:	equ	$20

Command_E_porta_up:	equ	$1
Command_E_porta_down:	equ	$2
Command_E_vib_control:	equ	$4
Command_E_Set_tune:	equ	$5
Command_E_loop:		equ	$6
Command_E_Retrig:	equ	$9
Command_E_slide_v_up:	equ	$a
Command_E_slide_v_down:	equ	$b
Command_E_cut_note:	equ	$c

XM_env_on		equ	0
XM_env_sustain		equ	1
XM_env_loop		equ	2

XM_Vib_retrig:		equ	0
XM_tremolo_retrig:	equ	1
