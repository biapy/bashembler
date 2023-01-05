# src/bashembler.bash

build one-file bash script from multiple files source.

## Overview

bashembler, contraction for bash-assembler build one-file bash script
by including assembled script and sourced scripts into an unique output
file.

Partially inspired by:
[Replacing 'source file' with its content, and expanding variables, in bash](https://stackoverflow.com/questions/37531927/replacing-source-file-with-its-content-and-expanding-variables-in-bash)

## Index

* [bashembler](#bashembler)

### bashembler

bashembler, contraction for bash-assembler build one-file bash script
by including assembled script and sourced scripts into an unique output
file.
If available, resulting script is formated using shfmt
and checked using shellcheck.

#### Example

```bash
source "${BASH_SOURCE[0]%/*}/libs/biapy-bashlings/src/bashembler.bash"
bashembler "src/my-script.bash" > 'bin/my-script'
```

#### Options

* **-h** | **-?** | **--help**

Display usage information.

* **-V** | **--version**

  Display version.

* **-q** | **--quiet**

  Disable error message output.

* **-v** | **--verbose**

  Enable verbose mode.

* **-c** | **--discard-comments**

  Remove comment lines from assembled file.

* **-w** | **--overwrite**

  Overwrite output path if it is an existing file.

* **-o \<output-path\>** | **--output=\<output-path\>**

  Write output to given path.

#### Arguments

* **$1** (string): A `bash` (or `sh`) script file.

#### Exit codes

* **0**: If `bash` script assembly is successful.
* **1**: If argument is missing, or more than one argument provided.
* **2**: If an invalid option is given.
* **3**: If input `$1` does not exists.
* **4**: If output file can not be created or it already exists and --overwrite is not used..
* **5**: if source command can't be parsed.
* **6**: if sourced file does not exists.

#### Output on stdout

* The one-file version of the $1 script, with sourced files included.

#### Output on stderr

* Error if argument is missing, or more than one argument provided.
* Error if output path exist, and --overwrite option is missing.
* Error if bashembler is unable to find a sourced file.

#### See also

* [cecho](https://github.com/biapy/biapy-bashlings/blob/main/doc/cecho.md)
* [in-list](https://github.com/biapy/biapy-bashlings/blob/main/doc/in-list.md)
* [realpath](https://github.com/biapy/biapy-bashlings/blob/main/doc/realpath.md)
* [include-sources](./internals/include-sources.md#include-sources)

