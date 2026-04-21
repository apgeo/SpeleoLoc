$configs = @(
  @{ file='lib/services/cave_repository.dart'; cls='CaveRepository'; iface='ICaveRepository'; tag='CaveRepository' },
  @{ file='lib/services/cave_place_repository.dart'; cls='CavePlaceRepository'; iface='ICavePlaceRepository'; tag='CavePlaceRepository' },
  @{ file='lib/services/raster_map_repository.dart'; cls='RasterMapRepository'; iface='IRasterMapRepository'; tag='RasterMapRepository' },
  @{ file='lib/services/definition_repository.dart'; cls='DefinitionRepository'; iface='IDefinitionRepository'; tag='DefinitionRepository' }
)
foreach ($cfg in $configs) {
  $f = $cfg.file
  $text = Get-Content $f -Raw

  if ($text -notmatch 'repository_interfaces\.dart') {
    $insert = "import 'package:speleoloc/services/repository_interfaces.dart';`nimport 'package:speleoloc/utils/app_logger.dart';`n"
    # Insert after last import line
    $lines = $text -split "`r?`n"
    $lastImportIdx = -1
    for ($i=0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match "^import ") { $lastImportIdx = $i }
    }
    if ($lastImportIdx -ge 0) {
      $newLines = @()
      $newLines += $lines[0..$lastImportIdx]
      $newLines += "import 'package:speleoloc/services/repository_interfaces.dart';"
      $newLines += "import 'package:speleoloc/utils/app_logger.dart';"
      if ($lastImportIdx + 1 -lt $lines.Count) {
        $newLines += $lines[($lastImportIdx+1)..($lines.Count-1)]
      }
      $text = $newLines -join "`n"
    }
  }

  # implements clause
  $text = $text -replace ("class " + $cfg.cls + " \{"), ("class " + $cfg.cls + " implements " + $cfg.iface + " {")

  # Add _log field after `final AppDatabase _database;`
  if ($text -notmatch "_log = AppLogger\.of\('" + $cfg.tag + "'\)") {
    $text = $text -replace "(\s*final AppDatabase _database;)", ("`$1`n  final _log = AppLogger.of('" + $cfg.tag + "');")
  }

  # Add @override to public method declarations (lines starting with 2 spaces then `Future<`)
  $lines = $text -split "`n"
  $newLines = New-Object System.Collections.ArrayList
  for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^  Future<' -and ($i -eq 0 -or $lines[$i-1].Trim() -ne '@override')) {
      $null = $newLines.Add('  @override')
    }
    $null = $newLines.Add($line)
  }
  $text = $newLines -join "`n"

  # catch (e) -> catch (e, st)
  $text = $text -replace 'catch \(e\) \{', 'catch (e, st) {'

  # print patterns
  $tagEsc = [regex]::Escape($cfg.tag)
  # `print('[Tag] MSG: $e');` -> `_log.severe('MSG', e, st);`
  $text = [regex]::Replace($text, "print\('\[$tagEsc\] ([^']*?):\s*\`$e'\);", '_log.severe(''$1'', e, st);')
  # `print('[Tag] MSG error: $e');` handled above; any remaining `print('[Tag] ...');` -> info
  $text = [regex]::Replace($text, "print\('\[$tagEsc\] ([^']*)'\);", '_log.info(''$1'');')

  Set-Content $f $text -NoNewline
}
Write-Host "Done"
