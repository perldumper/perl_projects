#!/usr/bin/perl

# EXAMPLE
# ./cartridge_header.pl pokemon_red.gb

# https://web.archive.org/web/20140122145900/http://nocash.emubase.de/pandocs.htm#thecartridgeheader

# SEE Appendix 3
#  GameBoyProgManVer1.1.pdf
# --> improve the %hashes

# drop the 0x prefix ?

use strict;
use warnings;
local $,="";
local $\="\n";
local $/=undef;
exit unless @ARGV;
my $game = shift;
my @CartridgeMemory;

open(my $fh, "<:raw", $game);
# split file string into byte array, faster than split "". And probably more reliable
@CartridgeMemory = unpack("C*", <$fh>);
close $fh;
 

# Specifies which Memory Bank Controller (if any) is used in the cartridge, and if further external hardware exists in the cartridge.
my %cartridge_type = (
	0x00, "ROM ONLY",
	0x01, "MBC1",
	0x02, "MBC1 + RAM",
	0x03, "MBC1 + RAM + BATTERY",
	0x05, "MBC2",
	0x06, "MBC2 + BATTERY",
	0x08, "ROM + RAM",
	0x09, "ROM + RAM + BATTERY",
	0x0B, "MMM01",
	0x0C, "MMM01 + RAM",
	0x0D, "MMM01 + RAM + BATTERY",
	0x0F, "MBC3 + TIMER + BATTERY",
	0x10, "MBC3 + TIMER + RAM + BATTERY",
	0x11, "MBC3",
	0x12, "MBC3 + RAM",
	0x13, "MBC3 + RAM + BATTERY",
	0x15, "MBC4",
	0x16, "MBC4 + RAM",
	0x17, "MBC4 + RAM + BATTERY",
	0x19, "MBC5",
	0x1A, "MBC5 + RAM",
	0x1B, "MBC5 + RAM + BATTERY",
	0x1C, "MBC5 + RUMBLE",
	0x1D, "MBC5 + RUMBLE + RAM",
	0x1E, "MBC5 + RUMBLE + RAM + BATTERY",
	0xFC, "POCKET CAMERA",
	0xFD, "BANDAI TAMA5",
	0xFE, "HuC3",
	0xFF, "HuC1 + RAM + BATTERY",
);

# 0148 - ROM Size
# Specifies the ROM Size of the cartridge. Typically calculated as "32KB shl N".
my %ROM_size = (
  0x00,  "32KByte (no ROM banking)",
  0x01,  "64KByte (4 banks)",
  0x02,  "128KByte (8 banks)",
  0x03,  "256KByte (16 banks)",
  0x04,  "512KByte (32 banks)",
  0x05,  "1MByte (64 banks) (only 63 banks used by MBC1)",
  0x06,  "2MByte (128 banks) (only 125 banks used by MBC1)",
  0x07,  "4MByte (256 banks)",
  0x52,  "1.1MByte (72 banks)",
  0x53,  "1.2MByte (80 banks)",
  0x54,  "1.5MByte (96 banks)",
);

# 0149 - RAM Size
# Specifies the size of the external RAM in the cartridge (if any).
# When using a MBC2 chip 00h must be specified in this entry, even though the MBC2 includes a built-in RAM of 512 x 4 bits.
my %RAM_size = (
  0x00, "None",
  0x01, "2 KBytes",
  0x02, "8 Kbytes",
  0x03, "32 KBytes (4 banks of 8KBytes each)",
);

# 014A - Destination Code
# Specifies if this version of the game is supposed to be sold in japan, or anywhere else. Only two values are defined.

my %destination_code = (
  0x00, "Japanese",
  0x01, "Non-Japanese",
);



# 0146 - SGB Flag
# Specifies whether the game supports SGB functions, common values are:
# The SGB disables its SGB functions if this byte is set to another value than 03h.
my %SGB_flag = (
  0x00, "No SGB functions (Normal Gameboy or CGB only game)",
  0x03, "Game supports SGB functions",
);

# 0143 - CGB Flag
# In older cartridges this byte has been part of the Title (see above). In CGB cartridges the upper bit is used to enable CGB functions. This is required, otherwise the CGB switches itself into Non-CGB-Mode. Typical values are:
#   80h - Game supports CGB functions, but works on old gameboys also.
#   C0h - Game works on CGB only (physically the same as 80h).
# Values with Bit 7 set, and either Bit 2 or 3 set, will switch the gameboy into a special non-CGB-mode with uninitialized palettes. Purpose unknown, eventually this has been supposed to be used to colorize monochrome games that include fixed palette data at a special location in ROM.


my %CGB_flag = (
	0x80, "Game supports CGB functions, but works on old gameboys also",
	0xC0, - "Game works on CGB only (physically the same as 80h)",
);



# 0100-0103 - Entry Point
# printf "0100-0103 - Entry Point  %02X %02X %02X %02X\n", @CartridgeMemory[0x100 .. 0x103];
printf "Entry Point        0x%02X 0x%02X 0x%02X 0x%02X\n", @CartridgeMemory[0x100 .. 0x103];

# 0104-0133 - Nintendo Logo
# printf "0104-0133 - Nintendo Logo %s\n", join " ", map { sprintf "%02X", $_ } @CartridgeMemory[0x104 .. 0x133];


# CHANGE THIS --> just say if the bytes match or not the official logo
printf "Nintendo Logo      %s\n", join " ", map { sprintf "0x%02X", $_ } @CartridgeMemory[0x104 .. 0x133];



# 0134-0143 - Title (originally 16 characters, then 15, then 11)
# printf "0134-0143 - Title %s\n", join "", map { chr } @CartridgeMemory[0x134 .. 0x143];
printf "Title              \"%s\"\n", join "", map { chr } @CartridgeMemory[0x134 .. 0x143];

# 013F-0142 - Manufacturer Code
# printf "013F-0142 - Manufacturer Code  %02X %02X %02X %02X\n", @CartridgeMemory[0x13F .. 0x142];
printf "Manufacturer Code  0x%02X 0x%02X 0x%02X 0x%02X\n", @CartridgeMemory[0x13F .. 0x142];

# 0143 - CGB Flag
# printf "0143 - CGB Flag %02X\n", $CartridgeMemory[0x143];
printf "CGB Flag           0x%02X    %s\n", $CartridgeMemory[0x143], $CGB_flag{ $CartridgeMemory[0x143] } // "Non-CGB Mode";

# 0144-0145 - New Licensee Code
# printf "0144-0145 - New Licensee Code %02X %02X\n", @CartridgeMemory[0x144 .. 0x145];
printf "New Licensee Code  0x%02X 0x%02X\n", @CartridgeMemory[0x144 .. 0x145];

# 0146 - SGB Flag
# printf "0146 - SGB Flag %02X\n", $CartridgeMemory[0x146];
printf "SGB Flag           0x%02X    %s\n", $CartridgeMemory[0x146], $SGB_flag{ $CartridgeMemory[0x146] };

# 0147 - Cartridge Type
# printf "0147 - Cartridge Type %02X\n", $CartridgeMemory[0x147];
# printf "Cartridge Type     %02X\n", $CartridgeMemory[0x147];

printf "Cartridge Type     0x%02X    %s\n", $CartridgeMemory[0x147], $cartridge_type{ $CartridgeMemory[0x147] };


# 0148 - ROM Size
# printf "0148 - ROM Size %02X\n", $CartridgeMemory[0x148];
# printf "ROM Size           0x%02X\n", $CartridgeMemory[0x148];
printf "ROM Size           0x%02X    %s\n", $CartridgeMemory[0x148], $ROM_size{ $CartridgeMemory[0x148] };

# 0149 - RAM Size
# printf "0149 - RAM Size %02X\n", $CartridgeMemory[0x149];
# printf "RAM Size           0x%02X\n", $CartridgeMemory[0x149];
printf "RAM Size           0x%02X    %s\n", $CartridgeMemory[0x149], $RAM_size{ $CartridgeMemory[0x149] };


# 014A - Destination Code
# printf "014A - Destination Code %02X\n", $CartridgeMemory[0x14A];
printf "Destination Code   0x%02X    %s\n", $CartridgeMemory[0x14A], $destination_code{ $CartridgeMemory[0x14A] };

# 014B - Old Licensee Code
# printf "014B - Old Licensee Code %02X\n", $CartridgeMemory[0x14B];
printf "Old Licensee Code  0x%02X\n", $CartridgeMemory[0x14B];

# 014C - Mask ROM Version number
# printf "014C - Mask ROM Version number %02X\n", $CartridgeMemory[0x14C];
printf "Mask ROM Version number 0x%02X\n", $CartridgeMemory[0x14C];

# 014D - Header Checksum
# printf "014D - Header Checksum %02X\n", $CartridgeMemory[0x14D];
printf "Header Checksum    0x%02X\n", $CartridgeMemory[0x14D];

# 014E-014F - Global Checksum
# printf "014E-014F - Global Checksum %02X %02X\n", @CartridgeMemory[0x14E .. 0x14F];
printf "Global Checksum    0x%02X 0x%02X\n", @CartridgeMemory[0x14E .. 0x14F];

__END__


0143 - CGB Flag
In older cartridges this byte has been part of the Title (see above). In CGB cartridges the upper bit is used to enable CGB functions. This is required, otherwise the CGB switches itself into Non-CGB-Mode. Typical values are:
  80h - Game supports CGB functions, but works on old gameboys also.
  C0h - Game works on CGB only (physically the same as 80h).
Values with Bit 7 set, and either Bit 2 or 3 set, will switch the gameboy into a special non-CGB-mode with uninitialized palettes. Purpose unknown, eventually this has been supposed to be used to colorize monochrome games that include fixed palette data at a special location in ROM.

0144-0145 - New Licensee Code
Specifies a two character ASCII licensee code, indicating the company or publisher of the game. These two bytes are used in newer games only (games that have been released after the SGB has been invented). Older games are using the header entry at 014B instead.

0146 - SGB Flag
Specifies whether the game supports SGB functions, common values are:
  00h = No SGB functions (Normal Gameboy or CGB only game)
  03h = Game supports SGB functions
The SGB disables its SGB functions if this byte is set to another value than 03h.

0147 - Cartridge Type
Specifies which Memory Bank Controller (if any) is used in the cartridge, and if further external hardware exists in the cartridge.
  00h  ROM ONLY                 13h  MBC3+RAM+BATTERY
  01h  MBC1                     15h  MBC4
  02h  MBC1+RAM                 16h  MBC4+RAM
  03h  MBC1+RAM+BATTERY         17h  MBC4+RAM+BATTERY
  05h  MBC2                     19h  MBC5
  06h  MBC2+BATTERY             1Ah  MBC5+RAM
  08h  ROM+RAM                  1Bh  MBC5+RAM+BATTERY
  09h  ROM+RAM+BATTERY          1Ch  MBC5+RUMBLE
  0Bh  MMM01                    1Dh  MBC5+RUMBLE+RAM
  0Ch  MMM01+RAM                1Eh  MBC5+RUMBLE+RAM+BATTERY
  0Dh  MMM01+RAM+BATTERY        FCh  POCKET CAMERA
  0Fh  MBC3+TIMER+BATTERY       FDh  BANDAI TAMA5
  10h  MBC3+TIMER+RAM+BATTERY   FEh  HuC3
  11h  MBC3                     FFh  HuC1+RAM+BATTERY
  12h  MBC3+RAM



0148 - ROM Size
Specifies the ROM Size of the cartridge. Typically calculated as "32KB shl N".
  00h -  32KByte (no ROM banking)
  01h -  64KByte (4 banks)
  02h - 128KByte (8 banks)
  03h - 256KByte (16 banks)
  04h - 512KByte (32 banks)
  05h -   1MByte (64 banks)  - only 63 banks used by MBC1
  06h -   2MByte (128 banks) - only 125 banks used by MBC1
  07h -   4MByte (256 banks)
  52h - 1.1MByte (72 banks)
  53h - 1.2MByte (80 banks)
  54h - 1.5MByte (96 banks)




0149 - RAM Size
Specifies the size of the external RAM in the cartridge (if any).
  00h - None
  01h - 2 KBytes
  02h - 8 Kbytes
  03h - 32 KBytes (4 banks of 8KBytes each)
When using a MBC2 chip 00h must be specified in this entry, even though the MBC2 includes a built-in RAM of 512 x 4 bits.

014A - Destination Code
Specifies if this version of the game is supposed to be sold in japan, or anywhere else. Only two values are defined.
  00h - Japanese
  01h - Non-Japanese


014D - Header Checksum
Contains an 8 bit checksum across the cartridge header bytes 0134-014C. The checksum is calculated as follows:
  x=0:FOR i=0134h TO 014Ch:x=x-MEM[i]-1:NEXT
The lower 8 bits of the result must be the same than the value in this entry. The GAME WON'T WORK if this checksum is incorrect.

014E-014F - Global Checksum
Contains a 16 bit checksum (upper byte first) across the whole cartridge ROM. Produced by adding all bytes of the cartridge (except for the two checksum bytes). The Gameboy doesn't verify this checksum.








