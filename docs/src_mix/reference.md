
# API reference

# API 参考


## Types

## 类型

```@autodocs
Modules = [BinaryBuilderBase, BinaryBuilder, BinaryBuilder.Auditor, BinaryBuilder.Wizard]
Order = [:type]
```


## Functions

＃＃ 职能

```@autodocs
Modules = [BinaryBuilderBase, BinaryBuilder, BinaryBuilder.Auditor, BinaryBuilder.Wizard]
Order = [:function]
# We'll include build_tarballs explicitly below, so let's exclude it here:
Filter = x -> !(isa(x, Function) && x === build_tarballs)
```


## Command Line

＃＃ 命令行

```@docs
build_tarballs
```


The [`build_tarballs`](@ref) function also parses command line arguments. The syntax is

[`build_tarballs`](@ref) 函数还解析命令行参数。语法是


described in the `--help` output:

`--help` 输出中描述：

````@eval
using BinaryBuilder, Markdown
Markdown.parse("""
```


$(BinaryBuilder.BUILD_HELP)

$(BinaryBuilder.BUILD_HELP)

```
""")
```

