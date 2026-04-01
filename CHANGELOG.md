
## [0.1.0] - 2026-03-30 (re-release)

### Added
- auto-install generated themes to user/system paths
- add multi-target UI theme dispatcher
- add comprehensive VS Code colour keys
- add --invert flag to flip generated themes

### Fixed
- improve _require_arg error hint
- guard against missing/unquoted arguments
- correct repo URL in generated theme comment
- remove duplicate editorBracketPairGuide.activeBackground keys
- use hue-lifted variants for near-black colour operations
- ensure badge readability + add missing SCM colour keys

### Changed
- refactor: extract shared libs and scaffold uiGen
- chore(dc-init): load workflows,actions
- chore: update git tree visualisation
- chore: update CHANGELOG for v0.1.0
- chore(dc-init): update workflows
- chore(dc-init): update workflows + action

## [0.1.0] - 2026-03-21

### Added
- add comprehensive VS Code colour keys
- add --invert flag to flip generated themes

### Fixed
- correct repo URL in generated theme comment
- remove duplicate editorBracketPairGuide.activeBackground keys
- use hue-lifted variants for near-black colour operations
- ensure badge readability + add missing SCM colour keys

### Changed
- chore(dc-init): update workflows
- chore(dc-init): update workflows + action

## [0.0.1] - 2026-03-09 (re-release)

### Added
- add automatic versioning for incremental theme generations
- add deps.sh --build manual mode for monorepo pastel
- add --export/-e flag with symlink support
- improve variation and bg-lightness parameters
- auto-install pastel + UK English (COLOUR→COLOUR)
- add colour presets, --list-presets, and config summary
- expand palette with analogous, triadic, split-complementary & cross-blends
- add WCAG contrast ratio guard for font readability

### Fixed
- support temporary rustup toolchain for modern pastel builds
- anglicise description + americanise function
- pass -- to pastel rotate for negative degree values

### Changed
- chore: dc-init2
- chore: gitkeep out + README del ref
- chore(json-gen): adapt info
- chore: update CHANGELOG for v0.0.1
- dc-init
- refactor: extract libraries from monolithic vsGen script
- restructure folders

### Documentation
- fill README placeholders

## [0.0.1] - 2026-02-23

### Added
- auto-install pastel + UK English (COLOUR→COLOUR)
- add colour presets, --list-presets, and config summary
- expand palette with analogous, triadic, split-complementary & cross-blends
- add WCAG contrast ratio guard for font readability

### Fixed
- anglicise description + americanise function
- pass -- to pastel rotate for negative degree values

### Changed
- dc-init
- refactor: extract libraries from monolithic vsGen script
- restructure folders

