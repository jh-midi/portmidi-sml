(* 
DOC : read  portmidi.h from the original src for the complete view of portmidi 

or at  

http://portmedia.sourceforge.net/portmidi/doxygen/
 
HERE it is a quick getting started by experiment with portTime.

STEP BY STEP : copy/paste the following lines which endswith ';' at PolyML prompt

you can select by block also but you can get cacophony


*)


use "./portmidi.sml";
open Portmidi;

(* first  *)
initialize();

(*  
time is music => familiarizing with PortTime 
 *)
(* verify portTime  *)
ptStarted();

ptStop ();

(* set clock tick  1 ms *)
ptStart 1;

(* show clock *)
ptTime();

(* pause 2000 ms *)
ptSleep 2000;


(* now look at the devices *)
				  
val res = showDevices();

(* 
here on  Mac :
----
Gestionnaire IAC Bus 1     id=0 input=true   output=false  opened=false  interf=CoreMIDI
Gestionnaire IAC Bus 2     id=1 input=true   output=false  opened=false  interf=CoreMIDI
ATM SQ                     id=2 input=true   output=false  opened=false  interf=CoreMIDI
ATM SQ Control             id=3 input=true   output=false  opened=false  interf=CoreMIDI
Kontakt Virtual Output     id=4 input=true   output=false  opened=false  interf=CoreMIDI
Gestionnaire IAC Bus 1     id=5 input=false  output=true   opened=false  interf=CoreMIDI
Gestionnaire IAC Bus 2     id=6 input=false  output=true   opened=false  interf=CoreMIDI
ATM SQ                     id=7 input=false  output=true   opened=false  interf=CoreMIDI
ATM SQ Control             id=8 input=false  output=true   opened=false  interf=CoreMIDI
Kontakt Virtual Input      id=9 input=false  output=true   opened=false  interf=CoreMIDI
----
 here on Linux :
______
Midi Through Port-0        id=0 input=false  output=true   opened=true   interf=ALSA
Midi Through Port-0        id=1 input=true   output=false  opened=false  interf=ALSA
ATM SQ ATM SQ              id=2 input=false  output=true   opened=false  interf=ALSA
ATM SQ ATM SQ              id=3 input=true   output=false  opened=false  interf=ALSA
ATM SQ ATM SQ Control      id=4 input=false  output=true   opened=false  interf=ALSA
ATM SQ ATM SQ Control      id=5 input=true   output=false  opened=false  interf=ALSA
val it = (): unit

I choose id=0  'Midi Through Port-0'  output=true => I can output midi messages
and set out_id according
previously I have connected this port to Ardour instrument vst3 >  
Surge (fantastic synth with microtonal possibilities)

https://surge-synthesizer.github.io

*)
val out_id =0;

(*
Implementation :
 openOutput and openInput save pointer in pointers array PM_STREAMS which is indexed on device id
and after we can get this pointer with :  (getStream out_id) see "portmidi.sml"

Note : pointers are transparents for using this interface with that, 
as we can only use device Id 

- usage : openOutput devId  buffer_size latency
  *)
(* open out Kontakt 
err = 0 
=> success *)
val err = openOutput out_id 100 2;

(* first note *)
val c4 = message (144,60,100); (* note on *)
val c4' = message (0x80,60,0); (* note off *)

val err = writeShort out_id 0 c4;

val err2 = writeShort out_id 0 c4';

(* we need array buffer for writing block of messages to device *)
(* filling output buffer *)
val notes_o = [(message(0x90,60,100),0),
	       (message(0x80,60,0),900),
	       (message(0x90,64,100),1000),
	       (message(0x90,67,100),1000),
	       (message(0x80,64,0),2000),
	       (message(0x80,67,0),2000)
	       ];
(* to array *)
val notes_o' = Array.fromList notes_o;

(* latency > 0 here : 2 *)
val err = openOutput out_id 100 2;

(* write buffer *)
val error = write out_id notes_o' 6;

(*
don't ear expecting notes because  0 and 1000 ms timestamps for note on
are in the past vs portTime on Suse only first note is played then
I stop it by 
val err2 = writeShort 0 0 c4';
*)
val err2 = writeShort 0 0 c4';
(* look at clock *)
val t = ptTime();
(* => val t = 333921: int 
1000 is legacy

I have to reset the clock to 0 before playing and put a small latency to be in time.
=> write a small fun

*)

fun playo n =  ( ptStop();ptStart 1; openOutput out_id 100 2; write out_id notes_o' n);

(* play 1 note = 2 events 1st on and  2nd off *)
val erO = playo 2;
(* then play 6 events *)
val erO = playo 6;

(* another solution for being in time is to add ptTime() to each timestamp of notes list 
without touching clock or already opened device 
=>
write these another small functions should help *)
fun addPortTime_o port_time event_array =
    Array.modify (fn (msg,ts) => (msg,ts + port_time)) event_array;


fun playList_o notes_list clock = let
    val  notes_array = Array.fromList notes_list
    val modified = addPortTime_o clock notes_array
in
    write out_id  notes_array 6
end;

val erpl_o = playList_o notes_o (ptTime());

(* my addon to portmidi playing with bigbuffer JH *)
(* one tuple for message + timestamp
0x90 = note on et 0x80 note off (channel 1)
60 = C4
100 = velocity
0 for  data4 (* this can be used for tagging and mandatory for sysex *)
0 = timestamp

here I put 2 notes at the same time 1000 => chord

the two lists are here for experiment portmidi timing with timestamp
*)
(* bad timestamp ordered list - 2000 is before 0 - read portmidi doc -
but play well on Suse *)
val notes = [
	     (0x90,67,100,0,1000),
	     (0x80,67,0,0,2000),
	     (0x90,64,100,0,1000),
	     (0x80,64,0,0,2000),
	     (0x90,60,100,0,0),
	     (0x80,60,0,0,980)
	    ];

(* good *)
val notes2 = [(0x90,60,100,0,0),
	      (0x80,60,0,0,980),
	     (0x90,67,100,0,1000),
	     (0x90,64,100,0,1000),
	      (0x80,67,0,0,2000),
	      (0x80,64,0,0,2000)
	    ];

(*  bigWrite need Array buffer *)
val notes'= Array.fromList notes;

val notes2'= Array.fromList notes2;

(*  latency > 0 for use  timestamp *)
val err = openOutput out_id 100 2;

(* set time 0 before playing 
I have six messages  but I can play only 4
*)
fun play msg_array n =  ( ptStop();ptStart 1; openOutput out_id 100 5;
			  bigWrite out_id msg_array n);

(* don't play msg in time  because the initial list is bad formed : 
all timestamp should be ordered 
but it's ok with Open Suse *)
val res = play notes' 4;
val res = play notes' 6; 

val res = play notes2' 6; (* notes2 is ordered and play well on all tested platforms *)


(* second solution for good timing  => add  port_time to  timestamp *)
fun addPortTime port_time event_array =
    Array.modify (fn (stat,dat1,dat2,dat3,ts) => (stat,dat1,dat2,dat3,ts + port_time)) event_array;

(* 
playing size messages from list 
*)
fun playList notes_list size = let
    val  notes_array = Array.fromList notes_list
    val pt_time = ptTime()
    val modified = addPortTime pt_time notes_array
in
    bigWrite out_id notes_array size
end;

(* try *)
val _ = playList notes 6;

val _ = playList notes2 6;


(* 
join all with #ptSleep for serial cacophony 
*)
val _ = openOutput out_id 100 2;

fun play3 () =  (playList notes2 2 ;ptSleep 1000;playList notes2 4 ;ptSleep 1500;playList notes2 6);
val _ =play3();

fun playPlus () = (playo 2; ptSleep 1000; playo 2; ptSleep 1000; playo 4 ;ptSleep 2000;playo 6);
val _ = playPlus();

(* à vous de jouer ! *)


(* ERRORS *)
(* if you get error use - getErrorText errnum *)
val err0 = openOutput 0 100 2;
(* => val err0 = ~9999: int *)

getErrorText err0;
(*
val it = "PortMidi: `Invalid device ID'": string
surely because  output=false
Gestionnaire IAC Bus 1     id=0 input=true   output=false  opened=false  interf=CoreMIDI
*)

terminate();

print ("args : " ^ (String.concatWith ", "  (CommandLine.arguments() ) ));
print "\n";
print ("cmd : " ^ (CommandLine.name()) );
print "\n";
