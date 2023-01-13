
# Building Packages
# 构建包


A `BinaryBuilder.jl` build script (what is often referred to as a `build_tarballs.jl` file) looks something like this:

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


The [`build_tarballs`](@ref) function takes in the variables defined above and runs the builds, placing output tarballs into the `./products` directory, and optionally generating and publishing the [JLL package](./jll.md).  Let's see in more details what are the ingredients of the builder.

[`build_tarballs`](@ref) 函数接受上面定义的变量并运行构建，将输出压缩包放入 `./products` 目录，并可选择生成和发布 [JLL 包](./jll.md )。让我们更详细地了解构建器的成分是什么。


## Name
## 名称

This is the name that will be used in the tarballs and for the JLL package.  It should be the name of the upstream package, not for example that of a specific library or executable provided by it, even though they may coincide.  The case of the name should match that of the upstream package.  Note that the name should be a valid Julia identifier, so it has meet some requirements, among which:

这是将在压缩包和 JLL 包中使用的名称。它应该是**上游包的名称**，而不是它提供的特定库或可执行文件的名称，即使它们可能重合。名称的大小写应与上游包的大小写匹配。请注意，该名称应该是一个有效的 Julia 标识符，因此它满足了一些要求，包括：


* it cannot start with a number,

* 不能以数字开头，


* it cannot have spaces, dashes, or dots in the name.  You can use underscores to replace them.

* 名称中不能包含空格、破折号或点，但可以使用下划线来代替

If you are unsure, you can use `Base.isidentifer` to check whehter the name is acceptable:

如果您不确定，可以使用 `Base.isidentifer` 来检查名称是否可以接受：

```julia
julia> Base.isidentifier("valid_package_name")
true

julia> Base.isidentifier("100-invalid package.name")
false
```


Note that `_jll` will be automatically appended to the name of the generated JLL package.

请注意，`_jll` 后缀会自动附加到生成的 JLL 包的名称中。


## Version number
## 版本号


This is the version number used in tarballs and should coincide with the version of the upstream package.  However, note that this should only contain major, minor and patch numbers, so

这是压缩包中使用的版本号，应该与上游包的版本一致。但是，请注意，这应该只包含主要、次要和补丁号，因此

```julia
julia> v"1.2.3"
v"1.2.3"
```


is acceptable, but

是可以接受的，但是

```julia
julia> v"1.2.3-alpha"
v"1.2.3-alpha"

julia> v"1.2.3+3"
v"1.2.3+3"
```


or a version including more than three levels (e.g., `1.2.3.4`) are not. Truncate the version to the patch number if necessary.

或包含三个以上级别的版本（例如，`1.2.3.4`）则不是。如有必要，将版本截断为补丁号。


The generated JLL package will automatically add a build number, increasing it for each rebuild of the same package version.

生成的 JLL 包将自动添加一个内部版本号，每次重新构建相同的包版本时都会增加它。


## Sources
## 来源


The sources are what will be compiled with the build script.  They will be placed under `${WORKSPACE}/srcdir` inside the build environment.  Sources can be of the following types:

源是将用于构建脚本编译的内容，它们将被放置在构建环境中的 `${WORKSPACE}/srcdir` 下。源可以是以下类型：


* [`ArchiveSource`](@ref): a compressed archive (e.g., `tar.gz`, `tar.bz2`, `tar.xz`, `zip`) that will be downloaded and automatically uncompressed;

* [`ArchiveSource`](@ref)：压缩文件（例如，`tar.gz`，`tar.bz2`，`tar.xz`， `zip`) ，将被下载并自动解压；


* [`GitSource`](@ref): a git repository that will be automatically cloned.  The specified revision will be checked out;

* [`GitSource`](@ref): 需要克隆的 git 存储库，将自从 `check out` 到制定的修订版。

* [`FileSource`](@ref): a generic file that will be downloaded from the Internet, without special treatment;

* [`FileSource`](@ref): 将从互联网下载的通用文件，无需特殊处理。

* [`DirectorySource`](@ref): a local directory whose content will be copied in `${WORKSPACE}/srcdir`.  This usually contains local patches used to non-interactively edit files in the source code of the package you want to build.

* [`DirectorySource`](@ref): 一个本地目录，其内容将被复制到 `${WORKSPACE}/srcdir`。这通常包含本地补丁，用于以非交互方式编辑待构建包的源代码中的文件。


Example of packages with multiple sources of different types:

具有多个不同类型来源的包示例：


* [`libftd2xx`](https://github.com/JuliaPackaging/Yggdrasil/blob/62d44097a26fe338763da8263b36ce6a63e7fa9c/L/libftd2xx/build_tarballs.jl#L9-L29).

* [`libftd2xx`](https://github.com/JuliaPackaging/Yggdrasil/blob/62d44097a26fe338763da8263b36ce6a63e7fa9c/L/libftd2xx/build_tarballs.jl#L9-L29)。


Sources are not to be confused with the [binary dependencies](#Binary-dependencies-1).

不要将源代码与 [二进制依赖项](#Binary-dependencies-1) 混淆。


!!! note


    Each builder should build a single package: don't use multiple sources to     bundle multiple packages into a single recipe.  Instead, build each package  separately, and use them as binary dependencies as appropriate.  This will increase reusability of packages.

!!! 注释

    每个构建器都应该构建一个包：不要使用多个源将多个包捆绑到一个配方中。相反，单独构建每个包，并根据需要将它们用作二进制依赖项。这将增加包的可重用性。


## Build script
## 构建脚本


The script is a bash script executed within the build environment, which is a `x86_64` Linux environment using the Musl C library, based on Alpine Linux (triplet: `x86_64-linux-musl`).  The section [Build Tips](./build_tips.md) provides more details about what you can usually do inside the build script.

该脚本是在构建环境中执行的 bash 脚本，构建环境使用 Musl C 库的 `x86_64` Linux 环境，基于 Alpine Linux（三元组：`x86_64-linux-musl`）。 [构建提示](./build_tips.md) 部分提供了有关在构建脚本中执行操作的更多详细信息。


## Platforms
## 平台


The builder should also specify the list of platforms for which you want to build the package.  At the time of writing, we support Linux (`x86_64`, `i686`, `armv6l`, `armv7l`, `aarch64`, `ppc64le`), Windows (`x86_64`, `i686`), macOS (`x86_64`, `aarch64`) and FreeBSD (`x86_64`).  When possible, we try to build for all supported platforms, in which case you can set

构建器还应指定要为其构建包的平台列表。在撰写本文时，我们支持 Linux（`x86_64`、`i686`、`armv6l`、`armv7l`、`aarch64`、`ppc64le`）、Windows（`x86_64`、`i686`）、macOS（`x86_64 `、`aarch64`) 和 FreeBSD (`x86_64`)。如果可能，我们会尝试为所有支持的平台构建，在这种情况下你可以设置

```julia
platforms = supported_platforms()
```


You can get the list of the supported platforms and their associated _triplets_ by using the functions `supported_platforms` and `triplet`:

你可以使用函数 `supported_platforms` 和 `triplet` 获取受支持平台的列表及其关联的 `triplets`：

```@repl
using BinaryBuilder
supported_platforms()
triplet.(supported_platforms())
```


The triplet of the platform is used in the name of the tarball generated.

平台的三元组将用于生成压缩包的名称。


For some packages, (cross-)compilation may not be possible for all those platforms, or you have interested in building the package only for a subset of them.  Examples of packages built only for some platforms are

对于某些包，（交叉）编译可能无法用于所有这些平台，或者您有兴趣仅为其中的一个子集构建包。仅为某些平台构建的包的示例为


* [`libevent`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/L/libevent/build_tarballs.jl#L24-L36);

[`libevent`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/L/libevent/build_tarballs.jl#L24-L36);


* [`Xorg_libX11`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/X/Xorg_libX11/build_tarballs.jl#L29):

* [`Xorg_libX11`]（https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/X/Xorg_libX11/build_tarballs.jl#L29）：

  this is built only for Linux and FreeBSD systems, automatically filtered from   `supported_platforms`, instead of listing the platforms explicitly.

  这个构建仅针对 Linux 和 FreeBSD 系统，自动从 `supported_platforms` 中筛出，而不明确列出平台。


### Expanding C++ string ABIs or libgfortran versions
### 扩展 C++ 字符串 ABI 或 libgfortran 版本


Building libraries is not a trivial task and entails a lot of compatibility issues, some of which are detailed in [Tricksy Gotchas](./tricksy_gotchas.md).

构建库不是一项微不足道的任务，它会带来很多兼容性问题，其中一些问题在 [Tricksy Gotchas](./tricksy_gotchas.md) 中有详细说明。


You should be aware of two incompatibilities in particular:

特别注意这两个不兼容性问题：


* The standard C++ library that comes with GCC can have one of [two incompatible ABIs](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html) for `std::string`, an old one usually referred to as C++03 string ABI, and a newer one conforming to the 2011 C++ standard.

* GCC 附带的标准 C++ 库对于 `std::string` 可以用 [两个不兼容的 ABIs](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html) 之一，一个旧的通常被称为 C++03 字符串 ABI，一个新的则符合 2011 C++ 标准。


!!! note

      This ABI does *not* have to do with the C++ standard used by the source code, in fact you can build a C++03 library with the C++11 `std::string`  ABI and a C++11 library with the C++03 `std::string` ABI.  This is  achieved by appropriately setting the `_GLIBCXX_USE_CXX11_ABI` macro.

!!! 注释
    此 ABI *不* 与源代码使用的 C++ 标准有关，事实上，你可以使用 C++11 `std::string` ABI 和 C++03 `std::string` ABI 的 C++11 库来构建 C++03 库。这是通过适当设置 `_GLIBCXX_USE_CXX11_ABI` 宏来实现的。


  This means that when building with GCC a C++ library or program which exposes   the `std::string` ABI, you must make sure that the user whill run a binary   matching their `std::string` ABI.  You can manually specify the `std::string`   ABI in the `compiler_abi` part of the platform, but `BinaryBuilder` lets you   automatically expand the list of platform to include an entry for the C++03   `std::string` ABI and another one for the C++11 `std::string` ABI, by using   the [`expand_cxxstring_abis`](@ref) function:

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


  Example of packages dealing with the C++ `std::string` ABIs are:

  处理 C++ `std::string` ABI 的包示例是：


  * [`GEOS`](https://github.com/JuliaPackaging/Yggdrasil/blob/1ba8f726810ba5315f686ef0137469a9bf6cca2c/G/GEOS/build_tarballs.jl#L33):     expands the the C++ `std::string` ABIs for all supported platforms;

  * [`Bloaty`](https://github.com/JuliaPackaging/Yggdrasil/blob/14ee948c38385fc4dfd7b6167885fa4005b5da35/B/Bloaty/build_tarballs.jl#L37):     builds the package only for some platforms and expands the C++ `std::string` ABIs;

  * [`libcgal_julia`](https://github.com/JuliaPackaging/Yggdrasil/blob/b73815bb1e3894c9ed18801fc7d62ad98fd9f8ba/L/libcgal_julia/build_tarballs.jl#L52-L57):     builds only for platforms with C++11 `std::string` ABI.

  * [`GEOS`](https://github.com/JuliaPackaging/Yggdrasil/blob/1ba8f726810ba5315f686ef0137469a9bf6cca2c/G/GEOS/build_tarballs.jl#L33)：为所有支持的平台扩展 C++ `std::string` ABI； 
  * [`Bloaty`](https://github.com/JuliaPackaging/Yggdrasil/blob/14ee948c38385fc4dfd7b6167885fa4005b5da35/B/Bloaty/build_tarballs.jl#L37)：仅为某些平台构建包并扩展 C++ `std::string ` ABI；
  * [`libcgal_julia`](https://github.com/JuliaPackaging/Yggdrasil/blob/b73815bb1e3894c9ed18801fc7d62ad98fd9f8ba/L/libcgal_julia/build_tarballs.jl#L52-L57)：仅针对带有 C++11 `std::string 的平台构建` ABI。


* The `libgfortran` that comes with GCC changed the ABI in a

* GCC 自带的 `libgfortran` 改变了 ABI

  backward-incompatible way in the 6.X -> 7.X and the 7.X -> 8.X transitions.   This means that when you build a package that will link to `libgfortran`, you   must be sure that the user will use a package linking to a `libgfortran`   version compatible with their own.  Also in this case you can either manually   specify the `libgfortran` version in the `compiler_abi` part fo the platform   or use a function, [`expand_gfortran_versions`](@ref), to automatically expand   the list of platform to include all possible `libgfortran` versions:

   6.X -> 7.X 和 7.X -> 8.X 转换中的向后不兼容方式。这意味着当您构建将链接到 `libgfortran` 的包时，您必须确保用户将使用链接到与他们自己兼容的 `libgfortran` 版本的包。同样在这种情况下，您可以在平台的 `compiler_abi` 部分手动指定 `libgfortran` 版本，或者使用函数 [`expand_gfortran_versions`](@ref) 自动扩展平台列表以包括所有可能的 ` libgfortran` 版本：

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


  Example of packages expanding the `libgfortran` versions are:

  扩展 `libgfortran` 版本的包示例是：


  * [`OpenSpecFun`](https://github.com/JuliaPackaging/Yggdrasil/blob/4f20fd7c58f6ad58911345adec74deaa8aed1f65/O/OpenSpecFun/build_tarballs.jl#L34): expands the `libgfortran` versions for all supported platforms; 
  * [`LibAMVW`](https://github.com/JuliaPackaging/Yggdrasil/blob/dbc6aa9dded5ae2fe967f262473f77f7e75f6973/L/LibAMVW/build_tarballs.jl#L65-L73): builds the package only for some platforms and expands the `libgfortran` versions.

 * [`OpenSpecFun`](https://github.com/JuliaPackaging/Yggdrasil/blob/4f20fd7c58f6ad58911345adec74deaa8aed1f65/O/OpenSpecFun/build_tarballs.jl#L34)：为所有支持的平台扩展了 `libgfortran` 版本；
 * [`LibAMVW`](https://github.com/JuliaPackaging/Yggdrasil/blob/dbc6aa9dded5ae2fe967f262473f77f7e75f6973/L/LibAMVW/build_tarballs.jl#L65-L73)：仅为某些平台构建包并扩展 `libgfortran` 版本.


Note that whether you need to build for different C++ string ABIs or libgfortran versions depends exclusively on whether the products of the current build expose the `std::string` ABI or directly link to `libgfortran`.  The fact that some of the dependencies need to expand the C++ string ABIs or libgfortran versions is not relevant for the current build recipe and BinaryBuilder will take care of installing libraries with matching ABI.

请注意，您是否需要为不同的 C++ 字符串 ABI 或 libgfortran 版本构建完全取决于当前构建的产品是通过公开 `std::string` ABI 还是直接链接到 `libgfortran`。事实上，某些依赖项需要扩展 C++ 字符串 ABI 或 libgfortran 版本，这与当前构建配方无关，BinaryBuilder 将负责安装具有匹配 ABI 的库。


Don't worry if you don't know whether you need to expand the list of platforms for the C++ `std::string` ABIs or the libgfortran versions: this is often not possible to know in advance without thoroughly reading the source code or actually building the package.  In any case the audit will inform you if you have to use these `expand-*` functions.

如果您不知道是否需要扩展 C++ `std::string` ABI 或 libgfortran 版本的平台列表，请不要担心：如果不彻底阅读源代码或实际构建包。在任何情况下，审计都会通知您是否必须使用这些 `expand-*` 函数。


### Platform-independent packages
### 独立于平台的包


`BinaryBuilder.jl` is particularly useful to build packages involving shared libraries and binary executables.  There is little benefit in using this package to build a package that would be platform-independent, for example to install a dataset to be used in a Julia package on the user's machine.  For this purpose a simple [`Artifacts.toml`](https://julialang.github.io/Pkg.jl/v1/artifacts/#Artifacts.toml-files-1) file generated with [`create_artifact`](https://julialang.github.io/Pkg.jl/v1/artifacts/#Using-Artifacts-1) would do exactly the same job.  Nevertheless, there are cases where a platform-independent JLL package would still be useful, for example to build a package containing only header files that will be used as dependency of other packages.  To build a platform-independent package you can use the special platform [`AnyPlatform`](@ref):

`BinaryBuilder.jl` 对于构建涉及共享库和二进制可执行文件的包特别有用。使用此包构建独立于平台的包几乎没有什么好处，例如，在用户计算机上安装要在 Julia 包中使用的数据集。为此目的，使用 [`create_artifact`](https ://julialang.github.io/Pkg.jl/v1/artifacts/#Using-Artifacts-1) 会做完全相同的工作。尽管如此，在某些情况下，独立于平台的 JLL 包仍然有用，例如构建一个仅包含头文件的包，这些头文件将用作其他包的依赖项。要构建独立于平台的包，您可以使用特殊平台 [`AnyPlatform`](@ref)：

```julia
platforms = [AnyPlatform()]
```


Within the build environment, an `AnyPlatform` looks like `x86_64-linux-musl`, but this shouldn't affect your build in any way.  Note that when building a package for `AnyPlatform` you can only have products of type `FileProduct`, as all other types are platform-dependent.  The JLL package generated for an `AnyPlatform` is [platform-independent](https://julialang.github.io/Pkg.jl/v1/artifacts/#Artifact-types-and-properties-1) and can thus be installed on any machine.

在构建环境中，`AnyPlatform` 看起来像 `x86_64-linux-musl`，但这不会以任何方式影响您的构建。请注意，在为 `AnyPlatform` 构建包时，您只能拥有 `FileProduct` 类型的产品，因为所有其他类型都依赖于平台。为 `AnyPlatform` 生成的 JLL 包是 [平台无关的](https://julialang.github.io/Pkg.jl/v1/artifacts/#Artifact-types-and-properties-1) 因此可以安装在任何机器上。


Example of builders using `AnyPlatform`:

使用 `AnyPlatform` 的构建器示例：


* [`OpenCL_Headers`](https://github.com/JuliaPackaging/Yggdrasil/blob/1e069da9a4f9649b5f42547ced7273c27bd2db30/O/OpenCL_Headers/build_tarballs.jl)

* [`SPIRV_Headers`](https://github.com/JuliaPackaging/Yggdrasil/blob/1e069da9a4f9649b5f42547ced7273c27bd2db30/S/SPIRV_Headers/build_tarballs.jl).


## Products
## 产品


The products are the files expected to be present in the generated tarballs.  If a product is not found in the tarball, the build will fail.  Products can be of the following types:

产品是预期出现在生成的压缩包中的文件。如果在压缩包中找不到产品，构建将失败。产品可以是以下类型：


* [`LibraryProduct`](@ref): this represent a shared library;

* [`LibraryProduct`](@ref): 这代表一个共享库；


* [`ExecutableProduct`](@ref): this represent a binary executable program.

* [`ExecutableProduct`](@ref)：这代表一个二进制可执行程序。


  Note: this cannot be used for interpreted scripts;

  注意：这不能用于解释性脚本；


* [`FrameworkProduct`](@ref) (only when building for `MacOS`): this represents a [macOS framework](https://en.wikipedia.org/wiki/Bundle_(macOS)#macOS_framework_bundles);

* [`FrameworkProduct`](@ref)（仅在为 `MacOS` 构建时）：这代表一个 [macOS 框架](https://en.wikipedia.org/wiki/Bundle_(macOS)#macOS_framework_bundles)；


* [`FileProduct`](@ref): a file of any type, with no special treatment.

* [`FileProduct`](@ref)：任何类型的文件，没有特殊处理。


The audit will perform a series of sanity checks on the products of the builder, with the exclusion `FileProduct`s, trying also to automatically fix some common issues.

审核将对构建器的产品执行一系列健全性检查，除了 `FileProduct`，同时尝试自动修复一些常见问题。


You don't need to list as products _all_ files that will end up in the tarball, but only those you want to make sure are there and on which you want the audit to perform its checks.  This usually includes the shared libraries and the binary executables.  If you are also generating a JLL package, the products will have some variables that make it easy to reference them.  See the documentation of [JLL packages](./jll.md) for more information about this.

您不需要将最终会出现在压缩包中的 _所有_ 文件列为产品，而只需列出你想要确保存并且希望审计对其执行检查的文件。这通常包括共享库和二进制可执行文件。如果您还生成 JLL 包，则产品将具有一些变量，以便于引用它们。有关此的更多信息，请参阅 [JLL packages](./jll.md) 的文档。

Packages listing products of different types:

不同类型产品的包列表：


* [`Fontconfig`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/F/Fontconfig/build_tarballs.jl#L57-L69).

* [`Fontconfig`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/F/Fontconfig/build_tarballs.jl#L57-L69)。


## Binary dependencies
## 二进制依赖

A build script can depend on binaries generated by another builder. A builder specifies `dependencies` in the form of previously-built JLL packages:

构建脚本可以依赖于另一个构建器生成的二进制文件。构建器以先前构建的 JLL 包的形式指定 `dependencies`：

```julia
# Dependencies of Xorg_xkbcomp
dependencies = [
    Dependency("Xorg_libxkbfile_jll"),
    BuildDependency("Xorg_util_macros_jll"),
]
```


* [`Dependency`](@ref) specify a JLL package that is necessary to build and load the current builder.  Binaries for the target platform will be installed;

* [`Dependency`](@ref) 指定构建和加载所需的 JLL 包并导入到当前的构建器。目标平台的二进制文件将被安装；


* [`RuntimeDependency`](@ref): a JLL package that is necessary only at runtime. Its artifact will not be installed in the prefix during the build.

* [`RuntimeDependency`](@ref)：仅在运行时需要的 JLL 包。在构建阶段，它的工件将不会被安装。

* [`BuildDependency`](@ref) is a JLL package necessary only to build the current package, but not to load it.  This dependency will install binaries for the target platforms and will not be added to the list of the dependencies of the   generated JLL package;

* [`BuildDependency`](@ref) 仅用于构建当前包的 JLL 包，但不加载它。该依赖项将为目标平台安装二进制文件，不会添加到生成的 JLL 包的依赖项列表中；


* [`HostBuildDependency`](@ref): similar to `BuildDependency`, but it will install binaries for the host system.  This kind of dependency is usually   added to provide some binary utilities to run during the build process.

* [`HostBuildDependency`](@ref): 类似于 `BuildDependency`，但它将为主机系统安装二进制文件。通常添加这种依赖性以提供一些二进制实用程序以在构建过程中运行。

The argument of `Dependency`, `RuntimeDependency`, `BuildDependency`, and `HostBuildDependency` can also be a `Pkg.PackageSpec`, with which you can specify more details about the dependency, like a version number, or also a non-registered package.  Note that in Yggdrasil only JLL packages in the [General registry](https://github.com/JuliaRegistries/General) can be accepted.

`Dependency`、`RuntimeDependency`、`BuildDependency` 和 `HostBuildDependency` 的参数也可以是 `Pkg.PackageSpec` 类型，你可以用它指定更多关于依赖的细节，比如版本号，或者非注册包。请注意，在 Yggdrasil 中，只能接受 [General registry](https://github.com/JuliaRegistries/General) 中的 JLL 包。


The dependencies for the target system (`Dependency` and `BuildDependency`) will be installed under `${prefix}` within the build environment, while the dependencies for the host system (`HostBuildDependency`) will be installed under `${host_prefix}`.

目标系统的依赖项（`Dependency` 和 `BuildDependency` ）将安装在构建环境中的 `${prefix}` 下，而主机系统的依赖项（`HostBuildDependency`）将安装在 `${host_prefix}` 下。


In the wizard, dependencies can be specified with the prompt: *Do you require any (binary) dependencies?  [y/N]*.

在 Wizard 向导中，可以通过提示指定依赖项：*Do you require any (binary) dependencies? [y/N]*。


Examples of builders that depend on other binaries include:

依赖于其他二进制文件的构建器示例包括：


* [`Xorg_libX11`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/X/Xorg_libX11/build_tarballs.jl#L36-L42) depends on `Xorg_libxcb_jll`, and `Xorg_xtrans_jll` at build- and run-time,   and on `Xorg_xorgproto_jll` and `Xorg_util_macros_jll` only at build-time.

* [`Xorg_libX11`](https://github.com/JuliaPackaging/Yggdrasil/blob/eb3728a2303c98519338fe0be370ef299b807e19/X/Xorg_libX11/build_tarballs.jl#L36-L42) 在构建和运行时依赖于 `Xorg_libxcb_jll` 和 `Xorg_xtrans_jll`，仅在构建时依赖于 `Xorg_xorgproto_jll` 和 `Xorg_util_macros_jll`。

### Platform-specific dependencies
### 特定于平台的依赖项


By default, all dependencies are used for all platforms, but there are some cases where a package requires some dependencies only on some platforms.  You can specify the platforms where a dependency is needed by passing the `platforms` keyword argument to the dependency constructor, which is the vector of `AbstractPlatforms` where the dependency should be used.

默认情况下，所有依赖项都用于所有平台，但在某些情况下，包仅在某些平台上需要某些依赖项。您可以通过将 `platforms` 关键字参数传递给依赖构造器来指定需要依赖的平台，这是一个 `AbstractPlatforms` 类型的向量，指定应使用的依赖项。


For example, assuming that the variable `platforms` holds the vector of the platforms for which to build your package, you can specify that `Package_jl` is required on all platforms excluding Windows one with

例如，假设变量 `platforms` 包含要为其构建包的平台的向量，您可以指定 `Package_jl` 在除 Windows 之外的所有平台上都是必需的

```julia
Dependency("Package_jll"; platforms=filter(!Sys.iswindows, platforms))
```


The information that a dependency is only needed on some platforms is transferred to the JLL package as well: the wrappers will load the platform-dependent JLL dependencies only when needed.

这些平台依赖信息也被传输到 JLL 包：包装器仅在需要时加载依赖于该平台的 JLL 依赖项。


!!! warning

    Julia's package manager doesn't have the concept of optional (or platform-dependent) dependencies: this means that when installing a JLL  package in your environment, all of its dependencies will always be installed as well in any case.  It's only at runtime that platform-specific dependencies will be loaded where necessary.

!!! 警告
   Julia 的包管理器没有可选依赖项或平台相关依赖项的概念：这意味着当在您的环境中安装 JLL 包时，在任何情况下，它的所有依赖项都将被安装。只有在运行必要时才会加载特定于平台的依赖项。

   For the same reason, even if you specify a dependency to be not needed on for a platform, the build recipe may still pull it in if that's also an indirect dependency required by some other dependencies.  At the moment `BinaryBuilder.jl` isn't able to propagate the information that a dependency is platform-dependent when installing the artifacts of the dependencies.

   出于同样的原因，即使您指定平台不需要的依赖项，如果它也是其他一些依赖项所需的间接依赖项，构建配方仍可能会引入它。目前，`BinaryBuilder.jl` 在安装依赖项的工件时无法传播依赖项依赖于平台的信息。


Examples:

例子：


* [`ADIOS2`](https://github.com/JuliaPackaging/Yggdrasil/blob/0528e0f31b55355df632c79a2784621583443d9c/A/ADIOS2/build_tarballs.jl#L122-L123) uses `MPICH_jll` to provide an MPI implementations on all platforms excluding   Windows, and `MicrosoftMPI_jll` for Windows.

* [`ADIOS2`](https://github.com/JuliaPackaging/Yggdrasil/blob/0528e0f31b55355df632c79a2784621583443d9c/A/ADIOS2/build_tarballs.jl#L122-L123) 使用 `MPICH_jll` 在除 Windows 之外的所有平台上提供 MPI 实现，并为 Windows 使用 `MicrosoftMPI_jll`。


* [`GTK3`](https://github.com/JuliaPackaging/Yggdrasil/blob/0528e0f31b55355df632c79a2784621583443d9c/G/GTK3/build_tarballs.jl#L70-L104) uses the X11 software stack only on Linux and FreeBSD platforms, and Wayland only on Linux.

* [`GTK3`](https://github.com/JuliaPackaging/Yggdrasil/blob/0528e0f31b55355df632c79a2784621583443d9c/G/GTK3/build_tarballs.jl#L70-L104) 仅在 Linux 和 FreeBSD 平台上使用 X11 软件栈，仅在 Linux 上使用 Wayland。


* [`NativeFileDialog`](https://github.com/JuliaPackaging/Yggdrasil/blob/0528e0f31b55355df632c79a2784621583443d9c/N/NativeFileDialog/build_tarballs.jl#L40-L44) uses GTK3 only on Linux and FreeBSD, on all other platforms it uses system libraries, so no other packages are needed in those cases.

* [`NativeFileDialog`](https://github.com/JuliaPackaging/Yggdrasil/blob/0528e0f31b55355df632c79a2784621583443d9c/N/NativeFileDialog/build_tarballs.jl#L40-L44) 仅在 Linux 和 FreeBSD 上使用 GTK3，在所有其他平台上它使用系统库，因此在这些情况下不需要其他包。


### Version number of dependencies

### 依赖的版本号
There are two different ways to specify the version of a dependency, with two different meanings:

有两种不同的方式来指定依赖的版本，具有两种不同的含义：


* `Dependency("Foo_jll", v"1.2.3")`: the second argument of `Dependency` specifies the version of the package to be used for building: this version *is not* reflected into a compatibility bound in the project of the generated JLL package.  This is useful when the package you want to build is compatible with all the versions of the dependency starting from the given one (and then you don't want to restrict compatibility bounds of the JLL package), but to maximize compatibility you want to build against the oldest compatible version.

* `Dependency("Foo_jll", v"1.2.3")`: `Dependency` 的第二个参数指定用于构建包的版本：此版本*未*反映在生成的 JLL 包项目中的版本兼容性边界。在这种情况下会很有用：当您要构建的包与从给定版本开始的所有依赖项版本兼容（而且您不想限制 JLL 包的兼容性范围），但为了最大化你对旧版本的兼容性能力。

* `Dependency(PackageSpec(; name="Foo_jll", version=v"1.2.3"))`: if the package is given as a `Pkg.PackageSpec` and the `version` keyword argument is given, this version of the package is used for the build *and* the generated JLL package will be compatible with the provided version of the package.  This should be used when your package is compatible only with a single version of the dependency, a condition that you want to reflect also in the project of the JLL package.

* `Dependency(PackageSpec(; name="Foo_jll", version=v"1.2.3"))`: 如果包作为 `Pkg.PackageSpec` 给出并且给出了 `version` 关键字参数，这个版本的包用于构建*而且*生成的 JLL 包将与提供的包版本兼容。当您的包仅与单一版本的依赖项兼容时，且希望在 JLL 包的项目中反映这种情况，应使用此选项。


# Building and testing JLL packages locally
# 在本地构建和测试 JLL 包


As a package developer, you may want to test JLL packages locally, or as a binary dependency developer you may want to easily use custom binaries.  Through a combination of `dev`'ing out the JLL package and creating an `overrides` directory, it is easy to get complete control over the local JLL package state.

作为包开发人员，您可能希望在本地测试 JLL 包，或者作为二进制依赖项开发人员，您可能希望轻松使用自定义二进制文件。通过结合 `dev` 中的 JLL 包和创建一个 `overrides` 目录，可以轻松完全控制本地 JLL 包状态。


## Overriding a prebuilt JLL package's binaries
## 覆盖预构建 JLL 包的二进制文件


After running `pkg> dev LibFoo_jll`, a local JLL package will be checked out to your depot's `dev` directory (on most installations this is `~/.julia/dev`) and by default the JLL package will make use of binaries within your depot's `artifacts` directory.  If an `override` directory is present within the JLL package directory, the JLL package will look within that `override` directory for binaries, rather than in any artifact directory.  Note that there is no mixing and matching of binaries within a single JLL package; if an `override` directory is present, all products defined within that JLL package must be found within the `override` directory, none will be sourced from an artifact.  Dependencies (e.g. found within another JLL package) may still be loaded from their respective artifacts, so dependency JLLs must themselves be `dev`'ed and have `override` directories created with files or symlinks created within them.

运行 `pkg> dev LibFoo_jll` 后，本地 JLL 包将被 `check out` 到您 “开发中” 的目录（大多数情况的路径为 `~/.julia/dev`），默认情况下，JLL 包将你的开发中的 `artifacts` 目录的二进制文件。如果 JLL 包目录中存在目录 `override`，则 JLL 包将在该 `override` 目录中查找二进制文件，而不是在任何 `artifact` 目录中。请注意，在单个 JLL 包中二进制文件不存在混合和匹配；如果存在 `override` 目录，则该 JLL 包中定义的所有产品都必须在 `override` 目录中找到，而不能来自 `artifact`。依赖项（例如，在另一个 JLL 包中的）可能仍会从它们各自的工件中加载，因此 JLL 依赖项本身必须是 “开发过” 的，并且具有创建了文件或符号链接的 `override` 目录。


### Auto-populating the `override` directory
### 自动填充 `override` 目录

To ease creation of an `override` directory, JLL packages contain a `dev_jll()` function, that will ensure that a `~/.julia/dev/<jll name>` package is `dev`'ed out, and will copy the normal artifact contents into the appropriate `override` directory.  This will result in no functional difference from simply using the artifact directory, but provides a template of files that can be replaced by custom-built binaries.

为了简化 `override` 目录的创建，JLL 包包含一个 `dev_jll()` 函数，这将确保 `~/.julia/dev/<jll name>` 包被 `dev` 输出，并把正常的工件内容复制到适当的 `override` 目录中。这对于简单地使用工件目录没有功能上的区别，但提供了一个可以由自定义构建的二进制文件替换的文件模板。


Note that this feature is rolling out to new JLL packages as they are rebuilt; if a JLL package does not have a `dev_jll()` function, [open an issue on Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil/issues/new) and a new JLL version will be generated to provide the function.

请注意，此功能将在重建时推广到新的 JLL 包；如果 JLL 包没有 `dev_jll()` 函数，[在 Yggdrasil 上打开一个问题](https://github.com/JuliaPackaging/Yggdrasil/issues/new) 将生成一个新的 JLL 版本以提供功能。


## Building a custom JLL package locally

## 在本地构建自定义 JLL 包


When building a new version of a JLL package, if `--deploy` is passed to `build_tarballs.jl` then a newly-built JLL package will be deployed to a GitHub repository.  (Read the documentation in the [Command Line](@ref) section or given by passing `--help` to a `build_tarballs.jl` script for more on `--deploy` options).  If `--deploy=local` is passed, the JLL package will still be built in the `~/.julia/dev/` directory, but it will not be uploaded anywhere.  This is useful for local testing and validation that the built artifacts are working with your package.

在构建新版本的 JLL 包时，如果将 `--deploy` 传递给 `build_tarballs.jl`，则新构建的 JLL 包将部署到 GitHub 存储库。 （阅读 [命令行](@ref) 部分中的文档或通过将 `--help` 传递给 `build_tarballs.jl` 脚本来获取有关 `--deploy` 选项的更多信息）。如果传递 `--deploy=local` ，JLL 包仍将构建在 `~/.julia/dev/` 目录中，但不会上传到任何地方。这对于本地测试和验证构建的工件是否与您的包一起工作很有用。

