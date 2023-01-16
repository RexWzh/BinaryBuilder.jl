
# 构建包

`BinaryBuilder.jl` 构建脚本（通常为 `build_tarballs.jl` 文件），示例如下：

```julia
using BinaryBuilder

name = "libfoo"
version = v"1.0.1"
sources = [
    ArchiveSource("<url to source tarball>", "sha256 hash"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libfoo-*
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libfoo", :libfoo),
    ExecutableProduct("fooifier", :fooifier),
]

dependencies = [
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
```

[`build_tarballs`](@ref) 函数接受上面定义的变量并运行构建，将输出压缩包放入 `./products` 目录，并可选择生成和发布 [JLL 包](./jll.md )。让我们更详细地了解构建器的成分是什么。

## 名称

这是将在压缩包和 JLL 包中使用的名称。它应该是**上游包的名称**，而不是它提供的特定库或可执行文件的名称，即使它们可能重合。名称的大小写应与上游包的大小写匹配。请注意，该名称应该是一个有效的 Julia 标识符，因此它满足了一些要求，包括：

* 不能以数字开头，

* 名称中不能包含空格、破折号或点，但可以使用下划线来代替

如果您不确定，可以使用 `Base.isidentifer` 来检查名称是否可以接受：

```julia
julia> Base.isidentifier("valid_package_name")
true

julia> Base.isidentifier("100-invalid package.name")
false
```

请注意，`_jll` 后缀会自动附加到生成的 JLL 包的名称中。

## 版本号

这是压缩包中使用的版本号，应该与上游包的版本一致。但是，请注意，这应该只包含主要、次要和补丁号，因此

```julia
julia> v"1.2.3"
v"1.2.3"
```

是可以接受的，但是

```julia
julia> v"1.2.3-alpha"
v"1.2.3-alpha"

julia> v"1.2.3+3"
v"1.2.3+3"
```

或包含三个以上级别的版本（例如，`1.2.3.4`）则不是。如有必要，将版本截断为补丁号。

生成的 JLL 包将自动添加一个内部版本号，每次重新构建相同的包版本时都会增加它。

## 来源

源是将用于构建脚本编译的内容，它们将被放置在构建环境中的 `${WORKSPACE}/srcdir` 下。源可以是以下类型：

* [`ArchiveSource`](@ref)：压缩文件（例如，`tar.gz`，`tar.bz2`，`tar.xz`， `zip`) ，将被下载并自动解压；

* [`GitSource`](@ref): 需要克隆的 git 存储库，将自从 `check out` 到制定的修订版。

* [`FileSource`](@ref): 将从互联网下载的通用文件，无需特殊处理。

* [`DirectorySource`](@ref): 一个本地目录，其内容将被复制到 `${WORKSPACE}/srcdir`。这通常包含本地补丁，用于以非交互方式编辑待构建包的源代码中的文件。

具有多个不同类型来源的包示例：

* [`libftd2xx`](https://github.com/JuliaPackaging/Yggdrasil/blob/62d44097a26fe338763da8263b36ce6a63e7fa9c/L/libftd2xx/build_tarballs.jl#L9-L29)。

不要将源代码与 [二进制依赖项](#Binary-dependencies-1) 混淆。

!!! 注释

    每个构建器都应该构建一个包：不要使用多个源将多个包捆绑到一个配方中。相反，单独构建每个包，并根据需要将它们用作二进制依赖项。这将增加包的可重用性。

## 构建脚本

该脚本是在构建环境中执行的 bash 脚本，构建环境使用 Musl C 库的 `x86_64` Linux 环境，基于 Alpine Linux（三元组：`x86_64-linux-musl`）。 [构建提示](./build_tips.md) 部分提供了有关在构建脚本中执行操作的更多详细信息。

## 平台

构建器还应指定要为其构建包的平台列表。在撰写本文时，我们支持 Linux（`x86_64`、`i686`、`armv6l`、`armv7l`、`aarch64`、`ppc64le`）、Windows（`x86_64`、`i686`）、macOS（`x86_64 `、`aarch64`) 和 FreeBSD (`x86_64`)。如果可能，我们会尝试为所有支持的平台构建，在这种情况下你可以设置

```julia
platforms = supported_platforms()
```

你可以使用函数 `supported_platforms` 和 `triplet` 获取受支持平台的列表及其关联的 `triplets`：

```@repl
using BinaryBuilder
supported_platforms()
triplet.(supported_platforms())
```

平台的三元组将用于生成压缩包的名称。

对于某些包，（交叉）编译可能无法用于所有这些平台，或者您有兴趣仅为其中的一个子集构建包。仅为某些平台构建的包的示例为


* [`libevent`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/L/libevent/build_tarballs.jl#L24-L36);

* [`Xorg_libX11`]（https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/X/Xorg_libX11/build_tarballs.jl#L29）：

  这个构建仅针对 Linux 和 FreeBSD 系统，自动从 `supported_platforms` 中筛出，而不明确列出平台。


### 扩展 C++ 字符串 ABI 或 libgfortran 版本


构建库不是一项微不足道的任务，它会带来很多兼容性问题，其中一些问题在 [Tricksy Gotchas](./tricksy_gotchas.md) 中有详细说明。

特别注意这两个不兼容性问题：

* GCC 附带的标准 C++ 库对于 `std::string` 可以用 [两个不兼容的 ABIs](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html) 之一，一个旧的通常被称为 C++03 字符串 ABI，一个新的则符合 2011 C++ 标准。

!!! 注释
    此 ABI *不* 与源代码使用的 C++ 标准有关，事实上，你可以使用 C++11 `std::string` ABI 和 C++03 `std::string` ABI 的 C++11 库来构建 C++03 库。这是通过适当设置 `_GLIBCXX_USE_CXX11_ABI` 宏来实现的。

  这意味着当使用 GCC 构建 C++ 库或公开 `std::string` ABI 的程序时，您必须确保用户将运行与他们的 `std::string` ABI 匹配的二进制文件。您可以在平台的 `compiler_abi` 部分手动指定 `std::string` ABI，但 `BinaryBuilder` 允许您自动扩展平台列表以包含 C++03 `std::string` 的条目 ABI 和另一个用于 C++11 `std::string` ABI 的 ABI，使用 [`expand_cxxstring_abis`](@ref) 函数：

```jldoctest
julia> using BinaryBuilder

julia> platforms = [Platform("x86_64", "linux")]
1-element Vector{Platform}:
  Linux x86_64 {libc=glibc}

julia> expand_cxxstring_abis(platforms)
2-element Vector{Platform}:
  Linux x86_64 {cxxstring_abi=cxx03, libc=glibc}
  Linux x86_64 {cxxstring_abi=cxx11, libc=glibc}
```

  处理 C++ `std::string` ABI 的包示例是：

  * [`GEOS`](https://github.com/JuliaPackaging/Yggdrasil/blob/1ba8f726810ba5315f686ef0137469a9bf6cca2c/G/GEOS/build_tarballs.jl#L33)：为所有支持的平台扩展 C++ `std::string` ABI； 

  * [`Bloaty`](https://github.com/JuliaPackaging/Yggdrasil/blob/14ee948c38385fc4dfd7b6167885fa4005b5da35/B/Bloaty/build_tarballs.jl#L37)：仅为某些平台构建包并扩展 C++ `std::string ` ABI；

  * [`libcgal_julia`](https://github.com/JuliaPackaging/Yggdrasil/blob/b73815bb1e3894c9ed18801fc7d62ad98fd9f8ba/L/libcgal_julia/build_tarballs.jl#L52-L57)：仅针对带有 C++11 `std::string 的平台构建` ABI。


* GCC 自带的 `libgfortran` 改变了 ABI 6.X -> 7.X 和 7.X -> 8.X 转换中的向后不兼容方式。这意味着当您构建将链接到 `libgfortran` 的包时，您必须确保用户将使用链接到与他们自己兼容的 `libgfortran` 版本的包。同样在这种情况下，您可以在平台的 `compiler_abi` 部分手动指定 `libgfortran` 版本，或者使用函数 [`expand_gfortran_versions`](@ref) 自动扩展平台列表以包括所有可能的 ` libgfortran` 版本：

```jldoctest
julia> using BinaryBuilder

julia> platforms = [Platform("x86_64", "linux")]
1-element Vector{Platform}:
  Linux x86_64 {libc=glibc}

julia> expand_gfortran_versions(platforms)
3-element Vector{Platform}:
  Linux x86_64 {libc=glibc, libgfortran_version=3.0.0}
  Linux x86_64 {libc=glibc, libgfortran_version=4.0.0}
  Linux x86_64 {libc=glibc, libgfortran_version=5.0.0}
```

  扩展 `libgfortran` 版本的包示例是：

 * [`OpenSpecFun`](https://github.com/JuliaPackaging/Yggdrasil/blob/4f20fd7c58f6ad58911345adec74deaa8aed1f65/O/OpenSpecFun/build_tarballs.jl#L34)：为所有支持的平台扩展了 `libgfortran` 版本；
 * [`LibAMVW`](https://github.com/JuliaPackaging/Yggdrasil/blob/dbc6aa9dded5ae2fe967f262473f77f7e75f6973/L/LibAMVW/build_tarballs.jl#L65-L73)：仅为某些平台构建包并扩展 `libgfortran` 版本.

请注意，您是否需要为不同的 C++ 字符串 ABI 或 libgfortran 版本构建完全取决于当前构建的产品是通过公开 `std::string` ABI 还是直接链接到 `libgfortran`。事实上，某些依赖项需要扩展 C++ 字符串 ABI 或 libgfortran 版本，这与当前构建配方无关，BinaryBuilder 将负责安装具有匹配 ABI 的库。

如果您不知道是否需要扩展 C++ `std::string` ABI 或 libgfortran 版本的平台列表，请不要担心：如果不彻底阅读源代码或实际构建包。在任何情况下，审计都会通知您是否必须使用这些 `expand-*` 函数。

### 独立于平台的包

`BinaryBuilder.jl` 对于构建涉及共享库和二进制可执行文件的包特别有用。使用此包构建独立于平台的包几乎没有什么好处，例如，在用户计算机上安装要在 Julia 包中使用的数据集。为此目的，使用 [`create_artifact`](https ://julialang.github.io/Pkg.jl/v1/artifacts/#Using-Artifacts-1) 会做完全相同的工作。尽管如此，在某些情况下，独立于平台的 JLL 包仍然有用，例如构建一个仅包含头文件的包，这些头文件将用作其他包的依赖项。要构建独立于平台的包，您可以使用特殊平台 [`AnyPlatform`](@ref)：

```julia
platforms = [AnyPlatform()]
```

在构建环境中，`AnyPlatform` 看起来像 `x86_64-linux-musl`，但这不会以任何方式影响您的构建。请注意，在为 `AnyPlatform` 构建包时，您只能拥有 `FileProduct` 类型的产品，因为所有其他类型都依赖于平台。为 `AnyPlatform` 生成的 JLL 包是 [平台无关的](https://julialang.github.io/Pkg.jl/v1/artifacts/#Artifact-types-and-properties-1) 因此可以安装在任何机器上。


使用 `AnyPlatform` 的构建器示例：


* [`OpenCL_Headers`](https://github.com/JuliaPackaging/Yggdrasil/blob/1e069da9a4f9649b5f42547ced7273c27bd2db30/O/OpenCL_Headers/build_tarballs.jl)

* [`SPIRV_Headers`](https://github.com/JuliaPackaging/Yggdrasil/blob/1e069da9a4f9649b5f42547ced7273c27bd2db30/S/SPIRV_Headers/build_tarballs.jl).

## 产品


产品是预期出现在生成的压缩包中的文件。如果在压缩包中找不到产品，构建将失败。产品可以是以下类型：

* [`LibraryProduct`](@ref): 这代表一个共享库；

* [`ExecutableProduct`](@ref)：这代表一个二进制可执行程序。

  注意：这不能用于解释性脚本；

* [`FrameworkProduct`](@ref)（仅在为 `MacOS` 构建时）：这代表一个 [macOS 框架](https://en.wikipedia.org/wiki/Bundle_(macOS)#macOS_framework_bundles)；

* [`FileProduct`](@ref)：任何类型的文件，没有特殊处理。

审核将对构建器的产品执行一系列健全性检查，除了 `FileProduct`，同时尝试自动修复一些常见问题。

您不需要将最终会出现在压缩包中的 _所有_ 文件列为产品，而只需列出你想要确保存并且希望审计对其执行检查的文件。这通常包括共享库和二进制可执行文件。如果您还生成 JLL 包，则产品将具有一些变量，以便于引用它们。有关此的更多信息，请参阅 [JLL packages](./jll.md) 的文档。

不同类型产品的包列表：

* [`Fontconfig`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/F/Fontconfig/build_tarballs.jl#L57-L69)。

## 二进制依赖

构建脚本可以依赖于另一个构建器生成的二进制文件。构建器以先前构建的 JLL 包的形式指定 `dependencies`：

```julia
# Dependencies of Xorg_xkbcomp
dependencies = [
    Dependency("Xorg_libxkbfile_jll"),
    BuildDependency("Xorg_util_macros_jll"),
]
```

* [`Dependency`](@ref) 指定构建和加载所需的 JLL 包并导入到当前的构建器。目标平台的二进制文件将被安装；

* [`RuntimeDependency`](@ref)：仅在运行时需要的 JLL 包。在构建阶段，它的工件将不会被安装。

* [`BuildDependency`](@ref) 仅用于构建当前包的 JLL 包，但不加载它。该依赖项将为目标平台安装二进制文件，不会添加到生成的 JLL 包的依赖项列表中；

* [`HostBuildDependency`](@ref): 类似于 `BuildDependency`，但它将为主机系统安装二进制文件。通常添加这种依赖性以提供一些二进制实用程序以在构建过程中运行。

`Dependency`、`RuntimeDependency`、`BuildDependency` 和 `HostBuildDependency` 的参数也可以是 `Pkg.PackageSpec` 类型，你可以用它指定更多关于依赖的细节，比如版本号，或者非注册包。请注意，在 Yggdrasil 中，只能接受 [General registry](https://github.com/JuliaRegistries/General) 中的 JLL 包。

目标系统的依赖项（`Dependency` 和 `BuildDependency` ）将安装在构建环境中的 `${prefix}` 下，而主机系统的依赖项（`HostBuildDependency`）将安装在 `${host_prefix}` 下。


在向导中，可以通过提示指定依赖项：*Do you require any (binary) dependencies? [y/N]*。

依赖于其他二进制文件的构建器示例包括：

* [`Xorg_libX11`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/X/Xorg_libX11/build_tarballs.jl#L36-L42) 在构建和运行时依赖于 `Xorg_libxcb_jll` 和 `Xorg_xtrans_jll`，仅在构建时依赖于 `Xorg_xorgproto_jll` 和 `Xorg_util_macros_jll`。

### 特定于平台的依赖项

默认情况下，所有依赖项都用于所有平台，但在某些情况下，包仅在某些平台上需要某些依赖项。您可以通过将 `platforms` 关键字参数传递给依赖构造器来指定需要依赖的平台，这是一个 `AbstractPlatforms` 类型的向量，指定应使用的依赖项。

例如，假设变量 `platforms` 包含要为其构建包的平台的向量，您可以指定 `Package_jl` 在除 Windows 之外的所有平台上都是必需的

```julia
Dependency("Package_jll"; platforms=filter(!Sys.iswindows, platforms))
```

这些平台依赖信息也被传输到 JLL 包：包装器仅在需要时加载依赖于该平台的 JLL 依赖项。

!!! 警告
   Julia 的包管理器没有可选依赖项或平台相关依赖项的概念：这意味着当在您的环境中安装 JLL 包时，在任何情况下，它的所有依赖项都将被安装。只有在运行必要时才会加载特定于平台的依赖项。

   出于同样的原因，即使您指定平台不需要的依赖项，如果它也是其他一些依赖项所需的间接依赖项，构建配方仍可能会引入它。目前，`BinaryBuilder.jl` 在安装依赖项的工件时无法传播依赖项依赖于平台的信息。

例子：

* [`ADIOS2`](https://github.com/JuliaPackaging/Yggdrasil/blob/0528e0f31b55355df632c79a2784621583443d9c/A/ADIOS2/build_tarballs.jl#L122-L123) 使用 `MPICH_jll` 在除 Windows 之外的所有平台上提供 MPI 实现，并为 Windows 使用 `MicrosoftMPI_jll`。

* [`GTK3`](https://github.com/JuliaPackaging/Yggdrasil/blob/0528e0f31b55355df632c79a2784621583443d9c/G/GTK3/build_tarballs.jl#L70-L104) 仅在 Linux 和 FreeBSD 平台上使用 X11 软件栈，仅在 Linux 上使用 Wayland。

* [`NativeFileDialog`](https://github.com/JuliaPackaging/Yggdrasil/blob/0528e0f31b55355df632c79a2784621583443d9c/N/NativeFileDialog/build_tarballs.jl#L40-L44) 仅在 Linux 和 FreeBSD 上使用 GTK3，在所有其他平台上它使用系统库，因此在这些情况下不需要其他包。

### 依赖的版本号

有两种不同的方式来指定依赖的版本，具有两种不同的含义：

* `Dependency("Foo_jll", v"1.2.3")`: `Dependency` 的第二个参数指定用于构建包的版本：此版本*未*反映在生成的 JLL 包项目中的版本兼容性边界。在这种情况下会很有用：当您要构建的包与从给定版本开始的所有依赖项版本兼容（而且您不想限制 JLL 包的兼容性范围），但为了最大化你对旧版本的兼容性能力。

* `Dependency(PackageSpec(; name="Foo_jll", version=v"1.2.3"))`: 如果包作为 `Pkg.PackageSpec` 给出并且给出了 `version` 关键字参数，这个版本的包用于构建*而且*生成的 JLL 包将与提供的包版本兼容。当您的包仅与单一版本的依赖项兼容时，且希望在 JLL 包的项目中反映这种情况，应使用此选项。

# 在本地构建和测试 JLL 包

作为包开发人员，您可能希望在本地测试 JLL 包，或者作为二进制依赖项开发人员，您可能希望轻松使用自定义二进制文件。通过结合 `dev` 中的 JLL 包和创建一个 `overrides` 目录，可以轻松完全控制本地 JLL 包状态。

## 覆盖预构建 JLL 包的二进制文件

运行 `pkg> dev LibFoo_jll` 后，本地 JLL 包将被 `check out` 到您 “开发中” 的目录（大多数情况的路径为 `~/.julia/dev`），默认情况下，JLL 包将你的开发中的 `artifacts` 目录的二进制文件。如果 JLL 包目录中存在目录 `override`，则 JLL 包将在该 `override` 目录中查找二进制文件，而不是在任何 `artifact` 目录中。请注意，在单个 JLL 包中二进制文件不存在混合和匹配；如果存在 `override` 目录，则该 JLL 包中定义的所有产品都必须在 `override` 目录中找到，而不能来自 `artifact`。依赖项（例如，在另一个 JLL 包中的）可能仍会从它们各自的工件中加载，因此 JLL 依赖项本身必须是 “开发过” 的，并且具有创建了文件或符号链接的 `override` 目录。

### 自动填充 `override` 目录

为了简化 `override` 目录的创建，JLL 包包含一个 `dev_jll()` 函数，这将确保 `~/.julia/dev/<jll name>` 包被 `dev` 输出，并把正常的工件内容复制到适当的 `override` 目录中。这对于简单地使用工件目录没有功能上的区别，但提供了一个可以由自定义构建的二进制文件替换的文件模板。

请注意，此功能将在重建时推广到新的 JLL 包；如果 JLL 包没有 `dev_jll()` 函数，[在 Yggdrasil 上打开一个问题](https://github.com/JuliaPackaging/Yggdrasil/issues/new) 将生成一个新的 JLL 版本以提供功能。

## 在本地构建自定义 JLL 包

在构建新版本的 JLL 包时，如果将 `--deploy` 传递给 `build_tarballs.jl`，则新构建的 JLL 包将部署到 GitHub 存储库。 （阅读 [命令行](@ref) 部分中的文档或通过将 `--help` 传递给 `build_tarballs.jl` 脚本来获取有关 `--deploy` 选项的更多信息）。如果传递 `--deploy=local` ，JLL 包仍将构建在 `~/.julia/dev/` 目录中，但不会上传到任何地方。这对于本地测试和验证构建的工件是否与您的包一起工作很有用。

