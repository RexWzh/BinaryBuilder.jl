# 参考 API

> 译注：以下是自动生成的函数注释，也可以在 REPL 中通过 help 模式查看。

## 类型

```@autodocs
Modules = [BinaryBuilderBase, BinaryBuilder, BinaryBuilder.Auditor, BinaryBuilder.Wizard]
Order = [:type]
```

## 函数

```@autodocs
Modules = [BinaryBuilderBase, BinaryBuilder, BinaryBuilder.Auditor, BinaryBuilder.Wizard]
Order = [:function]
# We'll include build_tarballs explicitly below, so let's exclude it here:
Filter = x -> !(isa(x, Function) && x === build_tarballs)
```

## 命令行

```@docs
build_tarballs
```

[`build_tarballs`](@ref) 函数能解析命令行参数，语法通过 `--help` 查看：

````@eval
using BinaryBuilder, Markdown
Markdown.parse("""
```
$(BinaryBuilder.BUILD_HELP)
```
""")
```

