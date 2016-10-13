# Stylish-Helper
Dump and repack the stylish plugin database in order to use your own editor/ide for the CSS styles or to make sharing/exporting your styles even easier.

## Default Stylish Database Locations
Default location for firefox is at ~/.mozilla/firefox/*.default/stylish.sqlite

Default location for chrome is at ~/.config/google-chrome/Default/databases/chrome-extension_fjnbnpbmkenffdnngjfgmeleoegfcffe_0/*

## Usage
![replaceitsarchlap Stylish DumpStylish.sh -h
Usage: DumpStylish.sh -v 0-3 -q -h -i InputStylish.sqlite -o OutputDirectory
	-i	InputStylish.sqlite	Select the stylish.sqlite file to dump
	-o	OutputDirectory	Select the output directory to dump the contents, if directory doesn't exist it will be made
	-v	verbose level 0-3
		0	 quiet no output
		1	 normal level of output
		2	 a bit more information
		3	 a ton of information
	-q	Quiet no output same as -v 0
	-h	Display help](https://i.imgur.com/KBEIOLt.png)
