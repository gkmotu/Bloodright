Option Explicit

Dim shell, fileSystem, projectRoot, updater, command
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")
projectRoot = fileSystem.GetParentFolderName(fileSystem.GetParentFolderName(WScript.ScriptFullName))
updater = projectRoot & "\tools\background-updater.ps1"
command = "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File " & Chr(34) & updater & Chr(34)
shell.Run command, 0, True
