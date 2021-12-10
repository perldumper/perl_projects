#!/usr/bin/bash

# a little better for the wrist on a laptop
# to stop using the right thumb for arrow keys

# have real arrows in numpad, so that they can work in vim
xmodmap -e 'keycode 80 = Up    KP_8 Up    KP_8'
xmodmap -e 'keycode 83 = Left  KP_4 Left  KP_4'
xmodmap -e 'keycode 84 = Down  KP_5 Down  KP_5'
xmodmap -e 'keycode 85 = Right KP_6 Right KP_6'
xmodmap -e 'keycode 88 = Down  KP_2 Down  KP_2'

# remove pageup, pagedown, etc when numlock is off
xmodmap -e 'keycode 79 = NoSymbol KP_7       NoSymbol KP_7'
xmodmap -e 'keycode 81 = NoSymbol KP_9       NoSymbol KP_9'
xmodmap -e 'keycode 87 = NoSymbol KP_1       NoSymbol KP_1'
xmodmap -e 'keycode 89 = NoSymbol KP_3       NoSymbol KP_3'
xmodmap -e 'keycode 90 = NoSymbol KP_0       NoSymbol KP_0'
xmodmap -e 'keycode 91 = NoSymbol KP_Decimal NoSymbol KP_Decimal'

# deactivate normal arrow keys
xmodmap -e 'keycode 111 = NoSymbol NoSymbol NoSymbol'
xmodmap -e 'keycode 111 = NoSymbol NoSymbol NoSymbol'
xmodmap -e 'keycode 113 = NoSymbol NoSymbol NoSymbol'
xmodmap -e 'keycode 114 = NoSymbol NoSymbol NoSymbol'
xmodmap -e 'keycode 116 = NoSymbol NoSymbol NoSymbol'

xmodmap -e 'keycode 81 = Return KP_9       Return KP_9'
xmodmap -e 'keycode 89 = Return KP_3       Return KP_3'
xmodmap -e 'keycode 87 = End KP_1       End KP_1'
xmodmap -e 'keycode 79 = Home KP_7       Home KP_7'
# xmodmap -e 'keycode 88 = Return  KP_2 Return  KP_2'
xmodmap -e 'keycode 88 = BackSpace  KP_2 BackSpace  KP_2'

xmodmap -e 'keycode 106 = Prior apostrophe KP_Divide KP_Divide KP_Divide KP_Divide'
xmodmap -e 'keycode 63 = Next quotedbl KP_Multiply KP_Multiply KP_Multiply KP_Multiply'

xmodmap -e 'keycode 86 = Return  KP_Add Return  KP_Add'
xmodmap -e 'keycode 81 = End KP_9       End KP_9'


