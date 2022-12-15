# Bashembler

[![linting](https://github.com/biapy/bashembler/actions/workflows/super-linter.yaml/badge.svg)](https://github.com/biapy/bashembler/actions/workflows/super-linter.yaml)
[![tests](https://github.com/biapy/bashembler/actions/workflows/ci.yaml/badge.svg)](https://github.com/biapy/bashembler/actions/workflows/ci.yaml)

Bashembler -- contraction for bash-assembler -- aims to ease shell sccript
development by providing a way to split lenghty scripts in multiple files
included by `source` or `.` (dot) instructions, and assembling these files
in a final one-file script, ready for deployment.

## Usage

Process `script.bash` and output the result to `stdout`:

```bash
bashembler 'script.bash'
```

Process `script.sh` and store result in `bin/script-for-deployment`:

```bash
bashembler --output='bin/script-for-deployment' 'script.sh'
```

## Third party libraries

Bashembler makes use of:

- **[Biapy bashlings](https://github.com/biapy/biapy-bashlings).
- **[shdoc](https://github.com/reconquest/shdoc)** for generating markdown
  documentation from code.
- [ShellCheck][shellcheck] for checking code
  quality.
- [shfmt][shfmt] for formating scripts and bats unit
  tests.
- **[ShellSpec][shellspec]**
  for unit testing.

## Contributing

### Git

#### Cloning

This library uses the [ShellSpec][shellspec] library for unit-testing.

Clone the repository with the additionnal libraries:

```bash
git clone --recurse-submodules 'git@github.com:biapy/bashembler'
```

#### Updating submodules

Update the submodules with:

```bash
git submodule update --remote
```

[shellspec]: https://shellspec.info/
[shellcheck]: https://github.com/koalaman/shellcheck
[shfmt]: https://github.com/mvdan/sh

#### Utilities

The `Makefile` provides these rules:

- **help** : Display a short help message about the rules available in the
  `Makefile`.
- **clean** : Delete generated documentation in `doc/` and remove functions
  list from `README.md`.
- **format** : format files using `shfmt` on `*.bash` files in `src/` and
  `*.bats` files in `test/`.
- **check** : check files for errors using `shellcheck` on `*.bash` files
  in `src/`.
- **test** : run unit tests.
- **doc** : Generate documentation in `doc/` using `shdoc`.
- **all** : All of the above.
