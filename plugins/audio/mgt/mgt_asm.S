; mgt plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		INCLUDE	"../mxplay.inc"

		XDEF	_mgt_parameter

		XREF	_mgt_register_module
		XREF	_mgt_get_playtime
		;XREF	_mgt_get_songs
		XREF	_mgt_init
		XREF	_mgt_set
		;XREF	_mgt_feed
		XREF	_mgt_unset
		XREF	_mgt_deinit
		;XREF	_mgt_pause
		;XREF	_mgt_mute

		XREF	_mgt_info
		XREF	_mgt_extensions
		XREF	_mgt_settings

		XDEF	_mgt_settings_name_get
		XDEF	_mgt_settings_channels_get

		XREF	_g_moduleBuffer

		dc.l	"MXP2"
_mgt_parameter:	ds.l	1
		dc.l	_mgt_register_module
		dc.l	_mgt_get_playtime
		dc.l	0			; _mgt_get_songs
		dc.l	_mgt_init
		dc.l	_mgt_set
		dc.l	0			; _mgt_feed
		dc.l	_mgt_unset
		dc.l	_mgt_deinit
		dc.l	0			; _mgt_pause
		dc.l	0			; _mgt_mute
		dc.l	_mgt_info
		dc.l	_mgt_extensions
		dc.l	_mgt_settings

			RsReset
MGT_Chunk		rs.b	3		; "MGT"
MGT_Version		rs.b	1		; $11, $xy pour Version x.y
MGT_Copyright		rs.b	4		; "œMCS"
MGT_Nb_Voices		rs.w	1		; Nombre de Voies
MGT_Nb_Musics		rs.w	1		; Nombre de Musiques
MGT_Nb_Orders		rs.w	1		; Nombre de Positions
MGT_Nb_Patterns		rs.w	1		; Nombre de Patterns
MGT_Nb_Tracks		rs.w	1		; Nombre de Pistes sauves (sans la 0)
MGT_Nb_Samples		rs.w	1		; Nombre de Samples
MGT_Attributes		rs.w	1		; Inutilis pour l'instant
MGT_Reserved		rs.l	1		; Rserv pour le futur

MGT_Musics		rs.l	1		; Adresse des Musics
MGT_Sequences		rs.l	1		; Adresse des Sequences
MGT_Samples_Infos	rs.l	1		; Adresse des Infos Samples
MGT_Patterns		rs.l	1		; Adresse des Patterns
MGT_Tracks_Ptr		rs.l	1		; Adresse des Pointeurs de Piste
MGT_Samples_Data	rs.l	1		; Adresse des Donnes Samples
MGT_Samples_Length	rs.l	1		; Longueur Totale des Samples
MGT_Tracks_Length	rs.l	1		; Longueur des Tracks Dpackes

			RsReset
Music_Name		rs.b	32		; Nom de la Musique
Music_Sequence		rs.l	1		; Adresse de la Sequence
Music_Length		rs.w	1		; Longueur de la Sequence
Music_Restart		rs.w	1		; Position de Rebouclage
Music_Initial_Tempo	rs.b	1		; Tempo initial
Music_Initial_Speed	rs.b	1		; Vitesse initiale
Music_Initial_Global	rs.w	1		; Volume Global de Fade-Out initial
Music_Initial_Master_L	rs.b	1		; Volumes Master Gauche et Droit
Music_Initial_Master_R	rs.b	1		; de 0  255, Volume Normal = 32
Music_Initial_Stereos	rs.w	0		; Nb_Voices

			RsReset
Sample_Name		rs.b	32		; 32 caractres

Sample_Start		rs.l	1		; Adresse dbut du Sample
Sample_Length		rs.l	1		; Taille du sample en units
Sample_Loop_Start	rs.l	1		; Offset dbut Boucle en units
Sample_Loop_Length	rs.l	1		; Taille de la Boucle en units
Sample_Buffer_Length	rs.l	1		; Taille Minimale du Buffer en units
Sample_End_Length	rs.l	1		; Taille de la fin du sample aprs le buffer

Sample_Base		rs.l	1		; Frquence de Replay pour le DO-4
Sample_Volume		rs.w	1		; Volume par dfaut de 0  1024
Sample_Panoramic	rs.b	2		; Volumes Gauche et Droit de 0  255
						; par dfaut, 0 si y'en a pas
Sample_Attributes	rs.b	1		; bits 0 et 1 : Loop Mode -->
						;  0 = Loop Off,  1 = Forward Loop
						;  2 = Ping-Pong Loop, 3 rserv

Sample_Fine_Tune	rs.b	1		; de 0  15  =  0  7 et -8  -1

			rs.b	1		; Inutilis
Sample_Drum_Note	rs.b	1		; Informations stockes
Sample_Drum_Volume	rs.b	1		; par le Tracker
Sample_Drum_Command	rs.b	1		; pour le mode
Sample_Drum_Parameter	rs.w	1		; Drum Edit

Sample_Midi_Note	rs.l	1		; Note au format MIDI
Sample_Reserved		rs.l	1		; 4 octets Rservs

Sample_Size		rs.b	0		; 80 octets


_mgt_settings_name_get:
		movea.l	_g_moduleBuffer,a0
		adda.l	(MGT_Musics,a0),a0	; song #0
		lea	(Music_Name,a0),a0
		clr.b	(31,a0)			; terminate it
		move.l	a0,_mgt_parameter

		moveq	#MXP_OK,d0
		rts

_mgt_settings_channels_get:
		movea.l	_g_moduleBuffer,a0
		clr.l	d0
		move.w	(MGT_Nb_Voices,a0),d0
		move.l	d0,_mgt_parameter

		moveq	#MXP_OK,d0
		rts

sample_get	MACRO
		XDEF	_mgt_settings_sample\1_get
_mgt_settings_sample\1_get:
		movea.l	_g_moduleBuffer,a0
		move.w	#\1-1,d0		; zero indexed
		cmp.w	(MGT_Nb_Samples,a0),d0
		bge.b	.no_more
		mulu.w	#Sample_Size,d0
		adda.l	(MGT_Samples_Infos,a0),a0
		adda.l	d0,a0			; sample #n

		lea	(Sample_Name,a0),a0
		clr.b	(31,a0)			; terminate it
		move.l	a0,_mgt_parameter

		moveq	#MXP_OK,d0
		rts

.no_more:	moveq	#MXP_ERROR,d0
		rts
		ENDM

		sample_get 1
		sample_get 2
		sample_get 3
		sample_get 4
		sample_get 5
		sample_get 6
		sample_get 7
		sample_get 8
		sample_get 9
		sample_get 10
		sample_get 11
		sample_get 12
		sample_get 13
		sample_get 14
		sample_get 15
		sample_get 16
		sample_get 17
		sample_get 18
		sample_get 19
		sample_get 20
		sample_get 21
		sample_get 22
		sample_get 23
		sample_get 24
		sample_get 25
		sample_get 26
		sample_get 27
		sample_get 28
		sample_get 29
		sample_get 30
		sample_get 31
