Class constructor($settings : Object)
	This:C1470.setup($settings)
	
Function setup($settings : Object)
	This:C1470.settings:=$settings
	This:C1470._initError()
	If (Is macOS:C1572)
		If (String:C10(This:C1470.settings.entitlements)="")
			This:C1470.settings.entitlements:=Folder:C1567(This:C1470.settings.macApplicationsPath+"/4D.app").folder("Contents").folder("Resources").file("4D.entitlements").path
		End if 
	End if 
	If (String:C10(This:C1470.settings.log)="")
		$posix:=Folder:C1567(fk logs folder:K87:17).file("Builder_log.txt")
		This:C1470.settings.log:=Convert path system to POSIX:C1106($posix.platformPath)  // we need an absolute folder, not /LOGS/...
	End if 
	
Function createMacClient($targetfolder : 4D:C1709.folder)->$error : Object
	This:C1470._initError()
	
	If (Not:C34(Is macOS:C1572))
		This:C1470._addError(-15000; "Building a Mac Client can only be done on Mac")
	Else 
		
		// ##1 copy source Volume Desktop
		$source:=Folder:C1567(This:C1470.settings.macApplicationsPath+"/4D Volume Desktop.app"; fk posix path:K87:1)
		If ((Not:C34($source.isPackage)) | (Not:C34($source.exists)))
			This:C1470._addError(-15001; "Source "+$source.path+" is not a Mac Package")
		Else 
			$target:=$targetfolder.folder(This:C1470.settings.name+" Client.app")
			If ($target.exists)
				$target.delete(1)  // with contents
			End if 
			If (Not:C34($targetfolder.exists))
				This:C1470._addError(-15002; $targetfolder.path+" is not a folder")
			Else 
				$source.copyTo($targetfolder; This:C1470.settings.name+" Client.app")
			End if 
		End if 
		This:C1470._addLogLine("Create "+$targetfolder.platformPath+" "+This:C1470.settings.name+" Client.app"; "Info")
		
		If (Not:C34(This:C1470.error.error))
			// ##2 rename
			$target.folder("Contents").folder("MacOS").file("4D Volume Desktop").rename(This:C1470.settings.name+" Client")
			$target.folder("Contents").folder("Resources").file("4D Volume Desktop.rsrc").rename(This:C1470.settings.name+" Client.rsrc")
			
			// ##3 in conents/Database create EnginedServer.4dlink
			$content:="<?xml version=\"1.0\" encoding=\"UTF-8\"?><database_shortcut is_remote=\"true\" server_database_name=\""+\
				This:C1470.settings.name+"\" server_path=\""+This:C1470.settings.serverPath+"\"/>"
			$link:=$target.folder("Contents").folder("Database").file("EnginedServer.4Dlink")
			$link.setText($content; "UTF-8-no-bom"; Document with LF:K24:22)
			
			// ##4 create info.plist
			// On Mac this could be done with setAppInfo() as well, but we need it on Mac and Windows, so we use the same code on both
			$infofile:=$target.folder("Contents").file("info.plist")
			This:C1470._modifypInfolist($infofile)
			
			// ##5 set copyright, etc
			$info:=New object:C1471
			// $info.CFBundleIconFile:="myapp.icns"
			$info.CFBundleShortVersionString:==This:C1470.settings.Version_long
			$info.CFBundleVersion:==This:C1470.settings.Version_short
			$info.NSHumanReadableCopyright:==This:C1470.settings.Copyright
			$infofile.setAppInfo($info)
		End if 
		
		If (Not:C34(This:C1470.error.error))
			// #6 - sign result
			This:C1470._addLogLine("Start Signing"; "Info")
			This:C1470._doSignMac($target)
		End if 
	End if 
	This:C1470._writeLog()
	$error:=This:C1470.error
	
Function createWinClient($targetfolder : 4D:C1709.folder)->$error : Object
	This:C1470._initError()
	
	// ##1 copy source Volume Desktop
	$source:=Folder:C1567(This:C1470.settings.winApplicationsPath+"/4D Volume Desktop"; fk posix path:K87:1)
	If ((Not:C34($source.isFolder)) | (Not:C34($source.exists)))
		This:C1470._addError(-15001; "Source "+$source.path+" is not a Folder")
	Else 
		$target:=$targetfolder.folder(This:C1470.settings.name+" Client")
		If ($target.exists)
			$target.delete(1)  // with contents
		End if 
		If (Not:C34($targetfolder.exists))
			This:C1470._addError(-15002; $targetfolder.path+" is not a folder")
		Else 
			$source.copyTo($targetfolder; This:C1470.settings.name+" Client")
		End if 
	End if 
	This:C1470._addLogLine("Create "+$targetfolder.platformPath+" "+This:C1470.settings.name+" Client"; "Info")
	
	If (Not:C34(This:C1470.error.error))
		// ##2 rename
		$target.file("4D Volume Desktop.rsr").rename(This:C1470.settings.name+" Client.rsr")
		$target.file("4D Volume Desktop.4DE").rename(This:C1470.settings.name+" Client.EXE")
		
		// ##3 in conents/Database create EnginedServer.4dlink
		$content:="<?xml version=\"1.0\" encoding=\"UTF-8\"?><database_shortcut is_remote=\"true\" server_database_name=\""+\
			This:C1470.settings.name+"\" server_path=\""+This:C1470.settings.serverPath+"\"/>"
		$link:=$target.folder("Database").file("EnginedServer.4Dlink")
		$link.setText($content; "UTF-8-no-bom"; Document with LF:K24:22)
		
		// ##4 create info.plist
		// On Mac this could be done with setAppInfo() as well, but we need it on Mac and Windows, so we use the same code on both
		$infofile:=$target.folder("Resources").file("info.plist")
		This:C1470._modifypInfolist($infofile)
		
		// ##5 set copyright, etc  
		If (Is macOS:C1572)
			This:C1470._addLogLine("Cannot modify copyright/app name on Mac for Windows Client"; "Info")
		Else 
			$info:=New object:C1471
			$info.InternalName:=This:C1470.settings.name+" Client"
			$info.ProductName:=This:C1470.settings.name+" Client"
			$info.FileDescription:=This:C1470.settings.name+" Client"
			$info.OriginalFilename:=This:C1470.settings.name+" Client.exe"
			$info.ProductVersion:=This:C1470.settings.Version_long
			$info.FileVersion:=This:C1470.settings.Version_short
			$info.LegalCopyright:=This:C1470.settings.Copyright
			$info.CompanyName:=This:C1470.settings.CompanyName
			$target.file(This:C1470.settings.name+" Client.EXE").setAppInfo($info)
		End if 
		
		// #6 - sign result
		If (Is macOS:C1572)
			This:C1470._addLogLine("Cannot sign Windows Client on Mac"; "Info")
		End if 
	End if 
	
	This:C1470._writeLog()
	$error:=This:C1470.error
	
Function _modifypInfolist($infofile : 4D:C1709.file)
	$oldinfo:=$infofile.getText()
	$newinfo:=Replace string:C233($oldinfo; "4D Volume Desktop"; This:C1470.settings.name+" Client")  // no need for Windows
	$newinfo:=Replace string:C233($newinfo; "com.4D.4DRuntimeVolumeLicense"; "com.4D."+This:C1470.settings.name+".client")
	
	$infolines:=Split string:C1554($oldinfo; Char:C90(10))
	// remove last two lines, insert new ones, add two last lines again
	Repeat 
		$info2:=$infolines.pop()
	Until (($info2="@</plist>@") | ($infolines.length<1))
	Repeat 
		$info1:=$infolines.pop()
	Until (($info1="@</dict>@") | ($infolines.length<1))
	$infolines.push("<key>com.4D.BuildApp.ReadOnlyApp</key>")
	$infolines.push("<string>true</string>")
	$infolines.push("<key>com.4D.BuildApp.ServerSelectionAllowed</key>")
	$infolines.push("<string>true</string>")
	$infolines.push("<key>SDIRuntime</key>")
	$infolines.push("<string>"+This:C1470.settings.SDIRuntime+"</string>")
	$infolines.push("<key>4D_SingleInstance</key>")
	$infolines.push("<string>"+This:C1470.settings.SingleInstance+"</string>")
	$infolines.push("<key>BuildCacheFolderNameClient</key>")
	$infolines.push("<string>"+This:C1470.settings.BuildCacheFolderNameClient+"</string>")
	$infolines.push("<key>BuildHardLink</key>")
	$infolines.push("<string>"+This:C1470.settings.BuildHardLink+"</string>")
	$infolines.push("<key>BuildName</key>")
	$infolines.push("<string>"+This:C1470.settings.name+"</string>")
	$infolines.push("<key>BuildRangeVersMin</key>")
	$infolines.push("<string>"+This:C1470.settings.CurrentVers+"</string>")
	$infolines.push("<key>BuildRangeVersMax</key>")
	$infolines.push("<string>"+This:C1470.settings.CurrentVers+"</string>")
	$infolines.push("<key>BuildCurrentVers</key>")
	$infolines.push("<string>"+This:C1470.settings.CurrentVers+"</string>")
	$infolines.push("<key>PublishName</key>")
	$infolines.push("<string>"+This:C1470.settings.PublishName+"</string>")
	$infolines.push($info1)
	$infolines.push($info2)
	$newinfo:=$infolines.join(Char:C90(13))
	$infofile.setText($newinfo; "UTF-8"; Document with CR:K24:21)
	This:C1470._addLogLine("Create Info.plist"; "Info")
	
Function _initError()
	This:C1470.error:=New object:C1471("error"; False:C215; "stack"; New collection:C1472)
	This:C1470.logtext:=""
	
Function _addError($id : Integer; $text : Text)
	This:C1470.error.error:=True:C214
	This:C1470.error.stack.push(New object:C1471("id"; $id; "text"; $text))
	This:C1470._addLogLine($text; "Error")
	
Function _addLogLine($text : Text; $type : Text)
	If ($type="Error")
		This:C1470.logtext:=This:C1470.logtext+"Error: "+$text+Char:C90(10)
	Else 
		If (This:C1470.settings.loglevel="INFO")
			This:C1470.logtext:=This:C1470.logtext+"Info: "+$text+Char:C90(10)
		End if 
	End if 
	
Function _writeLog
	File:C1566(This:C1470.settings.log).setText(This:C1470.logtext)
	
Function _doSignMac($file : 4D:C1709.file)
	// execute '/Applications/4D v19 R2/4D.app/Contents/Resources/SignApp.sh' 'Developer ID Application: 4D Deutschland GmbH (4789QA2D2W)' '/Users/thomas/Desktop/Neuer Ordner/xxx Client.app' '/Applications/4D v19 R2/4D.app/Contents/Resources/4D.entitlements' '/Users/thomas/Desktop/updatetest/Data/Logs/logSign.txt'
	$Signpath:=Folder:C1567(This:C1470.settings.macApplicationsPath+"/4D.app").folder("Contents").folder("Resources").file("SignApp.sh")
	If (Not:C34($signpath.exists))
		This:C1470._addError(-15003; "Sign path "+$Signpath.path+" not found")
	Else 
		$logpath:=File:C1566(This:C1470.settings.log).parent.file("builder_sign_log.txt").path
		$command:="'"+$Signpath.path+"' '"+This:C1470.settings.MacCertificate+"' '"+$file.path+"' '"+This:C1470.settings.entitlements+"' '"+$logpath+"'"
		$in:=""
		$out:=""
		$error:=""
		LAUNCH EXTERNAL PROCESS:C811($command; $in; $out; $error)
		If ($out="")
			$out:=File:C1566($logpath; fk posix path:K87:1).getText()
		End if 
		If ($out#"")
			If ($out="@Error @")
				This:C1470._addError(-15004; "Mac Sign execution error! ")
				This:C1470._addLogLine($out; "Error")
			Else 
				If (This:C1470.settings.loglevel="INFO")
					$signjobs:=Split string:C1554($out; Char:C90(10))
					For each ($line; $signjobs)
						This:C1470._addLogLine($line; "Info")
					End for each 
				End if 
			End if 
		End if 
		If ($error#"")
			This:C1470._addError(-15004; "Mac Sign command error: "+$error)
		End if 
	End if 
	
	