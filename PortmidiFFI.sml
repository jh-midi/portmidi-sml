val _ = if OS.Process.getEnv "OS" = SOME "Windows_NT"  then 
	    use "./winSysName.sml"
	else
	    use "./posixSysName.sml";


structure PortmidiFFI =
struct 

open Foreign

 
(* 
selectionned libraries are in dir ./libs
these libs are tested on Windows, Arch Linux and Suse 
I tested Ubuntu Studio but abandon it because with portmidi it don't recognize timestamp.
For PolyML the better is to compile it yourself 
*)
fun getLibMidi () = let
    val my_lib_dir = ref ""
    val sys_name = getSysName () 
    fun join f = OS.Path.joinDirFile {dir= !my_lib_dir,file=f} 
    val root_dir = OS.FileSys.getDir()
    val _ = (OS.FileSys.chDir "libs";my_lib_dir := OS.FileSys.getDir();OS.FileSys.chDir ".." )
in
    case sys_name  of
       "Darwin" =>  join "libportmidi.dylib"
      | "Linux" =>   join "libportmidi.so"
      | "Windows"  =>   "./portmidi.dll"
      | _ => "inconnu"
end

val libPortmidi = loadLibrary (getLibMidi()) 
val libPortTime = libPortmidi



(************************** portTime ****************************************)
val Pt_Started = buildCall0 ((getSymbol libPortTime "Pt_Started"), (),cInt32)
(*  Pt_Start(int resolution, PtCallback *callback, void *userData) *)
val Pt_Start = buildCall3 ((getSymbol  libPortTime "Pt_Start"),
			   (cInt32,cPointer,cPointer),cInt32)
val Pt_Stop = buildCall0 ((getSymbol  libPortTime "Pt_Stop"), (),cInt32)
val Pt_Time =  buildCall0 ((getSymbol  libPortTime "Pt_Time"), (),cInt32)
val Pt_Sleep  = buildCall1 ((getSymbol  libPortTime "Pt_Sleep"),cInt32, cVoid)
(************************** porttime end *************************************)			   
(* the raw lib interface *)

val PortMidiStream = cPointer
			      
val Pm_Initialize =  buildCall0 ((getSymbol libPortmidi "Pm_Initialize"), (), cInt32) 

val Pm_Terminate =  buildCall0 ((getSymbol libPortmidi "Pm_Terminate"), (), cInt32) 

val Pm_HasHostError =  buildCall1  ((getSymbol libPortmidi "Pm_HasHostError") ,PortMidiStream ,cInt32)

val Pm_GetHostErrorText =  buildCall2 ((getSymbol libPortmidi "Pm_GetHostErrorText"), (cStar cString , cUint), cVoid )

val Pm_GetErrorText =   buildCall1  ((getSymbol libPortmidi "Pm_GetErrorText") ,cInt32, cString)

				      
(*
typedef struct {
    int structVersion; /**< this internal structure version */ 
    const char *interf; /**< underlying MIDI API, e.g. MMSystem or DirectX */
    const char *name;   /**< device name, e.g. USB MidiSport 1x1 */
    int input; /**< true iff input is available */
    int output; /**< true iff output is available */
    int opened; /**< used by generic PortMidi code to do error checking on arguments */

} PmDeviceInfo;
*)
val PmDeviceInfo = cConstStar (cStruct6 (cInt32,cString,cString,cInt32,cInt32,cInt32))

(*
typedef struct {
    PmMessage      message;
    PmTimestamp    timestamp;
} PmEvent;
*)
val PmEvent = cStruct2 (cInt32,cInt32) (* mirror of PmEvent C structure *)

(* cOptionPtr is used here because this function can return  NULL pointer *)		    
val Pm_GetDeviceInfo  = buildCall1  ((getSymbol libPortmidi "Pm_GetDeviceInfo"), cInt32 , cOptionPtr(PmDeviceInfo))

val Pm_CountDevices = buildCall0 ((getSymbol libPortmidi "Pm_CountDevices"), (), cInt32) ()

				 
val pm_OpenOutput =  buildCall7 ((getSymbol libPortmidi "Pm_OpenOutput"),
				 (cStar PortMidiStream, cInt32,cPointer,cInt32,cPointer,cPointer,cInt32), cInt32)

val pm_OpenInput =  buildCall6 ((getSymbol libPortmidi "Pm_OpenInput"),
				( cStar PortMidiStream, cInt32,cPointer,cInt32,cPointer,cPointer), cInt32)
			       
val Pm_SetFilter = buildCall2 ((getSymbol libPortmidi "Pm_SetFilter"), (PortMidiStream, cInt32) , cInt32)

val Pm_SetChannelMask =  buildCall2 ((getSymbol libPortmidi "Pm_SetChannelMask"), (PortMidiStream, cInt32) , cInt32)
			    
val Pm_Abort = buildCall1 ((getSymbol libPortmidi "Pm_Abort"),PortMidiStream,cInt32)
			  
val Pm_Close = buildCall1 ((getSymbol libPortmidi "Pm_Close"),PortMidiStream,cInt32)
			  
val Pm_Synchronise =  buildCall1 ((getSymbol libPortmidi "Pm_Synchronize"),PortMidiStream,cInt32)

val pm_Read = buildCall3 ((getSymbol libPortmidi "Pm_Read"),
			  ( PortMidiStream, cArrayPointer PmEvent, cInt32),cInt32)


			 
val Pm_Poll = buildCall1 ((getSymbol libPortmidi "Pm_Poll"), PortMidiStream,cInt32)

val Pm_Write = buildCall3 ((getSymbol libPortmidi "Pm_Write"),
			   (PortMidiStream,cArrayPointer PmEvent,cInt32),cInt32)



			  
val Pm_WriteShort = buildCall3 ((getSymbol libPortmidi "Pm_WriteShort"),
				(PortMidiStream,cInt32,cInt32),cInt32)
			       
val Pm_WriteSysEx =  buildCall3 ((getSymbol libPortmidi "Pm_WriteSysEx"),
				 (PortMidiStream,cInt32,cString),cInt32)


				


(* 
JH : experimental status data1 data2 0 timestamp 
all values are  usables with write and read without conversion 
status,data1,data2,data3,timestamp
data3 is used only by sysex
 *)
(* sizeOf Big_Event  = sizeOf PmEvent *)			 
fun sizeof obj = let
    val {store=storeStruct, load=loadStruct, ctype = {size = sizeStruct, ...}, ... } = breakConversion obj
in
    sizeStruct
end
		
val  Big_Event = cStruct5 (cUint8,cUint8,cUint8,cUint8,cInt32) 

val big_Read = buildCall3 ((getSymbol libPortmidi "Pm_Read"),
			     ( PortMidiStream, cArrayPointer  Big_Event, cInt32),cInt32)

val big_Write = buildCall3 ((getSymbol libPortmidi "Pm_Write"),
			    (PortMidiStream,cArrayPointer Big_Event,cInt32),cInt32)

(* 
read1 and write event one by one
val inputBuffer = ref (0,0,0,0,0)
*)

val pm_Read1 = buildCall3 ((getSymbol libPortmidi "Pm_Read"),
	      ( PortMidiStream, cStar Big_Event, cInt32),cInt32) 
(* val output_buf = (0x90,60,100,0,2000) *) 
val pm_Write1 = buildCall3 ((getSymbol libPortmidi "Pm_Write"),
	      ( PortMidiStream, cConstStar Big_Event, cInt32),cInt32) 
			   
end

