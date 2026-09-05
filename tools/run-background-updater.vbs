Option Explicit

Dim shell, fileSystem, projectRoot, updater, command
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")
projectRoot = fileSystem.GetParentFolderName(fileSystem.GetParentFolderName(WScript.ScriptFullName))
updater = projectRoot & "\tools\background-updater.ps1"
command = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """" & updater & """"
shell.Run command, 0, False
