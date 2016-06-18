# ESD-ToolKit and RenameISOs

ESD ToolKit is a tool designed to convert, and modify esd files. Converting esd files does not modify them in any way.

Future versions will have the ability to modify and create esd files.

The project is still currently in beta and previews tends to be released each month.

This whole project was based on abbodi1406's work (his esd decrypter batch tool).

This tool has been rewritten in powershell and has a gui, as well as a cli version and has many new features the original script doesn't have.
You'll also find here a tool designed to rename Windows Build ISOs.

You can use my work only if you credit me for the parts used on your project public page and inside your project download.

Feel free to contact me if you need to.

You can also submit pull request and contribute to this project.

In this repo you'll also find the source code for the esddecrypt program by qad at MDL forums.

## Current state:

ESD_ToolKit_GUI.bat launches the Windows Setup toolkit gui (currently in preview)

ESD_ToolKit_cli.bat launches the Windows Setup toolkit cli (currently in preview)

ESDDecrypter.bat launches the old ESD Decrypter which still has some features I haven't implemented in the new one.

RenameISOs.bat launches the Rename ISOs tool which will rename all Windows Build ISOs in a given folder or the current directory.

ISORebuilder.bat launches the ISO Rebuilder tool, which allows you to build a MS-like iso from a folder, works with Windows 10 only atm.

### Credit for the original script and the tools used:

abbodi1406 for the original script

qad - decryption program

synchronicity - wimlib

murphy78 - original script

nosferati87, NiFu, s1ave77, and any other MDL forums members contributed in the ESD project

@tfwboredom - updated esddecrypt for 14361+ esds

https://github.com/hounsell/DecryptESD - DecryptESD Program made by Thomas Hounsell