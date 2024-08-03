# Ginja's Empty Epsilon Scripts
This repository is intended to be cloned into a `gn32` folder inside the EmptyEpsilon scripts directory, so that this file is `scripts/gn32/README.md`.  
All modules below assume that the repository is at this path.

## Core Modules
Language-type features and constant data definitions. Few or no dependencies.

### require
Provides a `require` function that behaves closer to standard Lua, allowing dropping the `.lua` suffix and tracking already-imported modules.

All other modules assume that this module has already been imported.

### lang / lang-strict / lang-lax
`lang-strict`: provides strict global-variable definition rules.  
`lang-lax`: provides compatibility for scripts targeting `lang-strict` in environments where the strict rules are not desired.  
`lang`: imports `lang-lax` if neither `lang-strict` nor `lang-lax` have been imported.

Modules targeting `lang-strict` should `require "lang"` for compatibility with non-strict scripts.

### hook / hook-sys
Provides event hook utilities so that multiple modules can respond to the same event without interference.

`hook-sys`: provides the hook system implementation, but no default events.  
`hook`: imports the system and integrates it with EE.

Modules targeting `hook` that do not use predefined entity hooks should `require "hook-sys"` so that they can be used in non-`hook` scripts.

## Main Modules
Libraries and large game subsystems relevant across multiple scenario types.

### track
Provides entity group tracking with associated data.

Depends on `hook`.
