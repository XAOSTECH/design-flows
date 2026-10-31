# tuiGen — Terminal & Shell Theme Generator

Generates terminal and shell colour themes from a shared colour palette powered by [pastel](https://github.com/sharkdp/pastel).

tuiGen is the terminal/shell counterpart to [uiGen](../uiGen) (desktop GUI).
Both consume the same palette engine ([`lib/colours.sh`](../../lib/colours.sh)), so a given preset or colour set produces a matching look across every surface.
uiGen delegates its terminal/shell surfaces to tuiGen, so each flow stays focused on one domain.

## Targets

| Target | Output | Status |
|--------|--------|--------|
| `kitty` | kitty colour config pulled in via `include` | first-class |
| `starship` | Starship palette block (`[palettes.<name>]`) | first-class |
| `tmux` | tmux status/pane/message colours | first-class |
| `alacritty` | Alacritty colour TOML | scaffold |
| `foot` | foot colour INI | scaffold |
| `fish` | fish `fish_color_*` snippet | scaffold |

First-class targets are part of the maintained setup.
Scaffold targets are functional starting points for surfaces outside daily use — review the output before relying on them.

## Usage

```bash
cd flows/tuiGen

# Terminal + prompt + multiplexer from explicit colours
./src/tuiGen --target kitty,starship,tmux -p pink -s purple --name NeonPink

# Every target at once from a preset
./src/tuiGen --target all --preset dracula

# Preview a kitty theme without writing anything
./src/tuiGen --target kitty -p "#ff69b4" --dry-run -v

# List targets or presets
./src/tuiGen --list-targets
./src/tuiGen --list-presets
```

### Output

tuiGen writes one directory per target under:

```
./out/<ThemeName>-<YYYY-MM-DD>/<ThemeName>/<target>/
```

When the matching tool config directory already exists (for example `~/.config/kitty`), the generated file is also copied there.
tuiGen never creates a tool's config tree for you.

## Options

Run `./src/tuiGen --help` for the full list.
The palette options (`-p/-s/-t`, `--variation`, `--bg-lightness`, `--compl`, `--invert`, `--preset`) behave exactly as in uiGen and palGen.

## Runtime palette cycling

tuiGen only generates themes.
Runtime switching (picking a palette on shell start, repointing kitty's `include`, selecting a Starship palette) lives in the [`themes`](https://github.com/XAOSTECH/themes) repository, which owns activation.
Keeping generation here and activation there avoids running pastel on the hot shell-init path.

## Dependencies

- Bash 5.0+
- [pastel](https://github.com/sharkdp/pastel) (resolved via `PASTEL_BIN`, the monorepo submodule, or `PATH`)
