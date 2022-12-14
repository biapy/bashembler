# src/internals/sourced-file-path.bash

Compute sourced file path from a bash source (or dot) command.

## Overview

`sourced-file-path` is a sub-function of `assemble-sources` that compute
a source command sourced file path.

## Index

* [function sourced-file-path {](#function-sourced-file-path-)

### function sourced-file-path {

Get sourced file from source (or dot) command.
When `--origin` option is not provided, the source content is returned as
is, without any modification.
When `--origin` option is provided, the function try to locate the sourced
file and return an error on failure.
If the file is located, it output the sourced file absolute path.

#### Example

```bash
source "${BASH_SOURCE[0]%/*}/libs/biapy-bashlings/src/internals/sourced-file-path.bash"
sourced_file="$(
    sourced-file-path 'source "${BASH_SOURCE[0]%/*}/libs/biapy-bashlings/src/cecho.bash"'
  )"
```

#### Options

* **-q** | **--quiet**

  Disable error messages when present.

* **-v** | **--verbose**

  Trigger verbose mode when present.

* **--origin**

  The file in which the source command is found.

#### Arguments

* **$1** (string): A Bash source or . (dot) include command.

#### Exit codes

* **0**: on success.
* **1**: if invalid option is given.
* **1**: if argument is missing or too many arguments given.
* **1**: if source command can't be parsed.
* **1**: if sourced file does not exists.

#### Output on stdout

* Source command argument if `--origin` is not provided.
* Sourced file absolute path if `--origin` is provided and file is found.

#### Output on stderr

* Error if invalid option is given.
* Error if argument is missing or too many arguments given.
* Error if source command can't be parsed.
* Error if sourced file does not exists.

#### See also

* [cecho](https://github.com/biapy/biapy-bashlings/blob/main/doc/cecho.md)
* [realpath](https://github.com/biapy/biapy-bashlings/blob/main/doc/realpath.md)
* [process-options](https://github.com/biapy/biapy-bashlings/blob/main/doc/process-options.md)
* [include-sources](./include-sources.md#include-sources)

