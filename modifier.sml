use "portmidi.sml";
open Portmidi;

fun waitMicros us = OS.Process.sleep ( Time.fromMicroseconds (Int.toLarge us))

(* 
I use it on Presonus ATOM for getting all messages on midi port 1 
because on Atom the channels are strangely distribued
you can play note on channel 1 but aftertouch rest on channel 10
and if you configure setup to use CC pressure then channel is forced at 2
and CC rotatives stay on channel 1

I just replace status by message type then all go to channel 1 - portmidi 0 -
here I set also velocity to fixed value 100 is good for me
but if I put 0 to velocity I keep original

I prefere that when using Ardour for example
Ardour-Jack  get input via "Midi Through Port-0"
then what we have to do is to redirect Atom to it

(*
showDevices();
Midi Through Port-0        id=0 input=false  output=true   opened=true   interf=ALSA
Midi Through Port-0        id=1 input=true   output=false  opened=false  interf=ALSA
ATM SQ ATM SQ              id=2 input=false  output=true   opened=false  interf=ALSA
ATM SQ ATM SQ              id=3 input=true   output=false  opened=true   interf=ALSA
ATM SQ ATM SQ Control      id=4 input=false  output=true   opened=false  interf=ALSA
ATM SQ ATM SQ Control      id=5 input=true   output=false  opened=false  interf=ALSA
qjackctl                   id=6 input=false  output=true   opened=false  interf=ALSA
val it = (): unit
*)

id=3 > transform >  id=0
scan_latency is in microSeconds for competition

Control-C => quit
*)
fun transform name_in name_out velocity scan_latency =  let
    val id_in = getDeviceInputId name_in
    val id_out = getDeviceOutputId name_out
    val timeOut = ref 1
    val er_in= openInput id_in 100
    val er_out = openOutput id_out 100 0 (* latency = 0 for real time *)
    val buf1 = ref (0,0,0,0,0)
    val _ = showDevices()
    val scan_latency' = Time.fromMicroseconds (Int.toLarge scan_latency)
in
    while  (!timeOut) > 0 do (
	  OS.Process.sleep scan_latency' ; (* 100% to 5 % processor usage on i7 with 2000 us *)
	    if (read1 id_in buf1) = 1 then
		let val (status,data1,data2,data3,ts) = (!buf1)
		    val new_status = Int.fromLarge (messageType (Int.toLarge status) )
		    val data2' = if new_status = 0x90 andalso velocity > 0 
				 then velocity (* change data2 when note on *)
				 else data2 
		in
		  (  write1 id_out (new_status,data1,data2',data3,ts) )
		end
		    else 0
	
	  )  
end



(* poly --script modifier.sml" *)
			      
(* 
uncomment for scripting 

and comment for compiling *)

(* velocity 100 							    
val err =  transform "ATM SQ ATM SQ" "Midi Through Port-0" 100 2000 			      
*)
(* keep velocity *)
(*
val err =  transform "ATM SQ ATM SQ" "Midi Through Port-0" 0 2000		
*)



(* to compile : 
 > polyc -o toChan1 modifier.sml  
then

> ./toChan1 "ATM SQ ATM SQ"
usage : ./toChan1 <midi-input-name> <midi-output-name> [<velocity>:0=same as input] [<scan-latency-microseconds>:2000>]

> ./toChan1 "ATM SQ ATM SQ" "Midi Through Port-0"

> ./toChan1 "ATM SQ ATM SQ" "Midi Through Port-0" 100 3000 
*)
							    
		      
fun main() = let
    val args = CommandLine.arguments()
    val name = CommandLine.name()
    val taille = length args
    val usage = "\nusage : " ^ name ^ " <midi-input-name> <midi-output-name> [<velocity>:0=same as input] [<scan-latency-microseconds>:2000>]\n"
in
    if taille < 2 then
	(
	  showDevices();
	  print usage;
	  waitMicros 2000
	)

	else let
	    val velocity = if taille > 2 then valOf ( Int.fromString (List.nth ( args, 2))) else 0
	    val scan_time  = if taille > 3 then valOf ( Int.fromString (List.nth ( args, 3))) else 2000
	in
	    transform (List.nth (args, 0)) (List.nth (args, 1)) velocity scan_time
	end
end
