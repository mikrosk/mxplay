***********************
*** Music-Mon V2.1a ***
***********************

Release-Date 21.08.2005

This is a bugfixed version of Music-Mon V2.1 which had been released on 06.02.2005. 

Bugfixes are basically concerning the replay routine, but also the editor got a bugfix:

Replay:

	1) Timing regarding 50/100/200Hz sounds was wrong in some constellations
	2) triangle waveform of AMD (S+N) was incorrect
	3) triangle waveform of PMD (WAVE) was incorrect

	These bugs existed already in the 2.0 replay. A new version of the replay
	fixing these bugs had been released on 07.07.2005 on DHS.

	new bugfix of this release:

	4) crashes or freaky noises caused by special constellations where successive
 	   digi notes of same sound# without any synth-note between on Channel A 
	   were combined with Sids / Sync-Buzzers on Channels B and C in a particular
	   sequence. This bug was uncovered by Marcer.

Editor:
	
	1) Filenames with more than one dot in (e.g. Music.sng.bak) confused 
	   the file-selector. Filenames with multiple dots in are actually only
 	   possible in emulation environments so this is not an issue on real machines
	   (at least the traditional ones). 


-------------------------------------------------------------------------------------------

Transcript of the scroller text:

"Hi folks, just some weeks after the release of MusicMon 2.0 SID 
here is the next one with the following new features: 

	* Sync-Buzzers 

	* Improved SID syncing 

	* Range of PMD Hardwave Depth extended to 63 (previously 15) 

	* Pitch-Bend can now be applied also to Hardwave (very important for 
	  sync-buzzers but also usefull for normal buzzers) 

	* Overlay/Underlay Paste Feature (SHIFT + 'U' / 'O') 

	* Entering of song- and soundname can now be canceled by 'ESC' key 
	  (small issue but it was just nasty when accidentally klicking into the 
	   sound/song name field with left instead of right mouse-key) 

	* Starts also from ST med res now

	* Support of 'Install Application...' (.SNG extension)

	* SMC-free replay routine with free configurable timer use 

	* 100% backward compatible to all previous MusicMon versions 

Small introduction:          

The hardwave menu offers a new sync alternative activated by the new purple
button 'S. 3'. Once activated it applies periodically sync on hardwave 
providing the sync buzzer effect. The frequency of the sync generator
behaves in the same way as the SID square generator does (but is driven 
one octave lower). Same as for SID generator, only Arpeggio affects the
generator frequency, but Pitch Bend or PMD do not. Sync Buzzer feature 
cannot be combined with SID so activating 'S. 3' automagically switches
off SID and vice versa. 

Most important on Sync-Buzzer sounds is smart modulation of hardwave 
frequency as you surely know already. So now, the pitch bend generator
can also be applied to the hardwave by the new button 'A.P.B.' 
(Apply Pitch Bend). The Frequency offset of pitch-bend is divided by 16
to achieve a match with the PSG square frequency (so slides of normal 
buzzer sounds sound also correctly). That means, a speed of 16 
corresponds to a continous frequency slide each 1/50 s, 1/100 s, 1/200 s.          
Beyond that, the PMD Depth for Hardwave has been extended to 63 which 
provides also additional possibilities. 

It's worth experimenting with fixed hardwave-frequency or high 
main-tune values also... You can also produce interesting arpeggio sounds...

Thanks to gwem and tao for providing me some hints regarding 
the sync buzzer effect...           

Thanks to stu for intensive beta testing...

Thanks to stu, drx, Marcer and Nexus 6 for donating demo songs...                     

Thanks to Cyclone for assisting me in switching the screen resolution
and sending me a code snippet about fetching command line arguments...

Some words about the replay routine:        

The focus was to deliver a system friendly routine running on any machine.
Regarding performance there is some room for improvement. So if you have 
a particular need for squeezing out the last cycle out of it you might 
convince me to provide customized versions using SMC and/or reserved 
registers...      

Ok, that's all for now... Have fun! And watch out for forthcoming 
releases which maybe will come..."


Dark Angel 
	alias
	    Frank Lautenbach

