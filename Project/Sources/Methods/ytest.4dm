//%attributes = {}
$settings:=New object:C1471
$settings.name:="test"
$settings.macApplicationsPath:="/Applications/4D v19 R2"  // drag&drop path from Finder to Terminal
$settings.winApplicationsPath:="C:/Program Files/4D/4D v19 R2"


$settings.serverPath:=":19813"

$settings.SingleInstance:="1"
$settings.SDIRuntime:="1"  // read from settings file?
$settings.BuildCacheFolderNameClient:=""
$settings.BuildHardLink:=""
$settings.CurrentVers:="2"
$settings.PublishName:=$settings.name
$settings.Version_long:="25 X3 build 1234"
$settings.Version_short:="25.3.0.0"
$settings.Copyright:="© by me, 2021. All rights reserved."
$settings.CompanyName:="myCompany"


$settings.MacCertificate:="Developer ID Application: 4D Deutschland GmbH (4789QA2D2W)"
$settings.entitlements:=""  // overwrite here
$settings.log:=""
$settings.loglevel:="INFO"  // or "ERROR" for error only




var $builder : cs:C1710.Builder

$builder:=cs:C1710.Builder.new($settings)

//$target:=Folder(fk desktop folder).folder("Buildtest")
//$error:=$builder.createMacClient($target; "")



$target:=Folder:C1567(fk desktop folder:K87:19).folder("Buildtest")
$error:=$builder.createWinClient($target; "")
