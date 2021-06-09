[StaticTea Modules](./)

# tpub.nim

The tpub macro pragma makes private routines public for testing. This allows you to test private procedures in external test files. When the test option is off, the macros do nothing.

# Index

* macro: [tpub](#user-content-a0) &mdash; Exports a procedure or function when in test mode so it can be tested in an external module.
* macro: [tpubType](#user-content-a1) &mdash; Exports a type when in test mode so it can be tested in an external module.

# <a id="a0"></a>tpub

Exports a procedure or function when in test mode so it can be tested in an external module.

Here is an example that makes myProcToTest public in
test mode:

.. code::

  proc myProcToTest(value:int): string {.tpub.} =

```nim
macro tpub(x: untyped): untyped
```


# <a id="a1"></a>tpubType

Exports a type when in test mode so it can be tested in an external module.

Here is an example that makes the type "SectionInfo" public in
test mode:

.. code::

  import tpub
  tpubType:
    type
      SectionInfo = object
        name*: string

```nim
macro tpubType(x: untyped): untyped
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
