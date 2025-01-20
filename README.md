# portmidi 2.0
* portmidi for PolyML with virtual ports, all Portmidi functionalities are at your disposal except callback function
* *You can use Portmidi without worry of pointers : just use device id or name*
* please read tutor_eng.sml and execute lines step by step for getting started
* use modifier.sml to transform MIDI message from input to output (Presonus Atom SQ -only one channel- )
* create virtual "my-diato" midi ports for use with Ardour, Tracktion MuseScsore ...
* and use diato keyboard for entering, recording your music on Linux.
* these are examples for using read1 and write1 added to lib interface for realtime input-output
* portmidi libs are provided for 64bits : tested on Debian Linux, Mac Catalina and Windows 11  (get a new version of these libs for Linux and OSX and install them in the libs directory ; the windows dll provided here is the new version)
* compiled from https://github.com/PortMidi/portmidi 
* read the portmidi doc at https://portmidi.github.io/portmidi_docs/
# Installing PolyML
* download polyML https://codeload.github.com/polyml/polyml/tar.gz/refs/tags/v5.9
* go to terminal 
* untar gz file with : tar xvf polyml-5.9.tar.gz 
* cd polyml-5.9/
* ./configure
* make
* sudo make install
* you are ready for portmidi-sml
# learn sml language
* a short tour https://openuniversity.github.io/PL-236319-Spr-2024/Material/Tutorials/sml/introduction.html
* if you don't know sml language read the book https://www.cl.cam.ac.uk/~lp15/MLbook/
* Book with solutions of exercices.

# installing portmidi-sml and compile virtual port
* I provide already compiled portmidi dynamic library for facility, but if this don't work for you,
you should compile portmidi yourself and modify the function "getLibMidi()" in the file PortmidiFFI.sml 
* download https://github.com/jh-midi/portmidi-sml/archive/refs/heads/main.zip
* copy this file to your home directory
* unzip the file : unzip main.zip

 # create your virtual midi port (no need to be a programmer)
* cd portmidi-sml-main
* polyc virt.sml -o virtual-portmidi (compile the program )
* now you can create virtual midi port : ./virtual-portmidi diato-port 
* you can create your in-out named ports : ./virtual-portmidi my-midi-port 
* and you can use it with my diato program (refresh your chromium navigator) or another at your convenance
* 
# installing on windows
* NB you can't create virtual midi port on windows
* but you can use this library for filtering midi event create music,send sysex etc ...
* https://www.tobias-erichsen.de/software/loopmidi.html or another driver work well with windows
* Click [Windows Cygwin](https://github.com/jh-midi/portmidi-sml/blob/main/Windows_Cygwin.md) : this is help for installing PolyML on Windows allowing compiling.
# installing on Mac
It's the same as for Linux, but I was only able to compile for the Intel version (Catalina).
Just modify PortmidiFFI.sml to add what is needed for M1 and M2.

