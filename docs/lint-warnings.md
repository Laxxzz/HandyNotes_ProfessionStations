# Lint warnings that stay

`Test-WowAddon.ps1` passes with 0 errors and these warnings:

- `Plugin.lua global 'LibStub'` - provided by HandyNotes (`## Dependencies: HandyNotes`), which
  is not in the linter's corpus.
- `Plugin.lua global 'TomTom'` - optional; every use is guarded by `if TomTom`.
- `SavedVariable ... has no per-key defaults merge` - the merge is the loop over `ns.DEFAULTS`
  in `Plugin.lua`'s ADDON_LOADED handler, which the linter's pattern does not recognise.
