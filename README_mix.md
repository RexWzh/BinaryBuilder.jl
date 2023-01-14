# BinaryBuilder

[![Build Status](https://dev.azure.com/JuliaPackaging/BinaryBuilder.jl/_apis/build/status/JuliaPackaging.BinaryBuilder.jl?branchName=master)](https://dev.azure.com/JuliaPackaging/BinaryBuilder.jl/_build/latest?definitionId=2&branchName=master) [![codecov.io](http://codecov.io/github/JuliaPackaging/BinaryBuilder.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPackaging/BinaryBuilder.jl?branch=master) 

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://docs.binarybuilder.org/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://docs.binarybuilder.org/dev)

> "Yea, though I walk through the valley of the shadow of death, I will fear no evil"

> “是的，我虽然经历了死亡的阴影，但我不会害怕任何邪恶”

# Quickstart

1. Install `BinaryBuilder` 安装模块 `BinaryBuilder` 
    ```julia
    using Pkg; Pkg.add("BinaryBuilder")
    ```

1. Run the wizard. 运行向导。
    ```julia
    using BinaryBuilder
    BinaryBuilder.run_wizard()
    ```

2. The wizard will take you through a process of building your software package. Note that the wizard may need to download a new compiler shard for each platform targeted, and there are quite a few of these, so a fast internet connection can be helpful.  The output of this stage is a `build_tarballs.jl` file, which is most commonly deployed as a pull request to the community buildtree [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil).  For experienced users, it is often more convenient to directly copy/modify an existing `build_tarballs.jl` file within Yggdrasil, then simply open a pull request where CI will test building the binary artifacts for all platforms again.

3. 该向导将引导您完成构建软件包的过程。 请注意，该向导可能需要为每个目标平台下载一个新的编译器碎片，其中的文件很多，因此网速快的互联网连接可能会有所帮助。 此阶段的输出是一个 `build_tarballs.jl` 文件，最常作为拉取请求部署到社区构建树 [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil)。 对于有经验的用户，直接复制/修改 Yggdrasil 中现有的 `build_tarballs.jl` 文件通常更方便，然后只需打开一个拉取请求，CI 将在其中再次测试为所有平台构建二进制工件。

4. The output of a build is a JLL package (typically hosted within the [JuliaBinaryWrappers](https://github.com/JuliaBinaryWrappers/) GitHub organization) which can be added to packages just like any other Julia package.  The JLL package will export bindings for all products defined within the build recipe.

4. 构建的输出是一个 JLL 包（通常托管在 [JuliaBinaryWrappers](https://github.com/JuliaBinaryWrappers/) GitHub 组织中），可以像任何其他 Julia 包一样添加到包中。 JLL 包将为构建配方中定义的所有产品导出绑定。

For more information, see the documentation for this package, viewable either directly in markdown within the [`docs/src`](docs/src) folder within this repository, or [online](https://docs.binarybuilder.org).

有关更多信息，请参阅此软件包的文档，在此存储库中的 [`docs/src`](docs/src) 文件夹中直接查看 markdown，或者 [在线](https://docs.binarybuilder.org)。

# Philosophy

Building binary packages is a pain.  `BinaryBuilder` follows a philosophy that is similar to that of building [Julia](https://julialang.org) itself; when you want something done right, you do it yourself.  To that end, `BinaryBuilder` is designed from the ground up to facilitate the building of packages within an easily reproducible and reliable Linux environment, ensuring that the built libraries and executables are deployable to every platform that Julia itself will run on.  Packages are cross-compiled using a sequence of shell commands, packaged up inside tarballs, and hosted online for all to enjoy.  Package installation is merely downloading, verifying package integrity and extracting that tarball on the user's computer.  No more compiling on user's machines.  No more struggling with system package managers.  No more needing `sudo` access to install that little mathematical optimization library.

构建二进制包很辛苦的事情。 `BinaryBuilder` 遵循与构建 [Julia](https://julialang.org) 本身类似的理念; 当你想要做好一件事时，你就要自己做。 为此，`BinaryBuilder` 从一开始就设计为在易于重现和可靠的 Linux 环境中构建软件包，确保构建的库和可执行文件可以部署到 Julia 本身将运行的每个平台上。 使用一系列 shell 命令对软件包进行交叉编译，将其打包到压缩包中，并在线上托管供所有人使用。包安装只是下载，验证包完整性并在用户计算机上提取压缩包。不再在用户机器上编译。不再与系统包管理器斗争。不再需要 `sudo` 权限来安装那个小的数学优化库。

All packages are cross compiled. If a package does not support cross compilation, we patch the package or, in extreme cases, rebundle prebuilt executables.

所有软件包都是交叉编译的。如果软件包不支持交叉编译，我们会修补软件包，或者在极端情况下，重新打包预构建的可执行文件。

The cross-compilation environment that we use is a homegrown Linux environment with many different compilers built for it, including various versions of `gcc`, `clang`, `gfortran`, `rustc` and `go`.  You can read more about this in [the `RootFS.md` file](https://github.com/JuliaPackaging/Yggdrasil/blob/master/RootFS.md) within the Yggdrasil repository.

我们使用的交叉编译环境是一个自制的 Linux 环境，其中包含许多为其构建的不同编译器，包括各种版本的 `gcc`，`clang`，`gfortran`，`rustc` 和 `go`。 您可以在 Yggdrasil 存储库中的 [`RootFS.md` 文件](https://github.com/JuliaPackaging/Yggdrasil/blob/master/RootFS.md) 中阅读更多信息。