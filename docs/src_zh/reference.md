# 参考 API

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

[`build_tarballs`](@ref) 函数还解析命令行参数。语法在 `--help` 输出中描述：

````@eval
using BinaryBuilder, Markdown
Markdown.parse("""
```
$(BinaryBuilder.BUILD_HELP)
```
""")
```

