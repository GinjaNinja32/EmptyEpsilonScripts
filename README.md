# Ginja's Empty Epsilon Scripts
This repository is intended to be cloned into a `gn32` folder inside the EmptyEpsilon scripts directory, so that this README file is `scripts/gn32/README.md`.  
All modules assume that the repository is at this path.

Some modules additionally depend on parts of [batteries](https://github.com/1bardesign/batteries), which should also be cloned into the EmptyEpsilon scripts directory.
In the documentation, these modules will specify that they use e.g. `batteries/sort`.

Note that all modules have an implicit dependency on `require`.

[Documentation here](https://ginjaninja32.github.io/EmptyEpsilonScripts/)

Documentation description tags:

- [non-`ECS`]: This item is only available on versions of EmptyEpsilon prior to the implementation of [ECS][ecs] (stable releases up to and including `EE-2024.12.08`).
- [`ECS`]: This item is only available on versions of EmptyEpsilon that contain [ECS][ecs] features (prereleases from `EE-2024.10.03PR` onwards).
- [`hook`]: This module uses `hook`.
- [`hook-sys`]: This module uses `hook-sys` (possibly by a transitive dependency) and requires certain hooks to be triggered manually unless `hook` is used. These hooks will be listed in the first section of the module's documentation.
- [`action-main`]: This module uses `action-main` (possibly by a transitive dependency) and requires certain hooks to be triggered manually unless `hook` is used. These hooks are listed in the first section of `action-main`'s documentation.

[ecs]: https://github.com/daid/EmptyEpsilon/wiki/ECS
