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
* [usage](#usage)

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

* **-V** | **--version**

  Display version.

* **-q** | **--quiet**

  Disable error message output.

* **-v** | **--verbose**

  Enable verbose mode.

* **-w** | **--overwrite**

  Overwrite output path if it is an existing file.

* **-o\<output-path\>** | **--output=\<output-path\>**

  Write output to given path.

* -h | -? | --help Display usage information.

#### Arguments

* **$1** (string): A `bash`` (or `sh`) script file.

#### Exit codes

* **0**: If `bash`` script assembly is successful.
* **1**: If bashembler failed to assemble the script.
* **1**: If argument is missing, or more than one argument provided.
* **1**: If bashembler is unable to find a sourced file.

#### Output on stdout

* The one-file version of the $1 script, with sourced files included.

#### Output on stderr

* Error if argument is missing, or more than one argument provided.
* Error if output path exist, and --overwrite option is missing.
* Error if bashembler is unable to find a sourced file.

#### See also

* [cecho](#cecho)
* [realpath](#realpath)
* [process-options](#process-options)
* [sourced-file-path](#sourced-file-path)
* [include-sources](#include-sources)

### usage

Bashembler usage.

#### Output on stdout

* Bashembler usage information.

