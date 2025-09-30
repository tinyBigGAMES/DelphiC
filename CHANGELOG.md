# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Create FUNDING.yml** (2025-09-28 – Jarrod Davis)


### Changed
- **Merge branch 'main' of https://github.com/tinyBigGAMES/DelphiC** (2025-09-29 – jarroddavis68)

- **Repo Update** (2025-09-29 – jarroddavis68)
  - 🎉 Initial release
  - 💻 Win64 TCC integration
  - 💾 Memory and file compilation modes
  - 🛡️ Comprehensive error handling
  - ⚙️ Full TCC option support
  - 📦 Multi-unit compilation
  - 🔄 Symbol bidirectionality

- **Update README.md** (2025-09-29 – Jarrod Davis)

- **Initial commit** (2025-09-28 – Jarrod Davis)


### Removed
- **Repo Update** (2025-09-29 – jarroddavis68)
  - Switched from kyx0r single-file TCC to official TinyCC repository for better runtime support
  - Fixed critical workflow state bug preventing multiple CompileString/AddFile calls in sequence
  - AddFile and CompileString now correctly allow multiple calls in wsConfigured or wsCompiled states
  - This fix enables proper multi-file compilation workflow (e.g., compile to .o, then link with main)
  - Official TCC provides proper libtcc1.a runtime library and startup code for EXE generation
  - Added comprehensive documentation distinguishing Reset() vs Clear() methods
  - Reset() now documented to preserve callbacks while Clear() removes all configuration
  - Improved XML documentation for both methods with clear examples of use cases

