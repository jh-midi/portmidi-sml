Welcome to the portmidi-sml wiki!

## Information for compiling PolyML on Windows with Cygwin.

download setup-x86_64.exe from https://cygwin.com/install.html

run it

select View >Full

* Install the packages cygwin-devel, git, make, gcc-core, gcc-g++ and rlwrap\
WARNING :  don't choose mingwin64 ; this compiler don't work well for compiling PolyML on cygwin

* download the PolyML [latest release](https://github.com/polyml/polyml/releases) :\
WARNING : don't clone the repository it is not the stable version and don't compile on windows.\
here I use v5.9.tar.gz

untar it using the **cywin64 Terminal**


` $ tar xvf polyml-5.9.tar.gz`

then

` $ cd polyml-5.9`\
` $ ./configure`\
` $ make`\
` $ make compiler`\
` $ make install`

and verify

* ` $ poly `

Poly/ML 5.9 Release

`> "Hello!";`

val it = "Hello!": string

`> control-D quit polyML`


note : you can use rlwrap for line editing and history


* ` $ rlwrap poly`


then you are in business.

## information for portmidi 🥇 

`$ git clone https://github.com/jh-midi/portmidi-sml.git`\
`$ cd portmidi-sml`
### before using portmidi you have to set portmidi.dll executable

## `$ chmod +777 libs/portmidi.dll`

And then you can compile your transformer :

`$ polyc -o toChan1 modifier.sml

And run it :

`$ ./toChan1.exe`

   Microsoft MIDI Mapper      id=0 input=false  output=true   opened=false  interf=MMSystem\
   TouchOSC Bridge            id=1 input=true   output=false  opened=false  interf=MMSystem\
   loopMIDI Port              id=2 input=true   output=false  opened=false  interf=MMSystem\
   ATM SQ                     id=3 input=true   output=false  opened=false  interf=MMSystem\
   MIDIIN2 (ATM SQ)           id=4 input=true   output=false  opened=false  interf=MMSystem\
   Microsoft GS Wavetable Synth  id=5 input=false  output=true   opened=false  interf=MMSystem\
   TouchOSC Bridge            id=6 input=false  output=true   opened=false  interf=MMSystem\
   loopMIDI Port              id=7 input=false  output=true   opened=false  interf=MMSystem\

`usage : ./toChan1 <midi-input-name> <midi-output-name> [<velocity>:0=same as input] [<scan-latency-microseconds>:2000>]`

**playing GS wavetable for test**

* _with big latency :_\
`$ ./toChan1 "ATM SQ" "Microsoft GS Wavetable Synth"`

* _with small latency=2 fixed velocity=100 :_\
`$ ./toChan1 "ATM SQ" "Microsoft GS Wavetable Synth" 100 2`

**with [loopMidi](https://www.tobias-erichsen.de/software/loopmidi.html) you can use Asio in your Daw then latency is ok**

`$ ./toChan1 "ATM SQ" "loopMIDI Port"`




