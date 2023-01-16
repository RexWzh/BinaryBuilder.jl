# JLL 包

`BinaryBuilder.jl` 旨在生成可在任何环境中使用的压缩包，但到目前为止，它们的主要用途是提供预构建的库和可执行文件，以便在 Julia 包中轻松使用。这是通过 JLL 包（“动态链接库” `Dynamic-Link Library` 的双关语，J 代表 Julia）完成的。它们可以像任何其他 Julia 包一样通过 REPL 中的 [Julia 包管理器](https://julialang.github.io/Pkg.jl/v1/) 安装

```
]add NAME_jll
```

然后加载

```
using NAME_jll
```

但是，大多数用户永远不需要自己执行这些步骤，JLL 包通常仅用作封装二进制库或可执行文件的包的依赖项。

大多数 JLL 包都位于 GitHub 上的 [`JuliaBinaryWrappers`](https://github.com/JuliaBinaryWrappers) 组织下，生成它们的构建器在 [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil /), 社区构建树。 `BinaryBuilder.jl` 允许任何人创建自己的 JLL 包并将它们发布到他们选择的 GitHub 存储库，而无需使用 Yggdrasil，请参阅[常见问题](@ref)。

## JLL 包的剖析

一个有点流行的误解是 JLL 包裹是“特殊的”。相反，它们是具有通用结构的简单 Julia 包，因为它们是自动生成的。下例为典型的 JLL 包树结构，其名称为 `NAME_jll.jl`：

```
NAME_jll
├── Artifacts.toml
├── LICENSE
├── Project.toml
├── README.md
└── src/
    ├── NAME_jll.jl
    └── wrappers/
        ├── aarch64-linux-gnu.jl
        ├── aarch64-linux-musl.jl
        ├── armv7l-linux-gnueabihf.jl
        ├── armv7l-linux-musleabihf.jl
        ├── i686-linux-gnu.jl
        ├── i686-linux-musl.jl
        ├── i686-w64-mingw32.jl
        ├── powerpc64le-linux-gnu.jl
        ├── x86_64-apple-darwin14.jl
        ├── x86_64-linux-gnu.jl
        ├── x86_64-linux-musl.jl
        ├── x86_64-unknown-freebsd11.1.jl
        └── x86_64-w64-mingw32.jl
```

这些是 JLL 包的主要成分：

* `LICENSE`，一个说明 JLL 包许可证的文件。请注意，这可能与它封装的库的许可证不同，后者记录在压缩包中；

* [`README.md`](https://en.wikipedia.org/wiki/README) 文件提供了一些有关封装内容的信息，例如封装提供的“产品”列表；

* [`Artifacts.toml` file](https://julialang.github.io/Pkg.jl/v1/artifacts/#Artifacts.toml-files-1) 包含有关给定包的所有可用压缩包(tarball)的信息。压缩包将上传到 GitHub 发行页；

* [`Project.toml`](https://julialang.github.io/Pkg.jl/v1/toml-files/#Project.toml-1) 文件描述了包的依赖关系及其兼容性；

* 包的主要文件名为 `src/NAME_jll.jl`。

  这是您发出命令时执行的内容

  ```jl
  using NAME_jll
  ```

  该文件读取 `Artifacts.toml` 中可用的压缩包列表，并选择与当前匹配的平台。某些 JLL 包并非为所有支持的平台构建。如果当前平台是 JLL 包不支持的平台之一，则调用结束。相反，如果支持当前平台，将包含 `src/wrappers/` 目录中的相应封装器；

* `wrappers/` 目录对每个平台提供一个文件。它们实际上大部分相同，由于特定于平台的细节而存在一些细微差别。下一节将更详细地分析封装器。

## 封装器

`src/wrappers/` 目录中的文件是围绕 JLL 包提供的二进制包自动生成的非常轻巧封装器。它们加载作为当前 JLL 包依赖项的所有 JLL 包，并导出生成当前 JLL 包的 `build_tarballs.jl` 脚本中列出的产品名称。其中，它们还定义了以下未导出的变量：

* `artifact_dir`: 当前工件安装的绝对路径平台。这是放置二进制文件/库/文件的“前缀”；


* `PATH`: 在当前 JLL 包中运行可执行文件所需的环境变量 [`PATH`](https://en.wikipedia.org/wiki/PATH_(variable)) 的值，如果有的话；

* `PATH_list`: `PATH` 中的目录列表，作为 `String` 向量；

* `LIBPATH`: 记录一列环境变量的取值用于共享库搜索，这里是当前 JLL 包提供库的正确值；

* `LIBPATH_list`：`LIBPATH` 中的目录列表，作为 `String` 的向量。


每个平台的封装文件还定义了 [`__init__()`](https://docs.julialang.org/en/v1/manual/modules/index.html#Module-initialization-and-precompilation-1) 函数JLL 包的，每次加载包时执行该代码。 `__init__()` 函数将填充上述大部分变量，并自动打开生成 JLL 包的 `build_tarballs.jl` 脚本产品中列出的共享库（如果存在的话）。


封装器中的其余代码特定于 JLL 包的每个产品，详情如下。如果您想查看提供所有主要三种产品的包的具体示例，请查看 [`Fontconfig_jll.jl`](https://github.com/JuliaBinaryWrappers/Fontconfig_jll.jl/tree/785936d816d1ae65c2a6648f3a6acbfd72535e36)。

除了上面每个 JLL 封装器定义的变量外，包 [`JLLWrappers`](https://github.com/JuliaPackaging/JLLWrappers.jl) 还定义了一个额外的未导出变量：

* `LIBPATH_env`: 当前平台共享库的搜索路径的环境变量名。这等于 Linux 和 FreeBSD 上的 `LD_LIBRARY_PATH`、macOS 上的 `DYLD_FALLBACK_LIBRARY_PATH` 和 Windows 上的 `PATH`。


在下文中，我们将以拥有这些产品的构建为例：

```julia
products = [
    FileProduct("src/data.txt", :data_txt),
    LibraryProduct("libdataproc", :libdataproc),
    ExecutableProduct("mungify", :mungify_exe),
]
```

### 库产品

[`LibraryProduct`](@ref) 是一个共享库，可以通过 Julia [`ccall`](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/) 编辑。假设产品名为 `libdataproc`，封装器定义了以下变量：

* `libdataproc`：这是应在 [`ccall`](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/index.html)中使用的被导出的[“静态”](https://docs.julialang.org/en/v1/manual/variables-and-scoping/#Constants-1)变量:

  ```julia
  num_chars = ccall((:count_characters, libdataproc), Cint,
                    (Cstring, Cint), data_lines[1], length(data_lines[1]))
  ```

  粗略地说，这个变量的值是共享库的基本名称，而不是它的完整绝对路径；


* `libdataproc_path`：共享库的完整绝对路径。注意这不是 `const`，因此不能在 `ccall` 中使用；

* `libdataproc_handle`: 共享库在初始化阶段加载后的内存地址。

### 可执行产品

[`ExecutableProduct`](@ref) 是可以在当前平台上运行的二进制可执行文件。例如，如果 `ExecutableProduct` 被称为 `mungify_exe`，则封装器定义一个名为 `mungify_exe` 的导出函数，用户应通过以下方式运行该函数：

```julia
# Only available in Julia v1.6+
run(`$(mungify_exe()) $arguments`)
```

```julia
mungify_exe() do exe
    run(`$exe $arguments`)
end
```
> 译注：后者等同于 `mungify_exe(exe->run($exe $arguments))` ？


请注意，在后一种形式中，`exe` 可以替换为您选择的任何名称：通过 [`do`-block](https://docs.julialang.org/en/v1/manual/functions/#Do-Block-Syntax-for-Function-Arguments-1) 语法，您正在定义将用于实际调用二进制文件的变量的名称 [`run`](https://docs.julialang.org/en/v1/base/base/#Base.run)。

前一种形式仅在使用 Julia v1.6 时可用，但在未来应该是首选，因为它是线程安全的并且通常更灵活。

关于 JLL 包 `ExecutableProduct` 的一个常见混淆点是为什么需要这些函数封装器：虽然原则上您可以通过在 `run` 中使用其绝对路径直接运行可执行文件，但这些函数确保可执行文件将找到所有共享运行时需要的库。

除了名为 `mungify_exe` 的函数外，对于该产品，还有以下未导出的变量：

* `mungify_exe_path`：可执行文件的完整绝对路径；

### 文件产品

[`FileProduct`](@ref) 是一个没有特殊处理的简单文件。例如，如果 `FileProduct` 被称为 `data_txt`，则为其定义的唯一变量是：

* `data_txt`: 这个导出的变量有指定文件的绝对路径：

  ```julia
  data_lines = open(data_txt, "r") do io
      readlines(io)
  end
  ```

* `data_txt_path`：这个未导出的变量实际上等于 `data_txt`，但用于保持与所有其他产品类型的一致性。

## 覆盖 JLL 包中的工件

如上所述，JLL 包使用 [Artifacts 系统](https://julialang.github.io/Pkg.jl/v1/artifacts) 来提供文件。如果你想用自己的二进制文件/库/文件覆盖工件的内容，你可以使用 [`Overrides.toml` 文件](https://julialang.github.io/Pkg.jl/v1/artifacts/#Overriding-artifact-locations-1).

我们在下面详细介绍了几种不同的方法来覆盖 JLL 包的工件，具体取决于包是否是“开发”的。第二种方法特别推荐给希望使用系统库代替 JLL 包中的库的系统管理员。

### `dev`'ed JLL 包

如果用户希望覆盖“开发”的 JLL 包中的内容，用户可以使用 JLL 包提供的 `dev_jll()` 方法将包的可变副本检出到他们的 `~/ .julia/dev` 目录。该包目录中将创建一个 `override` 目录，为用户提供一个方便的位置，以便将他们自己的文件复制到通常的工件源文件上。有关此功能的更多信息，请参阅本文档的 [Building Packages](./building.md) 部分中的“在本地构建和测试 JLL 包”部分。

### 非“开发”过的 JLL 包

例如，在 Linux 系统中，您可以覆盖 [`Fontconfig_jll.jl`](https://github.com/JuliaBinaryWrappers/Fontconfig_jll.jl) 提供的 Fontconfig 库和 [`Bzip2_jll.jl`](https://github.com/JuliaBinaryWrappers/Bzip2_jll.jl) 提供的 Bzip2 库，分别使用 `/usr/lib/libfontconfig.so` 和 `/usr/local/lib/libbz2.so` 以及以下 `Overrides.toml`：

```toml
[a3f928ae-7b40-5064-980b-68af3947d34b]
Fontconfig = "/usr"

[6e34b625-4abd-537c-b88f-471c36dfa7a0]
Bzip2 = "/usr/local"
```

关于如何编写此文件的一些评论：

* UUID 是 JLL 包的 UUID，

  `a3f928ae-7b40-5064-980b-68af3947d34b` 用于 `Fontconfig_jll.jl`，而 `6e34b625-4abd-537c-b88f-471c36dfa7a0` 用于 `Bzip2_jll.jl`。您可以在包的 `Project.toml` 文件中找到它们（例如，参见 [`Fontconfig_jll` 的 `Project.toml` 文件](https://github.com/JuliaBinaryWrappers/Fontconfig_jll.jl/blob/ 8904cd195ea4131b89cafd7042fd55e6d5dea241/Project.toml#L2)）或在注册表中查找（例如，请参阅[General 注册表中 `Fontconfig_jll` 的条目](https://github.com/JuliaRegistries/General/blob/caddd31e7878276f6e052f998cefdac/91f4/Fontconfig_jll/Package.toml#L2))。


* JLL packages 提供的 artifacts 与 packages 同名，在这种情况下，没有后缀 `_jll`、 `Fontconfig` 和 `Bzip2`。

* 工件位置保存在上面提到的 `artifact_dir` 变量中，这是软件包安装的“前缀”。回想一下，JLL 包中产品的路径是相对于 `artifact_dir` 的，您要用于覆盖 JLL 包产品的文件必须具有与工件相同的树结构。在我们的示例中，我们需要使用 `/usr` 覆盖 Fontconfig 和 `/usr/local` 用于 Bzip2。

### 覆盖特定产品

您可以使用 [Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl) 覆盖 JLL 中的特定产品（库、可执行文件或文件），而不是覆盖整个工件。

!!! 兼容问题
    本节需要 Julia 1.6 或更高版本。

作为例子，要覆盖我们的 `libbz2`：

```julia
using Preferences
set_preferences!(
    "LocalPreferences.toml",
    "Bzip2_jll",
    "libbzip2_path" => "/usr/local/lib/libbz2.so",
)
```


请注意，产品名称是 `libbzip2`，但我们使用 `libbzip2_path`。

!!! 警告
    在两种常见情况下这将不起作用：
  1. JLL 是 [Julia stdlib](https://github.com/JuliaLang/julia/tree/master/stdlib) 的一部分，例如 `Zlib_jll`
  2. JLL 尚未使用 [JLLWrappers.jl](https://github.com/JuliaPackaging/JLLWrappers.jl) 作为依赖项进行编译。在这种情况下，这意味着 JLL 的最后一次构建早于 JLLWrappers 包的引入，需要重新构建。请在 [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil/) 上提出问题请求新构建，或提出拉取请求以更新相关的 `build_tarballs.jl` 脚本。

