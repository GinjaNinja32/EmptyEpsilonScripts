# Ginja's Empty Epsilon Scripts
This repository is intended to be cloned into a `gn32` folder inside the EmptyEpsilon scripts directory, so that this file is `scripts/gn32/README.md`.  
All modules below assume that the repository is at this path.

Some modules additionally depend on parts of [batteries](https://github.com/1bardesign/batteries), which should also be cloned into the EmptyEpsilon scripts directory. In the list below, these modules will specify a dependency on e.g. `batteries/sort`.


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

Modules targeting `hook` that do not use predefined entity hooks should `require "hook-sys"` so that they can be used in non-`hook` scripts. They should also specify which hooks they use so that non-`hook` scenarios can trigger them correctly.

### debug
Provides debug utilities including centralised debug toggle management and a pretty-printer.

### stdext
Provides useful extensions to the Lua standard library that are not covered by `batteries`.

### position
Provides lists and mappings of EE crew positions.


## Main Modules
Libraries and large game subsystems relevant across multiple scenario types.

### action / action-comms / action-gm / action-main
Provides a menu system for custom station buttons, comms, and GM buttons.

`action`: Provides the base menu system implementation.  
Depends on `debug`, `stdext`.

`action-comms`: Provides comms menu functionality.  
Depends on `action`.

`action-gm`: Provides GM menu functionality.  
Depends on `action`, `hook-sys`.  
Required hooks: `update`.

`action-main`: Provides custom station button menu functionality.  
Depends on `action`, `hook-sys`, `position`, `batteries/sort`.  
Required hooks: `newPlayerShip`, `update`.

### track
Provides entity group tracking with associated data.

Depends on `hook`.
