 use "./PortmidiFFI.sml"; 


structure Portmidi =
struct

open PortmidiFFI 

type PmDeviceInfo' =
     {
       structVersion : int,
       interf : string,
       name : string,
       input : bool,
       output : bool,
       opened : bool,
       id: int (* for use with getDeviceId  *)
     }


	 
fun getDeviceInfo deviceID = let
    val info  = Pm_GetDeviceInfo deviceID in
    case info of
	SOME (structVersion,interf,name,input,output,opened) =>
	 {
	    structVersion = structVersion,
	    interf= interf,
	    name = name,
	    input =   (input = 1) orelse false,
	    output =  (output = 1) orelse false,
	    opened =  (opened = 1) orelse false,
	    id=deviceID
	}
      | NONE => {
	    structVersion = 0 ,
	    interf= "" ,
	    name = "",
	    input = false,
	    output = false,
	    opened =  false,
	    id = deviceID
	} 
end


(* 
here are vals to be evalued at run time
then don't convert to function
*)
val countDevices = Pm_CountDevices

val initialize  =  Pm_Initialize 
val terminate  =  Pm_Terminate 

(* not tested because I don't know how to have host error *)
fun hasHostError stream = (Pm_HasHostError stream) = 1

fun getHostErrorText taille = let
    val ar_text = List.tabulate (256,(fn x => #"*"))
    val er_txt = ref (String.implode ar_text)
    val _ = Pm_GetHostErrorText( er_txt, taille)
in
    (!er_txt)
end

							  
fun getErrorText errnum = Pm_GetErrorText (errnum)


     
(*****************  HEART OF THIS IMPLEMENTATION  ***************************** *)	 
(* 
this array of stream pointers is the register for retrieving the infos for device by Id when needed :
 for open close and get portmidi  stream at one place.
With that we can live in peace with the pointers, because we only use devices Id
 *)
(* type PmStream =  Memory.voidStar ref *)
type PmStream =  Memory.voidStar ref
				 
val stream_void = ref Memory.null

val STREAMS_COUNT = countDevices()
(* ref because we can add virtual port midi *)
val PM_STREAMS = ref ( Vector.tabulate(STREAMS_COUNT, fn x => ref Memory.null))

(* PortMidiStream pointer of pointer *)
fun getStreamPtr id = Vector.sub (!PM_STREAMS,id)

(* PortMidiStream working address *)
fun getStream id = (! (getStreamPtr id))
			  
fun setStreamPtr id (stream : PmStream) = Vector.update ( (!PM_STREAMS),id,stream)

(*****************************************************)		   
(*  pmClose pointer *)
fun pmClose streamPtr = Pm_Close streamPtr

(* for use with openOutput en openInput 
close stream and set it to *void  *)
fun close id = (pmClose ( getStream id ); setStreamPtr id (ref Memory.null) ;true)
    

fun listDevices () = let
    val _ = initialize ()
    val count = countDevices ()
    val iota = List.tabulate (count,fn x =>x)
in
    List.map (fn x => (getDeviceInfo x)) iota
end

(* show one device to human *)			 
fun showDevice (dev : PmDeviceInfo') = let
    fun fmt_bool lab = StringCvt.padRight #" " 6 ( Bool.toString (lab dev))
    val input = fmt_bool #input
    val output = fmt_bool #output 
    val opened = fmt_bool #opened 
    val id = Int.toString (#id dev)
    val to_show = [StringCvt.padRight #" " 25 (#name dev),id,input,output,opened,#interf dev]
    val labels = [ "" ,"  id=", " input="," output="," opened="," interf="]
in
    print ( ( ListPair.foldr (fn (a,b,accu) => a^b^accu) "" (labels,to_show) ) ^ "\n" )
end

(* show all devices to human *)
fun showDevices () =  List.app showDevice ( listDevices() )

(* get device id  : 'what' is  "#output | #input | #opened | #interf" 
*)
fun getDeviceId name what  = let
    val devices = listDevices()
    val dev = List.filter (fn x => (#name x) = name andalso (what x)) devices
in
    if  List.null dev then [~1] else List.map #id  dev
end

fun getDeviceInputId name = List.hd (getDeviceId name #input)

fun getDeviceOutputId name = List.hd (getDeviceId name #output)

(* add pointer in pointers vector if needed *)
fun updateStreamPointers id =
    if  Vector.length (!PM_STREAMS) <=id
    then
	let val nouveau = ref (Vector.fromList[ref Memory.null])
	in
	    PM_STREAMS :=  Vector.concat [(!PM_STREAMS), (!nouveau)]
	end
    else ()
		       
				     
(* return device id *)
fun createVirtualOutput name  = 
    let val id = Pm_CreateVirtualOutput (name, Memory.null, Memory.null)
    in
	updateStreamPointers id;
	id
    end
   				
fun createVirtualInput name  = 
   let val id = Pm_CreateVirtualInput (name, Memory.null, Memory.null) 
   in
       updateStreamPointers id;
       id
   end		

fun deleteVirtualDevice id = (close id; Pm_DeleteVirtualDevice(id))


(* if latency > 0, we need a time reference. If none is provided,
       use PortTime library - comment extracted from portmidi.c - 
*)
(*  

solution to help to retrieve already opened stream 
if it is already opened then reinit  *)

(* 
1 st version open stream and if it is already open => close it and reinit
but I choose to verify if its latency and buffer size is the same
as required then conserve and use it
TODO
 *)			     
fun openOutput id buffer_size latency = let 
    val stream = getStreamPtr id
    val opened = #opened (getDeviceInfo id)
    val _ = not opened orelse close id 
    val pm_error = pm_OpenOutput (stream, id, Memory.null, buffer_size , Memory.null, Memory.null,latency)
in
    (
      setStreamPtr id (ref (!stream))
    ; pm_error
    )
end

(* test one note immediate

val c3 = message (0x90, 60, 100);
openOutput 4 100 0; (* latence = 0 *)
writeShort  4 0 note;

(*  note-off *)
val c3' = message (0x80, 60, 0);
writeShort  4 0 c3';


*)
					    
fun openInput id buffer_size = let 
    val stream = getStreamPtr id
    val opened = #opened (getDeviceInfo id)
    val _ = not opened orelse close id
    val pm_error = pm_OpenInput (stream, id, Memory.null, buffer_size , Memory.null, Memory.null)
in
    (
      setStreamPtr id  ( ref (!stream))
    ; pm_error)
end

(* test 
openInput 2 100;

val buf2 =  bufferNew 4; (* 2 notes *)
=> val buf2 = fromList[(0, 0), (0, 0), (0, 0), (0, 0)]: (int * int) array 

read  2 buf2 4;
=> val it = 4: int
buf2;
=> val it = fromList[(3933328, 4302877), (1152, 4302992), (2361232, 4303411),
      (1920, 4303518)]: (int * int) array

poll  2; 
=> true

read  2 buf2 4;
=> 2
buf2;
=> val it = fromList[(6686352, 4303808), (1664, 4303901), (2361232, 4303411),
      (1920, 4303518)]: (int * int) array
*)

				   
(* tuple as arg because I want to pass it to the function *)
fun message (status, data1, data2) =
    LargeInt.toInt (
	IntInf.orb (
	    (IntInf.orb(IntInf.andb((IntInf.<< (Int.toLarge(data2), 0w16)), 0xFF0000),
			IntInf.andb((IntInf.<< (Int.toLarge(data1), 0w8)),0xFF00))),
	    IntInf.andb(Int.toLarge(status),0xFF))
    )

(* 
writeShort  4 0  ( message (0x80, 60, 0) );
 *)
fun writeShort out_id  when  msg  =  Pm_WriteShort (getStream out_id,when, msg)
 

(* 
val syx = createSysex "F0 00 21 1D 01 01 1F F7";
writeSysex 4 0 syx;
 *)
fun createSysex text = let
    val ltext = String.tokens Char.isSpace text
    val listInt = List.map (fn x => Word8.toInt(valOf(Word8.fromString x))) ltext
in
    implode (List.map (fn x => chr(x)) listInt)
end

			
fun writeSysex id_out when sysex = Pm_WriteSysEx (getStream id_out,when,sysex)

fun messageStatus msg = IntInf.andb(msg,0xFF)
fun messageData1 msg = IntInf.andb(IntInf.~>>(msg,0w8),0xFF)
fun messageData2 msg = IntInf.andb(IntInf.~>>(msg,0w16),0xFF)
				  
fun messageType msg =  IntInf.andb(msg,0xF0)

(*
  poll  2;
*)
fun poll id_in = Pm_Poll (getStream id_in) = 1

type PmEvent = {
    message : int,
    timestamp : int
}
		   
type Event = int*int



(* buffer needed for read and write events by packets 
we can also use Array.fromList cf test upward *)
fun bufferNew taille = Array.array(taille, (0,0))

fun bufferSet buffer index  (ev : Event) =  Array.update (buffer,index,ev) 

(*
val notes = Array.array (2, ( message(0x90,60,100),0 ));
val _ = bufferSet notes 1 ( message(0x80,60,0),1000 ) ;
val err = write  4 notes 2;
*)
		     
(* Pm_Write( PortMidiStream *stream, PmEvent *buffer, long length ); *)
fun write id_out buffer len = Pm_Write (getStream id_out ,buffer,len)

fun read id_in buffer len = pm_Read (getStream id_in, buffer, len)

fun setFilter (id_in, filter) = Pm_SetFilter (getStream id_in,filter)

(* logior list *)
fun logior list_int =
    Int.fromLarge ( List.foldr (fn (x,acc) => (IntInf.orb ((Int.toLarge x),acc))) (Int.toLarge 0)  list_int)

(* filter for input stream I don't see effect on output *)
fun filter elem = Word.toInt (Word.<< (0wx1,Word.fromInt elem) )
				  
val filt_active = filter 0x0E 
val filt_sysex = filter 0x00 
val filt_clock = filter 0x08
val filt_play = logior [filter 0x0a,filter 0x0C,filter 0x0B] 
val filt_tick = filter 0x09 
val filt_fd = filter 0x0D
val filt_undefined = filt_fd
val filt_reset = filter 0x0F
val filt_realtime =  logior [filt_active, filt_sysex,filt_clock, filt_play, filt_undefined, filt_reset,filt_tick]
val filt_note = logior [filter 0x19,filter 0x18] 
val filt_channel_aftertouch = filter 0x1D
val filt_poly_aftertouch = filter 0x1A
val filt_aftertouch = logior [filt_channel_aftertouch, filt_poly_aftertouch]
val filt_program = filter 0x1C
val filt_control = filter 0x1B 
val filt_pitchbend = filter 0x1E 
val filt_mtc = filter 0x01
val filt_song_position = filter 0x02 
val filt_song_select = filter 0x03
val filt_tune = filter 0x06
val filt_systemcommon = logior [filt_mtc, filt_song_position, filt_song_select, filt_tune]

(* 16 bits mask *)
fun pmChannel channel = Word.toInt ( Word.<< (0wx1,Word.fromInt channel))
(* 
setChannelMask  (4, pmChannel 0);

" Note that channels are numbered 0 to 15 (not 1 to 16). Most 
    synthesizer and interfaces number channels starting at 1, but
    PortMidi numbers channels starting at 0."
*)
fun setChannelMask (id_in, mask) =  Pm_SetChannelMask (getStream id_in, mask)

						    
(* portTime start *)
fun ptStarted () = Pt_Started () = 1 
fun ptStart resolution = Pt_Start (resolution,Memory.null,Memory.null)
fun ptStop () = Pt_Stop ()
fun ptTime () = Pt_Time ()
fun ptSleep duration = Pt_Sleep (duration)
    
		     
(* JH
big buffer usable for read and write events directly
we can also use Array.fromList for writing
 *)
type BigEvent =
     {
       status : int,
       data1 : int,
       data2 : int,
       data3 : int,
       timestamp : int
     }
				  
type Bevent =  int*int*int*int*int
				    
fun bigBufferNew taille = Array.array(taille, (0,0,0,0,0))

fun bigBufferSet big_buffer index  (big_ev : Bevent) =  Array.update (big_buffer,index,big_ev) 

fun bigRead id_in big_buffer len = big_Read (getStream id_in, big_buffer, len)

fun bigWrite id_out big_buffer len = big_Write (getStream id_out,big_buffer,len)

(*
val buf1 = ref (0,0,0,0,0);
val err = read1 2 buf1 ;
*)
fun read1 id_in buffer1 =  pm_Read1 (getStream id_in, buffer1, 1)

(*
write1  4 (0x80,60,120,0,100);
*)
fun write1 id_out buffer1 = pm_Write1 (getStream id_out,buffer1, 1)
				      
end

