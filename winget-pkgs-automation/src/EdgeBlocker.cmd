@echo off

@REM This file is *not* licensed under the MIT license, it was downloaded from Microsoft.

Echo MICROSOFT TOOL KIT TO DISABLE DELIVERY OF 
Echo MICROSOFT EDGE (CHROMIUM-BASED)
Echo.
Echo Copyright (C) Microsoft Corporation.  All rights reserved.
Echo.

set ProductName=Microsoft Edge (Chromium-based)
set REGBlockKey=HKLM\SOFTWARE\Microsoft\EdgeUpdate
set REGBlockValue=DoNotUpdateToEdgeWithChromium

set RemoteMachine=%1

if ""=="%1" goto Usage
if "/?"=="%1" goto Usage
if /I "/H"=="%1" goto Usage
if /I "/B"=="%1" goto LocalMachine
if /I "/U"=="%1" goto LocalMachine
set RemoteMachineName=%1
set Action=%2

:Parse
if /I "/B" == "%Action%" goto Block
if /I "/U" == "%Action%" goto UnBlock
goto Usage

:Block
Echo Blocking deployment of %ProductName% on %RemoteMachineName%
REG ADD "\\%RemoteMachine%\%REGBlockKey%" /v %REGBlockValue% /t REG_DWORD /d 1 /f
goto End

:UnBlock
Echo Unblocking deployment of %ProductName% on %RemoteMachineName%
REG DELETE "\\%RemoteMachine%\%REGBlockKey%" /v %REGBlockValue% /f
goto End

:LocalMachine
echo LOCAL!
set Action=%1
set RemoteMachine=.
set RemoteMachineName=the local machine
goto Parse

:Usage
Echo.
Echo This tool can be used to remotely block or unblock the delivery of
Echo %ProductName% via Automatic Updates. 
Echo.
Echo ------------------------------------------------------------
Echo Usage:
Echo %0 [machine name] [/B] [/U] [/H]
REM [machine name] [/B|U|H]
Echo B = Block %ProductName% deployment
Echo U = Allow %ProductName% deployment
Echo H = Help
Echo.
Echo To block or unblock installation on the local machine use
Echo period ("." with no quotes) as the machine name
Echo.
Echo Examples:
Echo %0 mymachine /B (blocks delivery on machine "mymachine")
Echo.
Echo %0 /U (unblocks delivery on the local machine)
Echo ------------------------------------------------------------
Echo.

:End
