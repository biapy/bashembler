# src/internal/include-sources.bash

`bashembler` logic, recursivly including sourced files in main script.

## Overview

include-sources read line by line a bash (or sh script) and look for
`source` (or dot (i.e. `.`)) commands. When a `source` command is
encountered, `include-sources` try to resolve the sourced file path, and
recursively process the sourced files. Each read line is outputed as is
to `/dev/stdout`, except for the source commands which are replaced by
the sourced files.

## Index

* [include-sources](#include-sources)

### include-sources

include-sources read line by line a bash (or sh script) and look for
`source` (or dot (i.e. `.`)) commands. When a `source` command is
encountered, `include-sources` try to resolve the sourced file path, and
recursively process the sourced files. Each read line is outputed as is
to `/dev/stdout`, except for the source commands which are replaced by
the sourced files.

#### Example

```bash
source "${BASH_SOURCE[0]%/*}/libs/biapy-bashlings/src/internals/include-sources.bash"
$contents="$( include-sources --origin="src/my-script.bash" "src/my-script.bash" )"
```

#### Options

* **-q** | **--quiet**

  Disable error messages when present.

* **-v** | **--verbose**

  Trigger verbose mode when present.

* **--discard-comments**

  Remove comment lines (eg, starting by '#') from assembled file.

* **--level=\<level\>**

  The distance from origin shell script (0 for origin).

* **--origin=\<origin-file-path\>**

  The origin shell script file path (i.e, first processed file, before recursion).

* **--output=\<output-file-path\>**

  The output shell script file path.

#### Arguments

* **$1** (string): A `bash` (or `sh`) script file.

#### Exit codes

* **0**: If `bash`` script assembly is successful.
* **1**: If argument is missing, or more than one argument provided.
* **2**: If an invalid option is given.
* **3**: If input `$1` does not exists.
* **4**: If output file can not be created.
* **5**: if source command can't be parsed.
* **6**: if sourced file does not exists.

#### Output on stdout

* The one-file version of the $1 script, with sourced files included, if `--output` is not used.

#### Output on stderr

* Error if argument is missing, or more than one argument provided.
* Error if invalid option provided.
* Error if include-sources is unable to find a sourced file.

#### See also

* [https://stackoverflow.com/questions/37531927/replacing-source-file-with-its-content-and-expanding-variables-in-bash](https://stackoverflow.com/questions/37531927/replacing-source-file-with-its-content-and-expanding-variables-in-bash)
* [cecho](https://github.com/biapy/biapy-bashlings/blob/main/doc/cecho.md)
* [realpath](https://github.com/biapy/biapy-bashlings/blob/main/doc/realpath.md)
* [repeat-string](https://github.com/biapy/biapy-bashlings/blob/main/doc/repeat-string.md)
* [process-options](https://github.com/biapy/biapy-bashlings/blob/main/doc/process-options.md)
* [sourced-file-path](./sourced-file-path.md#sourced-file-path)

