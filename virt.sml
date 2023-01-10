(* named virtual port *)
use "./portmidi.sml";
open Portmidi;

(* use with
virtual-portmidi diato &
fluidsynth Gaillard.sf2 -m alsa_seq -p diato
*)

(*
fun clean (diatout,diatin) =
      (deleteVirtualDevice diatout;
       deleteVirtualDevice diatin;
       terminate())
*)

fun testExists id =
    if id >= 0 then (* good id *)
	let val infos = getDeviceInfo id
	    val name = #name infos
	    val isOutput =  #output infos
	    val isInput = #input infos
	    val direction = if isOutput then " output" else if isInput then " input" else "inconnu"
	in print ("Virtual Portmidi : " ^ name ^ direction ^ " created\n")
	end
    else (* error *)
	print (getErrorText id ^ "\n")

fun main () =
    let  val dum1 = initialize()
	 val dum = ptStart 1
	 val args = CommandLine.arguments()
	 val name = List.hd args
	 val diatout = createVirtualOutput name 
	 val dum = testExists diatout (* print result *)
	 val diatin = createVirtualInput name 
	 val dum = testExists diatin (* print result *)
	 val err_in = openInput diatin 100
	 val err_out = openOutput diatout 100 2
	 val buf1 = ref (0,0,0,0,0) (* one event storage *)
in 
    while (true) do (
	ptSleep 1; (* reduce cpu usage *)
	if (poll diatin  )  then (
	    read1 diatin buf1 ;
	    write1 diatout (!buf1)
	)
	else 1
    )
end

