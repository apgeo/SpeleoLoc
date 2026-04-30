$ll = [System.Collections.Generic.List[string]](Get-Content lib\screens\home_page.dart)

# 1. Add Completer field after _testDataPromptShown (line 124, 0-indexed 123)
$ll.Insert(124, "  Completer<void>? _testDataPromptCompleter;")

# 2. Insert beforeAutoTour override after _toggleMainToolbar (now at line 218 close brace, 0-indexed 217)
$ll.Insert(219, "")
$ll.Insert(219, "  }")
$ll.Insert(219, "    if (_testDataPromptCompleter != null) await _testDataPromptCompleter!.future;")
$ll.Insert(219, "  @override")
$ll.Insert(219, "  Future<void> beforeAutoTour() async {")

# 3. Replace _offerTestDataPopulation() call (now shifted by 1+5=6 lines, original 247 -> 253)
$ll[253] = "        _testDataPromptCompleter = Completer<void>();"
$ll.Insert(254, "        _offerTestDataPopulation().whenComplete(() {")
$ll.Insert(255, "          _testDataPromptCompleter?.complete();")
$ll.Insert(256, "          _testDataPromptCompleter = null;")
$ll.Insert(257, "        });")

Set-Content lib\screens\home_page.dart $ll -Encoding UTF8
Write-Host "Done: $($ll.Count)"
