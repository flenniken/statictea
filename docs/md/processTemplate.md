# processTemplate.nim

Process the template.


* [processTemplate.nim](../../src/processTemplate.nim) &mdash; Nim source code.
# Index

* [collectCommand](#collectcommand) &mdash; Read template lines and write out non-command lines.
* [processTemplate](#processtemplate) &mdash; Process the template.
* [processTemplateTop](#processtemplatetop) &mdash; Setup the environment streams then process the template.

# collectCommand

Read template lines and write out non-command lines. When a
nextline, block or replace command is found, return its lines.
This includes the command line and its continue lines.

On input extraLine is the first line to use.  On exit extraLine
is the line that caused the collection to stop which is commonly
the first replacement block line.


~~~nim
proc collectCommand(env: var Env; lb: var LineBuffer;
                    prepostTable: PrepostTable; extraLine: var ExtraLine): CmdLines {.
    raises: [IOError, OSError, ValueError, KeyError],
    tags: [ReadIOEffect, WriteIOEffect].}
~~~

# processTemplate

Process the template.


~~~nim
proc processTemplate(env: var Env; args: Args) {.
    raises: [ValueError, Exception, IOError, OSError, KeyError], tags: [
    TimeEffect, WriteIOEffect, ReadDirEffect, ReadIOEffect, RootEffect,
    ReadEnvEffect, WriteDirEffect].}
~~~

# processTemplateTop

Setup the environment streams then process the template.


~~~nim
proc processTemplateTop(env: var Env; args: Args) {.
    raises: [ValueError, IOError, OSError, Exception, KeyError], tags: [
    ReadDirEffect, WriteIOEffect, TimeEffect, ReadIOEffect, RootEffect,
    ReadEnvEffect, WriteDirEffect].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿