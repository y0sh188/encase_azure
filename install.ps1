function fixuri($uri){
  $UnEscapeDotsAndSlashes = 0x2000000;
  $SimpleUserSyntax = 0x20000;
  $type = $uri.GetType();
  $fieldInfo = $type.GetField("m_Syntax", ([System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic));
  $uriParser = $fieldInfo.GetValue($uri);
  $typeUriParser = $uriParser.GetType().BaseType;
  $fieldInfo = $typeUriParser.GetField("m_Flags", ([System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::FlattenHierarchy));
  $uriSyntaxFlags = $fieldInfo.GetValue($uriParser);
  $uriSyntaxFlags = $uriSyntaxFlags -band (-bnot $UnEscapeDotsAndSlashes);
  $uriSyntaxFlags = $uriSyntaxFlags -band (-bnot $SimpleUserSyntax);
  $fieldInfo.SetValue($uriParser, $uriSyntaxFlags);
}
$path = "C:\EnCaseLogs"
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}
$Logfile = "C:\EnCaseLogs\install.log"
Function LogWrite
{
   Param ([string]$logstring)
   Add-content $Logfile -value $logstring
}
LogWrite "Start script execution ..."
$source = $args[2]
$dest = $args[0] + "\encase.iso"
$version = $args[1]
LogWrite "source=$source"
LogWrite "dest=$dest"
LogWrite "version=$version"
LogWrite "Downloading encase ..."
$source_uri = New-Object System.Uri -ArgumentList ($source)
fixuri $source_uri
LogWrite "Changed encase uri: $source_uri"
Invoke-WebRequest -Uri $source_uri -OutFile $dest
LogWrite "Download complete"
LogWrite "Mounting encase iso ..."
if(!(get-DiskImage -ImagePath $dest).Attached){
    $mount_res = Mount-DiskImage -ImagePath $dest
} else {
    $mount_res = Get-DiskImage -ImagePath $dest
}
LogWrite "Mount the iso complete."
$mount_drive = ($mount_res | Get-Volume).DriveLetter + ":"
cd $mount_drive
$installer = Get-ChildItem -Path . -Name -Filter "*EnCase Setup*" -Include *.exe
LogWrite "Initiating encase silent installer ..."
Start-Process  -FilePath ".\$installer"  -ArgumentList "`"C:\Program Files\EnCase $version`""  -Wait -PassThru -NoNewWindow
LogWrite "EnCase silent installer complete."
LogWrite "Unmounting the iso ..."
Dismount-DiskImage -ImagePath $dest
LogWrite "Script complete!"