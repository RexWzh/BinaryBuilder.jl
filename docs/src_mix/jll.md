
# JLL packages

# 仲量联行包裹


`BinaryBuilder.jl` is designed to produce tarballs that can be used in any environment, but so far their main use has been to provide pre-built libraries and executables to be readily used in Julia packages.  This is accomplished by JLL packages (a pun on "Dynamic-Link Library", with the J standing for Julia). They can be installed like any other Julia packages with the [Julia package manager](https://julialang.github.io/Pkg.jl/v1/) in the REPL with

`BinaryBuilder.jl` 旨在生成可在任何环境中使用的 tarball，但到目前为止，它们的主要用途是提供预构建的库和可执行文件，以便在 Julia 包中轻松使用。这是通过 JLL 包（“动态链接库”的双关语，J 代表 Julia）完成的。它们可以像任何其他 Julia 包一样通过 REPL 中的 [Julia 包管理器](https://julialang.github.io/Pkg.jl/v1/) 安装

```
]add NAME_jll
```


and then loaded with

然后加载

```
using NAME_jll
```


However, most users will not ever need to do these steps on their own, JLL packages are usually only used as dependencies of packages wrapping binary libraries or executables.

但是，大多数用户永远不需要自己执行这些步骤，JLL 包通常仅用作包装二进制库或可执行文件的包的依赖项。


Most JLL packages live under the [`JuliaBinaryWrappers`](https://github.com/JuliaBinaryWrappers) organization on GitHub, and the builders to generate them are maintaned in [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil/), the community build tree.  `BinaryBuilder.jl` allows anyone to create their own JLL package and publish them to a GitHub repository of their choice without using Yggdrasil, see the [Frequently Asked Questions](@ref).

大多数 JLL 包都位于 GitHub 上的 [`JuliaBinaryWrappers`](https://github.com/JuliaBinaryWrappers) 组织下，生成它们的构建器在 [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil /), 社区构建树。 `BinaryBuilder.jl` 允许任何人创建自己的 JLL 包并将它们发布到他们选择的 GitHub 存储库，而无需使用 Yggdrasil，请参阅[常见问题](@ref)。


## Anatomy of a JLL package

## JLL 包的剖析


A somewhat popular misconception is that JLL packages are "special".  Instead, they are simple Julia packages with a common structure, as they are generated automatically.  This is the typical tree of a JLL package, called in this example `NAME_jll.jl`:

一个有点流行的误解是 JLL 包裹是“特殊的”。相反，它们是具有通用结构的简单 Julia 包，因为它们是自动生成的。这是 JLL 包的典型树，在此示例中称为“NAME_jll.jl”：

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


These are the main ingredients of a JLL package:

这些是 JLL 包的主要成分：


* `LICENSE`, a file stating the license of the JLL package.  Note that this may

* `LICENSE`，一个说明 JLL 包许可证的文件。请注意，这可能


  differ from the license of the library it wraps, which is instead shipped   inside the tarballs;

与它包装的库的许可证不同，后者是在 tarball 中运送的；


* a [`README.md`](https://en.wikipedia.org/wiki/README) file providing some

[`README.md`](https://en.wikipedia.org/wiki/README) 文件提供了一些


  information about the content of the wrapper, like the list of "products"   provided by the package;

有关包装内容的信息，例如包装提供的“产品”列表；


* the [`Artifacts.toml`

* [`Artifacts.toml`


  file](https://julialang.github.io/Pkg.jl/v1/artifacts/#Artifacts.toml-files-1)   contains the information about all the available tarballs for the given   package.  The tarballs are uploaded to GitHub releases;

file](https://julialang.github.io/Pkg.jl/v1/artifacts/#Artifacts.toml-files-1) 包含有关给定包的所有可用压缩包的信息。压缩包上传到 GitHub 发布；


* the

* 这


  [`Project.toml`](https://julialang.github.io/Pkg.jl/v1/toml-files/#Project.toml-1)   file describes the packages dependencies and their compatibilities;

[`Project.toml`](https://julialang.github.io/Pkg.jl/v1/toml-files/#Project.toml-1) 文件描述了包的依赖关系及其兼容性；


* the main entry point of the package is the file called `src/NAME_jll.jl`.

* 包的主要入口点是名为 src/NAME_jll.jl 的文件。


  This is what is executed when you issue the command

这是您发出命令时执行的内容

```jl
  using NAME_jll
  ```


  This file reads the list of tarballs available in `Artifacts.toml` and choose   the platform matching the current platform.  Some JLL packages are not built   for all supported platforms.  If the current platform is one of those platform   not supported by the JLL package, this is the end of the package.  Instead, if   the current platform is supported, the corresponding wrapper in the   `src/wrappers/` directory will be included;

该文件读取 Artifacts.toml 中可用的 tarball 列表，并选择与当前平台匹配的平台。某些 JLL 包并非为所有支持的平台构建。如果当前平台是 JLL 包不支持的平台之一，则包结束。相反，如果支持当前平台，将包含 `src/wrappers/` 目录中的相应包装器；


* the `wrappers/` directory contains a file for each of the supported

* `wrappers/` 目录包含每个支持的文件


  platforms.  They are actually mostly identical, with some small differences   due to platform-specific details.  The wrappers are analyzed in more details   in the following section.

平台。它们实际上大部分相同，由于特定于平台的细节而存在一些细微差别。下一节将更详细地分析包装器。


## The wrappers

## 包装器


The files in the `src/wrappers/` directory are very thin automatically-generated wrappers around the binary package provided by the JLL package.  They load all the JLL packages that are dependencies of the current JLL package and export the names of the products listed in the `build_tarballs.jl` script that produced the current JLL package.  Among others, they also define the following unexported variables:

`src/wrappers/` 目录中的文件是围绕 JLL 包提供的二进制包自动生成的非常薄的包装器。它们加载作为当前 JLL 包依赖项的所有 JLL 包，并导出生成当前 JLL 包的 `build_tarballs.jl` 脚本中列出的产品名称。其中，它们还定义了以下未导出的变量：


* `artifact_dir`: the absolute path to where the artifact for the current

* `artifact_dir`: 当前工件所在位置的绝对路径


  platform has been installed.  This is the "prefix" where the   binaries/libraries/files are placed;

平台已安装。这是放置二进制文件/库/文件的“前缀”；


* `PATH`: the value of the

* `PATH`: 的值


  [`PATH`](https://en.wikipedia.org/wiki/PATH_(variable)) environment variable   needed to run executables in the current JLL package, if any;

[`PATH`](https://en.wikipedia.org/wiki/PATH_(variable)) 在当前 JLL 包中运行可执行文件所需的环境变量（如果有）；


* `PATH_list`: the list of directories in `PATH` as a vector of `String`s;

* `PATH_list`: `PATH` 中的目录列表，作为 `String` 的向量；


* `LIBPATH`: the value of the environment variable that holds the list of

* `LIBPATH`: 保存列表的环境变量的值


  directories in which to search shared libraries.  This has the correct value   for the libraries provided by the current JLL package;

搜索共享库的目录。这对于当前 JLL 包提供的库具有正确的值；


* `LIBPATH_list`: the list of directories in `LIBPATH` as a vector of `String`s.

* `LIBPATH_list`：`LIBPATH` 中的目录列表，作为 `String` 的向量。


The wrapper files for each platform also define the [`__init__()`](https://docs.julialang.org/en/v1/manual/modules/index.html#Module-initialization-and-precompilation-1) function of the JLL package, the code that is executed every time the package is loaded.  The `__init__()` function will populate most of the variables mentioned above and automatically open the shared libraries, if any, listed in the products of the `build_tarballs.jl` script that generated the JLL package.

每个平台的包装文件还定义了 [`__init__()`](https://docs.julialang.org/en/v1/manual/modules/index.html#Module-initialization-and-precompilation-1) 函数JLL包的，每次加载包时执行的代码。 `__init__()` 函数将填充上述大部分变量，并自动打开生成 JLL 包的 `build_tarballs.jl` 脚本产品中列出的共享库（如果有）。


The rest of the code in the wrappers is specific to each of the products of the JLL package and detailed below.  If you want to see a concrete example of a package providing all the main three products, have a look at [`Fontconfig_jll.jl`](https://github.com/JuliaBinaryWrappers/Fontconfig_jll.jl/tree/785936d816d1ae65c2a6648f3a6acbfd72535e36).

包装器中的其余代码特定于 JLL 包的每个产品，详情如下。如果您想查看提供所有主要三种产品的包的具体示例，请查看 [`Fontconfig_jll.jl`](https://github.com/JuliaBinaryWrappers/Fontconfig_jll.jl/tree/785936d816d1ae65c2a6648f3a6acbfd72535e36)。


In addition to the variables defined above by each JLL wrapper, the package [`JLLWrappers`](https://github.com/JuliaPackaging/JLLWrappers.jl) defines an additional unexported variable:

除了上面每个 JLL 包装器定义的变量外，包 [`JLLWrappers`](https://github.com/JuliaPackaging/JLLWrappers.jl) 还定义了一个额外的未导出变量：


* `LIBPATH_env`: the name of the environment variable of the search paths of the

* `LIBPATH_env`: 搜索路径的环境变量名


  shared libraries for the current platform.  This is equal to `LD_LIBRARY_PATH`   on Linux and FreeBSD, `DYLD_FALLBACK_LIBRARY_PATH` on macOS, and `PATH` on   Windows.

当前平台的共享库。这等于 Linux 和 FreeBSD 上的“LD_LIBRARY_PATH”、macOS 上的“DYLD_FALLBACK_LIBRARY_PATH”和 Windows 上的“PATH”。


In what follows, we will use as an example a builder that has these products:

在下文中，我们将以拥有这些产品的建筑商为例：

```julia
products = [
    FileProduct("src/data.txt", :data_txt),
    LibraryProduct("libdataproc", :libdataproc),
    ExecutableProduct("mungify", :mungify_exe),
]
```


### LibraryProduct

### 图书馆产品


A [`LibraryProduct`](@ref) is a shared library that can be [`ccall`](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)ed from Julia.  Assuming that the product is called `libdataproc`, the wrapper defines the following variables:

[`LibraryProduct`](@ref) 是一个共享库，可以是 [`ccall`](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)从朱莉娅编辑。假设产品名为 libdataproc，包装器定义了以下变量：


* `libdataproc`: this is the exported

* `libdataproc`：这是导出的


  [`const`](https://docs.julialang.org/en/v1/manual/variables-and-scoping/#Constants-1)   variable that should be used in   [`ccall`](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/index.html):

[`const`](https://docs.julialang.org/en/v1/manual/variables-and-scoping/#Constants-1) 应在 [`ccall`](https://docs .julialang.org/en/v1/manual/calling-c-and-fortran-code/index.html):

```julia
  num_chars = ccall((:count_characters, libdataproc), Cint,
                    (Cstring, Cint), data_lines[1], length(data_lines[1]))
  ```


  Roughly speaking, the value of this variable is the basename of the shared   library, not its full absolute path;

粗略地说，这个变量的值是共享库的基本名称，而不是它的完整绝对路径；


* `libdataproc_path`: the full absolute path of the shared library.  Note that

* `libdataproc_path`：共享库的完整绝对路径。注意


  this is not `const`, thus it can't be used in `ccall`;

这不是 const，因此不能在 ccall 中使用；


* `libdataproc_handle`: the address in memory of the shared library after it has

* `libdataproc_handle`: 共享库在内存中的地址


  been loaded at initialization time.

在初始化时加载。


### ExecutableProduct

### 可执行产品


An [`ExecutableProduct`](@ref) is a binary executable that can be run on the current platform.  If, for example, the `ExecutableProduct` has been called `mungify_exe`, the wrapper defines an exported function named `mungify_exe` that should run by the user in one the following ways:

[`ExecutableProduct`](@ref) 是可以在当前平台上运行的二进制可执行文件。例如，如果 `ExecutableProduct` 被称为 `mungify_exe`，则包装器定义一个名为 `mungify_exe` 的导出函数，用户应通过以下方式运行该函数：

```julia
# Only available in Julia v1.6+
run(`$(mungify_exe()) $arguments`)
```

```julia
mungify_exe() do exe
    run(`$exe $arguments`)
end
```


Note that in the latter form `exe` can be replaced with any name of your choice: with the [`do`-block](https://docs.julialang.org/en/v1/manual/functions/#Do-Block-Syntax-for-Function-Arguments-1) syntax you are defining the name of the variable that will be used to actually call the binary with [`run`](https://docs.julialang.org/en/v1/base/base/#Base.run).

请注意，在后一种形式中，`exe` 可以替换为您选择的任何名称：使用 [`do`-block](https://docs.julialang.org/en/v1/manual/functions/#Do- Block-Syntax-for-Function-Arguments-1) 语法，您正在定义将用于实际调用二进制文件的变量名称 [`run`](https://docs.julialang.org/en/v1 /base/base/#Base.run）。


The former form is only available when using Julia v1.6, but should be preferred going forward, as it is thread-safe and generally more flexible.

前一种形式仅在使用 Julia v1.6 时可用，但在未来应该是首选，因为它是线程安全的并且通常更灵活。


A common point of confusion about `ExecutableProduct`s in JLL packages is why these function wrappers are needed: while in principle you could run the executable directly by using its absolute path in `run`, these functions ensure that the executable will find all shared libraries it needs while running.

关于 JLL 包中的 ExecutableProduct 的一个常见混淆点是为什么需要这些函数包装器：虽然原则上您可以通过在 run 中使用其绝对路径直接运行可执行文件，但这些函数确保可执行文件将找到所有共享运行时需要的库。


In addition to the function called `mungify_exe`, for this product there will be the following unexported variables:

除了名为 `mungify_exe` 的函数外，对于该产品，还有以下未导出的变量：


* `mungify_exe_path`: the full absolute path of the executable;

* `mungify_exe_path`：可执行文件的完整绝对路径；


### FileProduct

### 文件产品


A [`FileProduct`](@ref) is a simple file with no special treatment.  If, for example, the `FileProduct` has been called `data_txt`, the only variables defined for it are:

[`FileProduct`](@ref) 是一个没有特殊处理的简单文件。例如，如果 `FileProduct` 被称为 `data_txt`，则为其定义的唯一变量是：


* `data_txt`: this exported variable has the absolute path to the mentioned

* `data_txt`: 这个导出的变量有提到的绝对路径


  file:

文件：

```julia
  data_lines = open(data_txt, "r") do io
      readlines(io)
  end
  ```


* `data_txt_path`: this unexported variable is actually equal to `data_txt`, but

* `data_txt_path`：这个未导出的变量实际上等于`data_txt`，但是


  is kept for consistency with all other product types.

保持与所有其他产品类型的一致性。


## Overriding the artifacts in JLL packages

## 覆盖 JLL 包中的工件


As explained above, JLL packages use the [Artifacts system](https://julialang.github.io/Pkg.jl/v1/artifacts) to provide the files. If you wish to override the content of an artifact with their own binaries/libraries/files, you can use the [`Overrides.toml` file](https://julialang.github.io/Pkg.jl/v1/artifacts/#Overriding-artifact-locations-1).

如上所述，JLL 包使用 [Artifacts 系统](https://julialang.github.io/Pkg.jl/v1/artifacts) 来提供文件。如果你想用自己的二进制文件/库/文件覆盖工件的内容，你可以使用 [`Overrides.toml` 文件](https://julialang.github.io/Pkg.jl/v1/artifacts/ #Overriding-artifact-locations-1).


We detail below a couple of different ways to override the artifact of a JLL package, depending on whether the package is `dev`'ed or not.  The second method is particularly recommended to system administrator who wants to use system libraries in place of the libraries in JLL packages.

我们在下面详细介绍了几种不同的方法来覆盖 JLL 包的工件，具体取决于包是否是“开发”的。第二种方法特别推荐给希望使用系统库代替 JLL 包中的库的系统管理员。


### `dev`'ed JLL packages

### `dev`'ed JLL 包


In the event that a user wishes to override the content within a `dev`'ed JLL package, the user may use the `dev_jll()` method provided by JLL packages to check out a mutable copy of the package to their `~/.julia/dev` directory.  An `override` directory will be created within that package directory, providing a convenient location for the user to copy in their own files over the typically artifact-sourced ones.  See the segment on "Building and testing JLL packages locally" in the [Building Packages](./building.md) section of this documentation for more information on this capability.

如果用户希望覆盖“开发”的 JLL 包中的内容，用户可以使用 JLL 包提供的“dev_jll()”方法将包的可变副本检出到他们的“~/ .julia/dev` 目录。将在该包目录中创建一个“override”目录，为用户提供一个方便的位置，以便将他们自己的文件复制到通常来自工件的文件上。有关此功能的更多信息，请参阅本文档 [Building Packages](./building.md) 部分中有关“在本地构建和测试 JLL 包”的部分。


### Non-`dev`'ed JLL packages

### 非 `dev`'ed JLL 包


As an example, in a Linux system you can override the Fontconfig library provided by [`Fontconfig_jll.jl`](https://github.com/JuliaBinaryWrappers/Fontconfig_jll.jl) and the Bzip2 library provided by [`Bzip2_jll.jl`](https://github.com/JuliaBinaryWrappers/Bzip2_jll.jl) respectively with `/usr/lib/libfontconfig.so` and `/usr/local/lib/libbz2.so` with the following `Overrides.toml`:

例如，在 Linux 系统中，您可以覆盖 [`Fontconfig_jll.jl`](https://github.com/JuliaBinaryWrappers/Fontconfig_jll.jl) 提供的 Fontconfig 库和 [`Bzip2_jll.jl` 提供的 Bzip2 库](https://github.com/JuliaBinaryWrappers/Bzip2_jll.jl) 分别使用 `/usr/lib/libfontconfig.so` 和 `/usr/local/lib/libbz2.so` 以及以下 `Overrides.toml`：

```toml
[a3f928ae-7b40-5064-980b-68af3947d34b]
Fontconfig = "/usr"

[6e34b625-4abd-537c-b88f-471c36dfa7a0]
Bzip2 = "/usr/local"
```


Some comments about how to write this file:

关于如何编写此文件的一些评论：


* The UUIDs are those of the JLL packages,

* UUID 是 JLL 包的 UUID，


  `a3f928ae-7b40-5064-980b-68af3947d34b` for `Fontconfig_jll.jl` and   `6e34b625-4abd-537c-b88f-471c36dfa7a0` for `Bzip2_jll.jl`.  You can either   find them in the `Project.toml` files of the packages (e.g., see [the   `Project.toml` file of   `Fontconfig_jll`](https://github.com/JuliaBinaryWrappers/Fontconfig_jll.jl/blob/8904cd195ea4131b89cafd7042fd55e6d5dea241/Project.toml#L2))   or look it up in the registry (e.g., see [the entry for `Fontconfig_jll` in   the General   registry](https://github.com/JuliaRegistries/General/blob/caddd31e7878276f6e052f998eac9f41cdf16b89/F/Fontconfig_jll/Package.toml#L2)).

`a3f928ae-7b40-5064-980b-68af3947d34b` 用于 `Fontconfig_jll.jl` 和 `6e34b625-4abd-537c-b88f-471c36dfa7a0` 用于 `Bzip2_jll.jl`。您可以在包的 `Project.toml` 文件中找到它们（例如，参见 [`Fontconfig_jll` 的 `Project.toml` 文件](https://github.com/JuliaBinaryWrappers/Fontconfig_jll.jl/blob/ 8904cd195ea4131b89cafd7042fd55e6d5dea241/Project.toml#L2)）或在注册表中查找（例如，请参阅[General 注册表中 `Fontconfig_jll` 的条目](https://github.com/JuliaRegistries/General/blob/caddd31e7878276f6e052f998cefdac/91f4 /Fontconfig_jll/Package.toml#L2))。


* The artifacts provided by JLL packages have the same name as the packages,

* JLL packages提供的artifacts与packages同名，


  without the trailing `_jll`, `Fontconfig` and `Bzip2` in this case.

在这种情况下，没有尾随的 _jll 、 Fontconfig 和 Bzip2 。


* The artifact location is held in the `artifact_dir` variable mentioned above,

* 工件位置保存在上面提到的 `artifact_dir` 变量中，


  which is the "prefix" of the installation of the package.  Recall the paths of   the products in the JLL package is relative to `artifact_dir` and the files   you want to use to override the products of the JLL package must have the same   tree structure as the artifact.  In our example we need to use `/usr` to   override Fontconfig and `/usr/local` for Bzip2.

这是软件包安装的“前缀”。回想一下，JLL 包中产品的路径是相对于 `artifact_dir` 的，您要用于覆盖 JLL 包产品的文件必须具有与工件相同的树结构。在我们的示例中，我们需要使用 `/usr` 覆盖 Fontconfig 和 `/usr/local` 用于 Bzip2。


### Overriding specific products

### 覆盖特定产品


Instead of overriding the entire artifact, you can override a particular product (library, executable, or file) within a JLL using [Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl).

您可以使用 [Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl) 覆盖 JLL 中的特定产品（库、可执行文件或文件），而不是覆盖整个工件。


!!! compat

！！！兼容


    This section requires Julia 1.6 or later.

本节需要 Julia 1.6 或更高版本。


For example, to override our `libbz2` example:

例如，要覆盖我们的 `libbz2` 示例：

```julia
using Preferences
set_preferences!(
    "LocalPreferences.toml",
    "Bzip2_jll",
    "libbzip2_path" => "/usr/local/lib/libbz2.so",
)
```


Note that the product name is `libbzip2`, but we use `libbzip2_path`.

请注意，产品名称是 `libbzip2`，但我们使用 `libbzip2_path`。


!!! warning

！！！警告


    There are two common cases where this will not work:     1. The JLL is part of the [Julia stdlib](https://github.com/JuliaLang/julia/tree/master/stdlib),        for example `Zlib_jll`     2. The JLL has not been compiled with [JLLWrappers.jl](https://github.com/JuliaPackaging/JLLWrappers.jl)        as a dependency. In this case, it means that the last build of the JLL        pre-dates the introduction of the JLLWrappers package and needs a fresh        build. Please open an issue on [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil/)        requesting a new build, or make a pull request to update the relevant        `build_tarballs.jl` script.

在两种常见情况下这将不起作用：1. JLL 是 [Julia stdlib](https://github.com/JuliaLang/julia/tree/master/stdlib) 的一部分，例如 `Zlib_jll` 2. JLL 尚未使用 [JLLWrappers.jl](https://github.com/JuliaPackaging/JLLWrappers.jl) 作为依赖项进行编译。在这种情况下，这意味着 JLL 的最后一次构建早于 JLLWrappers 包的引入，需要重新构建。请在 [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil/) 上提出问题请求新构建，或提出拉取请求以更新相关的 `build_tarballs.jl` 脚本。

