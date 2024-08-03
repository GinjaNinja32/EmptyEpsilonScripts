# Ginja's Empty Epsilon Scripts

## Core Modules
Language-type features, constant data definitions. Few or no dependencies.

### require
Provides a `require` function that behaves closer to standard Lua, allowing dropping the `.lua` suffix and tracking already-imported modules.

All other modules assume that this module has already been imported.

### lang / lang-strict / lang-lax
`lang-strict`: provides strict global-variable definition rules.  
`lang-lax`: provides compatibility for scripts targeting `lang-strict` in environments where the strict rules are not desired.  
`lang`: imports `lang-lax` if neither `lang-strict` nor `lang-lax` have been imported.

Modules targeting `lang-strict` should `require "lang"` for compatibility with non-strict scripts.
