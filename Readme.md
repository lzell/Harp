Quick Start
==========
Building requires Xcode7 installed at /Applications/Xcode

Open Harp.xcworkspace.  Build and run HarpSample_AppleTV.  Build and run
HarpController.  A gamepad will appear on the controller after 5 to 10 seconds.
Tap some buttons.

Demo
====
![Harp Demo](https://github.com/lzell/Harp/raw/master/uploads/demo.gif)

About
=====
This is an open source re-write from the ground up of the Joypad game
controller, with the major caveat that it is not protocol-compliant with Joypad
itself.  A handful of people worked on Joypad for multiple years, and this
project is not aimed at being nearly as robust and featurefull as Joypad
itself.  That said, this should take the task of network programming completely
out of your own initiatives to build second screen controllers like Joypad.

Individual bits of this project may be of use to other applications. For
example, this is the first (that I'm aware of) pure swift wrapper around some
of the dns_sd.h functionality -- the pieces required to locate and get the IPv6
address and port of a bluetooth available service.

One unintended but awesome implication of this design over Joypad is that it
could be extended to allow each player to have a different controller layout,
which could be used to expose different functionality to each player based on
the context.


Known limitations
=================
* When using the iOS simulator you must start HarpSample_AppleTV before
	HarpController.  For real devices you can start them in any order.

* Whereas Joypad used to "beam" skinned controllers over bluetooth, the design
	here requires that the controller be built into controller app itself.
	Meaning you can't just adjust some SDK calls and have a different controller
	layout on the gamepad.  Instead, you have to build the gamepad in the HarpApp
	(or your whitelabel) yourself.  See Proto1ViewController as an example

* Hasn't been tested much


Notes:
======
When debugging network prog issues, it's easiest to work with two Xcode windows
open.  The Scheme > Target will stay in sync between the two windows,
unfortunately, and I haven't found a way around that.  It is possible, though,
to switch the console output between the two different running programs. Do
this by going to View > Debug Area > Show Debug Area.  The toolbar item at the
far right, with the tooltip of "Choose Stack Frame" (?), switches output
between multiple running programs.

When using the two window side-by-side technique it is best to be able to
shrink the Xcode windows to take up only half the screen.  Do this by going to
View > Hide Toolbar.  After that, the Xcode window can be resized.

Workflow: Create the second window with cmd+shift+t, hide the toolbar with
cmd+opt+t, use spectacle hotkey to snap the windows to half size, and then
switch targets blindly with cmd+ctrl+[


FAQ
===

Q. Why is there a huge delay from when I tap a button to when the input shows up?

A. When you start the service, you specify the number of players to allow to
connect simultaneously. If that limit has not been hit yet, then the bluetooth
radio is still searching for other controllers in the area.  This significantly
degrades performance.  So make sure you set maxConcurrentConnections to the
number of players you expect.
