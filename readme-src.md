---
abstract: Pandoc filter for converting marked djot
  definition lists to Pandoc metadata.
author: Benct Philip Jonsson <bpjonsson@gmail.com>
date: '2024-12-05'
title: list2meta.lua
version: '0.001'
no-meta: true
---

## Synopsis

```` djot
{.metadata}
:   foo

    bar

:   baz

    -   tic
    -   tac
    -   toc
    
:   quux

    A *list of inlines!*

:   bool

    `true`{=bool}

:   string

    `true`{=str}
    
:   big string

    ```=str
    First line.
    Second line.
    Third line.
    ```
    
:   bing

    :   bang

        bong

:   alpha

    {.nometa}
    :   Latin

        -   a
        -   b
        -   c

    :   Greek

        -   α
        -   β
        -   γ

    :   Cyrillic

        -   а
        -   б
        -   в
        -   г

This is a paragraph
````

``` sh
pandoc -L list2meta.lua -sw markdown meta.dj
```

``` markdown_pandoc
---
alpha: |

  Latin

  :   -   a
      -   b
      -   c

  Greek

  :   -   α
      -   β
      -   γ

  Cyrillic

  :   -   а
      -   б
      -   в
      -   г
baz:
- tic
- tac
- toc
big string: First line.  Second line.  Third line.
bing:
  bang: bong
bool: true
foo: bar
quux: A **list of inlines!**
string: "true"
---

This is a paragraph
```

## Rationale

I like [djot][] a lot, and it is now supported by Pandoc,
but it has no native format for in-document metadata which
is a major hurdle for me. This filter is meant to remove
that hurdle by "converting" specially marked djot definition
lists into Pandoc metadata.

## Description

The filter works by looking in the top level of the
document[^top] for definition lists which have
`.metadata` as their first and only class, and if it finds
any convert them into a structure which Pandoc's Lua API
accepts as metadata.

[^top]: In Lua filter terms any direct children of the `blocks`
list of the Pandoc document object.

For [technical reasons][] any top-level Div which has
`.metadata` as its only class is expected to have a
DefinitionList as its only child and will be treated the
same as a DefinitionList with `.metadata` as its only class.

During this conversion the top level DefinitionList and some
kinds of Pandoc elements found as descendants of it are
treated specially when they are the only [effective
content][] in a value of a list which is also being
converted:

Lists

:   

    **DefinitionList**

    :   These are converted into metadata mappings: each
        *term* is [stringified][] and used as a mapping key,
        and the *definitions* of each term are converted
        into a single list of blocks, with any single
        children of that list of blocks being converted
        further as applicable.

    **BulletList** and **OrderedList**

    :   These are converted into metadata lists, with any
        single children of each list item being converted
        further as applicable.

    Single-child lists which have a class `.nometa` are not
    converted into meta mappings and lists.

    For [technical reasons][] any single-child Div which has
    a class `.nometa` will be replaced with its content.

Other single children

:   

    **Para** and **Plain**

    :   These are converted into lists of inlines, i.e.
        effectively their content is used as a metadata
        value, with the exception of content lists with a
        **RawInline** as single child which meets one of the
        following criteria:

        -   `` `true`{=bool} `` and `` `false`{=bool} `` are
            converted into actual booleans. If a RawInline
            with `=bool` as format has any other text an
            error will be thrown.
        -   A RawInline with the "format" `str` will become
            a raw string (Lua type *string*) equal to the
            text of the RawInline.

        The same is true of single-child [djot symbols][]
        which looks like `:true:` or `:false:`. They will be
        converted to a Lua boolean, as will for [technical
        reasons][] any Pandoc Span with a class `.symbol`
        which is [stringified][] to "true" or "false".
        
## "Effective content"

Technically all Pandoc list element content, including
the definitions for a term in a definition list, are
represented in the AST as a list of lists of blocks.
This filter first flattens such lists into a single list of
blocks and then tries to convert single children of that list
which are Para or Plain elements into lists of inlines or even
raw strings or booleans as described above. In most
cases this means that list values "become what they
look like" compared to regular Pandoc YAML metadata, whether
in a metadata file or in a Markdown file.

## Non-djot input

For the [technical reason]{#technical-reasons} that djot
supports attributes on any elements while the Pandoc AST
only supports attributes on a few element types the djot
reader of Pandoc represents most elements which have
attributes in djot input in the Pandoc AST wrapped in a Div
(for block elements) or a Span (for inline elements) which
"carries" the attributes. These wrappers also have an extra
attribute `wrapper="1"` which tells the djot writer of
Pandoc to "unwrap" the wrapped element and assign the
(other) attributes of the wrapper to it. (Indeed you can
wrap elements this way manually when converting from
Markdown to djot!)

Because of this the filter does not actually look for
definition lists with a `.metadata` class but for *divs with
such a class whose only child is a definition list,* and
likewise not for lists with a `.nometa` class but for *any
div with a `.nometa` class.*

Moreover **the filter ignores the `wrapper="1"` attribute**,
both its presence and its absence, because I want to avoid
the extra clutter of the attribute when using this filter
with Markdown input, for which there are IMO legitimate
reasons:

-   The "pseudo-metadata" handled by this filter effectively
    has higher precedence than real in-document metadata[^1]
    which may be useful sometimes, because when you specify
    multiple Markdown input files to Pandoc all their
    metadata blocks are merged. With this filter you can
    place a "pseudo-metadata block" in any of your files and
    have it override real metadata in any of the files.

Likewise [djot symbols][] are represented in the Pandoc AST
as spans with a single class `.symbol`. For this reason *any
span with such a class whose text stringifies to "true" or
"false"* will be "converted" to a real boolean when it
occurs as the single child of a list value (in
"pseudo-metadata").

## Source code

The actual source code for this filter, where you also will
find all comments, is to be found in `list2meta.moon` and is
written in [MoonScript][]. The file you should use as a
filter is `list2meta.lua`, which is generated automatically
with `moonc` which compiles MoonScript code into Lua code.
While the Lua code produced by `moonc` has its quirks it is
surprisingly readable, but it preserves neither comments nor
spacing. If you want to hack on the filter I recommend that
you install moonscript with [luarocks][] (preferably the
development version since that is what I use), work on the
MoonScript code and and compile it with
`moonc list2meta.moon` when you are done.

Likewise the source for `README.md` is in `readme-src.md`,
written in [Pandoc's][pandoc] flavor of Markdown, and the GitHub
Flavored Markdown in `README.md` was automatically generated
with pandoc. While the differences may currently be
negligible that may be subject to change.

[^1]: Also of course higher precedence than metadata in
    defaults files and metadata files.

  [djot]: https://djot.net/
  [technical reasons]: #technical-reasons
  [effective content]: #effective-content
  [stringified]: https://pandoc.org/lua-filters.html#pandoc.utils.stringify
  [djot symbols]: https://htmlpreview.github.io/?https://github.com/jgm/djot/blob/master/doc/syntax.html#symbols
  [MoonScript]: https://moonscript.org
  [luarocks]: https://luarocks.org
  [pandoc]: https://pandoc.org
