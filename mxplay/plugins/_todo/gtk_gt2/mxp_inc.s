; ==================================
; === mxPlay plugin return codes ===
; ==================================

MXP_ERROR		EQU	0
MXP_OK			EQU	1
MXP_UNIMPLEMENTED	EQU	2

; ===========================
; === mxPlay plugin flags ===
; ===========================

MXP_FLG_USE_DSP		EQU	1<<0			; plugin uses DSP
MXP_FLG_USE_DMA		EQU	1<<1			; plugin uses DMA sound system
MXP_FLG_USE_020		EQU	1<<2			; plugin uses 020+ CPU
MXP_FLG_USE_FPU		EQU	1<<3			; plugin uses FPU

MXP_FLG_INFOLINE	EQU	1<<30			; show on infoline, too
MXP_FLG_MOD_PARAM	EQU	1<<31			; module parameter else plugin parameter

; ================================
; === mxPlay plugin structures ===
; ================================

mxp_struct_info:
			RSRESET
mxp_struct_info_plugin_author:	RS.L	1		; pointer to plugin's author
mxp_struct_info_plugin_version:	RS.L	1		; pointer to plugin's version
mxp_struct_info_replay_name:	RS.L	1		; pointer to replay's name
mxp_struct_info_replay_author:	RS.L	1		; pointer to replay's author
mxp_struct_info_replay_version:	RS.L	1		; pointer to replay's version
mxp_struct_info_flags:	RS.L	1			; plugin's resources (see also: MXP_FLG_*)

mxp_struct_settings:
			RSRESET
mxp_struct_settings_name:
			RS.L	1			; pointer to parameter's name or 0
mxp_struct_settings_type:
			RS.L	1			; type of parameter
							; 0: in/out: bool (0/1)
							; 1: in/out: pointer to string representing a text
							; 2: in/out: pointer to string representing a number
mxp_struct_settings_routine_set:
			RS.L	1			; pointer to routine which set the parameter (or 0)
mxp_struct_settings_routine_get:
			RS.L	1			; pointer to routine which get the parameter
			

mxp_struct_extensions:
			RSRESET
mxp_struct_extensions_string:
			RS.L	1			; pointer to extension-string (e.g. "AM") or 0
mxp_struct_extensions_name:
			RS.L	1			; pointer to name-string (e.g. "ACE Module")
			
; =============================
; === mxPlay plugin indices ===
; =============================

; Name:    Plugin header.
; Purpose: Compare to this 4 characters to verify you want to use right plugin.
; Input:   -
; Output:  -
MXP_PLUGIN_HEADER	EQU	0*4

; Name:    Parameter for input.
; Purpose: Here you have to write value/pointer for the routine you call.
; Input:   -
; Output:  -
MXP_PLUGIN_PARAMETER	EQU	1*4

; Name:	   Module registration.
; Purpose: Let the plugin know where can find music module.
; Input:   Music module address.
; Output:  Return code.
MXP_PLUGIN_REGISTER_MOD	EQU	2*4

; Name:	   Module validation.
; Purpose: MXP_OK means module is replayable by the plugin.
; Input:   -
; Output:  Return code.
MXP_PLUGIN_CHECK_MOD	EQU	3*4

; Name:	   Get module play time.
; Purpose: Get the more or less accurate play time in seconds.
; Input:   -
; Output:  Play time.
MXP_PLUGIN_PLAYTIME	EQU	4*4

; Name:	   Plugin initialization.
; Purpose: Alloc buffers, generate tables, etc.
; Input:   -
; Output:  Return code.
MXP_PLUGIN_INIT		EQU	5*4

; Name:    Plugin set.
; Purpose: Set up hw registers & play music.
; Input:   -
; Output:  Return code.
MXP_PLUGIN_SET		EQU	6*4

; Name:    Plugin unset.
; Purpose: Stop music & restore registers
; Input:   -
; Output:  Return code.
MXP_PLUGIN_UNSET	EQU	7*4

; Name:    Plugin deinitialization.
; Purpose: Free buffers.
; Input:   -
; Output:  Return code.
MXP_PLUGIN_DEINIT	EQU	8*4

; Name:    Music forward.
; Purpose: Forward music for a while.
; Input:   
; Output:  Return code.
MXP_PLUGIN_MUSIC_FWD	EQU	9*4

; Name:    Music rewind.
; Purpose: Rewind music for a while.
; Input:   
; Output:  Return code.
MXP_PLUGIN_MUSIC_RWD	EQU	10*4

; Name:    Music pause.
; Purpose: Pause music and free resources.
; Input:   -
; Output:  Return code.
MXP_PLUGIN_MUSIC_PAUSE	EQU	11*4

; Name:    Plugin information.
; Purpose: Pointer to structure with information about plugin. (see also: mxp_struct_info)
; Input:   -
; Output:  -
MXP_PLUGIN_INFO		EQU	12*4

; Name:    Supported module extensions by plugin.
; Purpose: Pointer to structure-field with file extensions which plugin supports. (see also: mxp_struct_extensions)
; Input:   -
; Output:  -
MXP_PLUGIN_EXTENSIONS	EQU	13*4

; Name:    Plugin settings structure.
; Purpose: Pointer to structure-field with optional replay parameters. (see also: mxp_struct_settings)
; Input:   -
; Output:  -
MXP_PLUGIN_SETTINGS	EQU	14*4
