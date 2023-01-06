% BASHEMBLER(1) bashembler v1.0.0
% Pierre-Yves Landuré <contact@biapy.fr>
% January 2023

# NAME

bashembler - build one-file bash script from multiple files source.

# SYNOPSIS

**bashembler** [*OPTION*...] *SHELL_SCRIPT_FILE* > *OUTPUT_FILE*

**bashembler** [*OPTION*...] [ *-o* *OUTPUT_FILE* | *--output=OUTPUT_FILE* ] *SHELL_SCRIPT_FILE*

# DESCRIPTION

bashembler, contraction for bash-assembler build one-file bash script
by including assembled script and sourced scripts into an unique output
file.

If available, resulting script is formated using **shfmt**
and checked using **shellcheck**.

# OPTIONS

**-h**, **-?**, **--help**

: Display usage information.

**-V**, **--version**

: Display version.

**-q**, **--quiet**

: Disable error message output.

**-v**, **--verbose**

: Enable verbose mode.

**-c**, **--discard-comments**

: Remove comment lines from assembled file.

**-w**, **--overwrite**

: Overwrite output path if it is an existing file.

**-o** *OUTPUT_FILE*, **--output=***OUTPUT_FILE*

: Write output to given path.

# EXIT STATUS

**0**

: Success

**1**

: Incorrect number of arguments given

**2**

: Invalid option given

**3**

: Input file not found

**4**

: Unable to create output file

**5**

: Unrecognized source command in input

**6**

: Sourced file not found

# RETURN VALUE

If *--output* option is not used, **bashembler** output the assembled script
on **stdout**. If *--quiet* is not used, it lists assembled files on **stderr**.

# BUGS

## Reporting bugs

You may report bugs at
[**bashembler** issues tracker](https://github.com/biapy/bashembler/issues).

## Known bugs

**bashembler** does not parse the shell script. It reads the scripts
contents line by line. This can lead to unwanted behaviour during output
generation:

* **--discard-comments** remove all lines starting by **#**, weither the line is
  in a multiline string or a EOF section.
* **source** and **.** (dot) commands parsing is minimal, and heavily **bash** oriented.
  As it is **bashembler** may not correctly process **zsh** or **fish** scripts.

# EXAMPLE

**bashembler** *-h* | **bashembler** *-?* | **bashembler** *--help*

: Displays usage information, then exits.

**bashembler** *-V* | **bashembler** *--version*

: Displays version information, then exits.

**bashembler** *script.sh*

: Assemble *script.sh* file and output results to **stdout**.

**bashembler** *script.sh* > *output.sh*

: Assemble *script.sh* file and pipe results to *output.sh* file.

**bashembler** --output=*output.sh* *script.sh*

: Assemble *script.sh* file and output results to *output.sh* file.

# SEE ALSO

* [Replacing source file with its content, and expanding variables, in bash](https://stackoverflow.com/questions/37531927/replacing-source-file-with-its-content-and-expanding-variables-in-bash)
* [Biapy Bashlings](https://github.com/biapy/biapy-bashlings/)
