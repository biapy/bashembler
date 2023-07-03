# Bashembler

[![linting](https://github.com/biapy/bashembler/actions/workflows/super-linter.yaml/badge.svg)](https://github.com/biapy/bashembler/actions/workflows/super-linter.yaml)
[![tests](https://github.com/biapy/bashembler/actions/workflows/ci.yaml/badge.svg)](https://github.com/biapy/bashembler/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/biapy/bashembler/branch/main/graph/badge.svg?token=5XJ8H7BMG1)](https://codecov.io/gh/biapy/bashembler)
[![CodeFactor](https://www.codefactor.io/repository/github/biapy/bashembler/badge)](https://www.codefactor.io/repository/github/biapy/bashembler)

Bashembler -- contraction for bash-assembler -- aims to ease shell scripts
development by providing a way to split lengthy scripts in multiple files
included by `source` or `.` (dot) instructions, and assembling these files
in a final single-file script, ready for deployment.

[Bashembler @ Docker Hub](https://hub.docker.com/r/biapy/bashembler/).

## Usage

Process `script.bash` and output the result to `stdout`:

```bash
bashembler 'script.bash'
# Using docker
docker run --rm --volume '.:/data'  'biapy/bashembler' 'script.bash'
```

Process `script.sh` and store result in `bin/script-for-deployment`:

```bash
bashembler --output='bin/script-for-deployment' 'script.bash'
# Using docker
docker run --rm --volume '.:/data'  'biapy/bashembler' \
  --output='bin/script-for-deployment' 'script.bash'
```

Optionally, strip comments from result:

```bash
bashembler --discard-comments 'script.bash'
# Using docker
docker run --rm --volume '.:/data'  'biapy/bashembler' \
  --discard-comments 'script.bash'
```

## Third party libraries

Bashembler makes use of:

- [Biapy bashlings](https://github.com/biapy/biapy-bashlings).
- [shdoc](https://github.com/reconquest/shdoc) for building markdown
  documentation from code.
- [Pandoc](https://pandoc.org) for creating `man` page.
- [ShellCheck][shellcheck] for checking code quality.
- [shfmt][shfmt] for formating scripts.
- [ShellSpec][shellspec] for unit testing.

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
