[StaticTea Modules](/)

# processTemplate.nim

Process the template.

# Index

* [yieldContentLine](#user-content-a0) &mdash; Yield one content line at a time and keep the line endings.
* [processTemplate](#user-content-a1) &mdash; Process the template and return 0 on success.
* [updateTemplate](#user-content-a2) &mdash; Update the template and return 0 on success.
* [processTemplateTop](#user-content-a3) &mdash; Process the template and return 0 on success.
* [updateTemplateTop](#user-content-a4) &mdash; Update the template and return 0 on success.

# <a id="a0"></a>yieldContentLine

Yield one content line at a time and keep the line endings.

```nim
iterator yieldContentLine(content: string): string
```


# <a id="a1"></a>processTemplate

Process the template and return 0 on success. Return 1 if a warning messages was written while processing the template.

```nim
proc processTemplate(env: var Env; args: Args): int
```


# <a id="a2"></a>updateTemplate

Update the template and return 0 on success. Return 1 if a warning messages was written while processing the template.

```nim
proc updateTemplate(env: var Env; args: Args): int
```


# <a id="a3"></a>processTemplateTop

Process the template and return 0 on success. This calls processTemplate.

```nim
proc processTemplateTop(env: var Env; args: Args): int
```


# <a id="a4"></a>updateTemplateTop

Update the template and return 0 on success. This calls updateTemplate.

```nim
proc updateTemplateTop(env: var Env; args: Args): int
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
