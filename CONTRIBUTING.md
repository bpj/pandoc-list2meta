## Note to contributors

The actual source code for this software, where you also
will find all comments, is to be found in the
`<SCRIPTNAME>.moon` file(s) and is written in
[MoonScript](https://moonscript.org).[^1] The file(s) you
should use is/are `<SCRIPTNAME>.lua`, which is/are generated
automatically with *moonc* which compiles MoonScript code
into Lua code. While the Lua code produced by *moonc* has
its quirks it is surprisingly readable, but it preserves
neither comments nor spacing.

If you want to hack on the software you install moonscript
with [luarocks](https://luarocks.org) (preferably the
development version since that is what I use), work on the
MoonScript code and and compile it with
`moonc <SCRIPTNAME>.moon` when you are done.

Likewise the source for `README.md` is in `readme-src.md`
and is, like the source for any other documentation written
in [Pandoc's](https://pandoc.org) flavor of Markdown, and
the GitHub Flavored Markdown in `README.md`, as well as any
documentation in other formats,was automatically generated
with pandoc. While the differences may currently be
negligible that may be subject to change.

If there is a `devtools` directory in the repository it may
contain MoonScript files not meant to be compiled into Lua
so don't run *moonc* on that directory or any
`<SCRIPTNAME>.moon` files in it for which there are no
corresponding `<SCRIPTNAME>.lua` files. In
general you should not submit pull requests modifying files
in that directory on your own initiative. Open an issue if
you think there are any bugfixes or improvements to be made,
possibly requesting review of modified files in a branch in
your own fork.

If there is a Makefile or `devtools/pandoc` directory in the
repository you should not run *make* or *pandoc* yourself to
generate any additional documentation, as this will be done
as needed by the maintainer. If there is a
`devtools/pandoc/filters.md` file it will contain a list of
Pandoc filters (and possibly other tools) needed to build
the documentation, along with links to where you can get
them.

Pull requests with modifications to the automatically
generated Lua code, `README.md` or other files meant to be
generated automatically will not be accepted!

[^1]: Here `<SCRIPTNAME>` in angle brackets is a placeholder
    for any name for which there may be a Lua file and a
    corresponding MoonScript file.
