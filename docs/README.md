# design-flows

<!-- Project Shields/Badges -->
<p align="center">
  <a href="https://github.com/XAOSTECH/design-flows">
    <img alt="GitHub repo" src="https://img.shields.io/badge/GitHub-XAOSTECH%2F-design-flows-181717?style=for-the-badge&logo=github">
  </a>
  <a href="https://github.com/XAOSTECH/design-flows/releases">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/XAOSTECH/design-flows?style=for-the-badge&logo=semantic-release&colour=blue">
  </a>
  <a href="https://github.com/XAOSTECH/design-flows/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/XAOSTECH/design-flows?style=for-the-badge&colour=green">
  </a>
</p>

<p align="center">
  <a href="https://github.com/XAOSTECH/design-flows/actions">
    <img alt="CI Status" src="https://github.com/XAOSTECH/design-flows/actions/workflows/bash-lint.yml/badge.svg?branch=Main>
  </a>
  <a href="https://github.com/XAOSTECH/design-flows/issues">
    <img alt="Issues" src="https://img.shields.io/github/issues/XAOSTECH/design-flows?style=flat-square&logo=github&colour=yellow">
  </a>
  <a href="https://github.com/XAOSTECH/design-flows/pulls">
    <img alt="Pull Requests" src="https://img.shields.io/github/issues-pr/XAOSTECH/design-flows?style=flat-square&logo=github&colour=purple">
  </a>
  <a href="https://github.com/XAOSTECH/design-flows/stargazers">
    <img alt="Stars" src="https://img.shields.io/github/stars/XAOSTECH/design-flows?style=flat-square&logo=github&colour=gold">
  </a>
  <a href="https://github.com/XAOSTECH/design-flows/network/members">
    <img alt="Forks" src="https://img.shields.io/github/forks/XAOSTECH/design-flows?style=flat-square&logo=github">
  </a>
</p>

<p align="center">
  <img alt="Last Commit" src="https://img.shields.io/github/last-commit/XAOSTECH/design-flows?style=flat-square&logo=git&colour=blue">
  <img alt="Repo Size" src="https://img.shields.io/github/repo-size/XAOSTECH/design-flows?style=flat-square&logo=files&colour=teal">
  <img alt="Code Size" src="https://img.shields.io/github/languages/code-size/XAOSTECH/design-flows?style=flat-square&logo=files&colour=orange">
  <img alt="Contributors" src="https://img.shields.io/github/contributors/XAOSTECH/design-flows?style=flat-square&logo=github&colour=green">
</p>

<!-- Optional: Stability/Maturity Badge -->
<p align="center">
  <img alt="Stability" src="https://img.shields.io/badge/stability-stable-green?style=flat-square">
  <img alt="Maintenance" src="https://img.shields.io/maintenance/yes/2026?style=flat-square">
</p>

---

<p align="center">
  <b>Unix Design Flows</b>
</p>

---

> **Note:** This repository is part of the [**design-tools**](https://github.com/XAOSTECH/design-tools) monorepo.  
> 📚 [**View full documentation →**](https://xaostech.github.io/design-tools)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Available Flows](#-available-flows)
- [Installation](#-installation)
- [Usage](#-usage)
- [Flow Development](#-flow-development)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🔍 Overview

**design-flows** provides automated design workflow scripts for Unix-like systems. Each flow is a self-contained tool that automates specific design tasks.

### Available Flows

#### vsGen — VS Code Theme Generator

**Location:** `flows/vsGen/`

Generates VS Code workspace colour themes from 3 base colours with intelligent palette expansion.

**Features:**
- 10 shades per colour (light to dark gradients)
- Analogous, triadic, and split-complementary harmonies
- WCAG contrast ratio protection (≥3.0)
- 8 built-in presets
- Configurable variation level
- Auto-installs dependencies

### Why design-flows?

Design workflows involve repetitive tasks that can be automated. design-flows provides:

- **Consistency** — Automated workflows ensure consistent output
- **Speed** — Generate complex themes in seconds
- **Accessibility** — Built-in WCAG compliance checks
- **Flexibility** — Highly configurable with sensible defaults

---

## 📥 Installation

### Prerequisites

- Bash 5.0+
- Git
- [pastel](https://github.com/sharkdp/pastel)

### Standalone Installation

```bash
# Clone the repository
git clone https://github.com/XAOSTECH/design-flows.git
cd design-flows
```

### Monorepo Installation

```bash
# Clone the entire monorepo
git clone --recursive https://github.com/XAOSTECH/design-tools.git
cd design-tools/design-flows
```

In the `design-tools` monorepo, `pastel` is delivered as a root submodule at
`../pastel/`.

`vsGen` resolves `pastel` in this order:
1. `PASTEL_BIN` (explicit override)
2. Monorepo submodule binary: `../pastel/target/release/pastel` (or debug)
3. System `pastel` from `PATH`
4. Auto-install fallback

If you use monorepo `pastel`, build it once:

```bash
./flows/vsGen/lib/deps.sh --build --check -v
```

This keeps `vsGen` itself unchanged and lets you trigger submodule build logic
manually from `deps.sh` when you want it.

---

## 🚀 Usage

### vsGen Examples

```bash
cd flows/vsGen

# Use a built-in preset
./src/vsGen --preset sakura

# Custom colour combinations
./src/vsGen -p coral -s gold -t skyblue

# High variation with complementary colours
./src/vsGen -p "#ff1493" -s "#ffd700" --variation 0.8 --compl

# Preview without writing files
./src/vsGen --preset neon --dry-run -v

# Update existing workspace
./src/vsGen -c project.code-workspace -p violet -s lime

# List all presets
./src/vsGen --list-presets
```

### Output

vsGen generates VS Code workspace files at:

```
./out/<ThemeName>-<YYYY-MM-DD>-v<VERSION>.code-workspace
```

Open in VS Code:

```bash
code ./out/My-Theme-2026-03-05-v1.1.0.code-workspace
```

---

## 🛠️ Flow Development

### Structure

Each flow should follow this structure:

```
flows/
└── <flow-name>/
    ├── README.md           # Flow-specific documentation
    ├── src/
    │   └── <flow-name>     # Main executable
    ├── lib/                # Optional libraries
    │   ├── deps.sh         # Dependency checks
    │   └── ...
    └── test/               # Optional tests
        └── test.sh
```

### Guidelines

1. **Modular** — Extract reusable functions into `lib/`
2. **Self-documenting** — Include `--help` and examples
3. **Error handling** — Use `set -euo pipefail`
4. **Logging** — Provide verbose output with `-v`
5. **Dependencies** — Auto-install when possible
6. **UK English** — Use British spelling (colour, not color)

### Example 1: Generate a New Theme

```bash
cd flows/vsGen
./src/vsGen --preset sakura -n "Sakura Workspace"
```

### Example 2: Update Existing Workspace Colours

```bash
cd flows/vsGen
./src/vsGen -c ../../project.code-workspace -p coral -s gold -t skyblue --variation 0.8
```

---

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FLOWS_VERBOSE` | Enable verbose logging (`1` to enable) | `0` |
| `PASTEL_BIN` | Override pastel executable path | `pastel` |

### Configuration File

```yaml
# config.yml
default_flow: vsGen
default_preset: sakura
variation: 0.5
background_lightness: 0.12
complementary_colours: true
```

---

## 📚 Documentation

### Flow Documentation

| Flow | Documentation | Description |
|------|---------------|-------------|
| **vsGen** | [README](../flows/vsGen/README.md) | VS Code theme generator |

### Additional Resources

- [design-tools monorepo](https://github.com/XAOSTECH/design-tools)
- [Contributing Guidelines](../CONTRIBUTING.md)
- [GitHub Pages](https://xaostech.github.io/design-tools)

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

### Workflow

1. **Fork** and clone the repository
2. **Create branch**: `git checkout -b flow/<flow-name>`
3. **Develop** following flow development guidelines
4. **Test** thoroughly with various inputs
5. **Commit** with conventional commits: `feat(flow): add feature`
6. **Push** and open a Pull Request
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

See also: [Code of Conduct](CODE_OF_CONDUCT.md) | [Security Policy](SECURITY.md)

---

## 🗺️ Roadmap

- [x] vsGen modularised into `src/` + `lib/`
- [x] WCAG readability safeguards for generated themes
- [ ] Add additional flows (terminal theme generator)
- [ ] Add flow-level smoke tests in CI
- [ ] Add optional YAML configuration loading

See the [open issues](https://github.com/XAOSTECH/design-flows/issues) for a full list of proposed features and known issues.

---

## 💬 Support

- 📧 **Email**: maintainers@xaostech.dev
- 💻 **Issues**: [GitHub Issues](https://github.com/XAOSTECH/design-flows/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/XAOSTECH/design-flows/discussions)
- 📝 **Wiki**: [GitHub Wiki](https://github.com/XAOSTECH/design-flows/wiki)

---

## 📄 License

Distributed under the GPL-3.0 License. See [`LICENSE`](LICENSE) for more information.

---

## 🙏 Acknowledgements

- [pastel](https://github.com/sharkdp/pastel) for CLI colour tooling
- VS Code workspace settings and colour customisation model
- Contributors and testers in XAOSTECH design workflows

---

<p align="center">
  <a href="https://github.com/XAOSTECH">
    <img src="https://img.shields.io/badge/Made%20with%20%E2%9D%A4%EF%B8%8F%20by-XAOSTECH-red?style=for-the-badge">
  </a>
</p>

<p align="center">
  <a href="#design-flows">⬆️ Back to Top</a>
</p>
