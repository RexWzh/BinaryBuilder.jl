
# BinaryBuilder.jl
Julia 包 [`BinaryBuilder.jl`](https://github.com/JuliaPackaging/BinaryBuilder.jl) 的目的是提供一个编译第三方二进制依赖项的系统，该系统应可以在 [Julia 发行版](https://julialang.org/downloads) 中工作。特别地，通过此软件包你能够将 C、C++、Fortran、Rust、Go 等软件的大型预先存在的代码库编译成二进制文件，这些二进制文件可以在非常广泛的范围内下载和加载/运行。由于这个包支持的平台越来越多，在本地编译软件包会很困难（而且通常很昂贵），我们专注于提供一组 Linux 托管的交叉编译器。这个包将搭建一个环境来对所有主要平台进行交叉编译，并尽最大努力使编译过程尽可能轻松。

注意：当前 BinaryBuilder 本身仅在 Linux `x86_64` 和 macOS `x86_64` 系统上运行，Windows 支持正在积极开发中。在 macOS 和 Windows 上，你必须安装 `docker` 作为后端虚拟化引擎。注意 Docker Desktop 是推荐的版本; 如果你安装了 Docker Machine，它可能无法正常工作或可能需要额外的配置。

## 项目流程

假设你有一个 Julia 包 `Foo.jl`，它需要使用一个已编译的 `libfoo` 共享库。作为编写 `Foo.jl` 的第一步，你可以使用系统编译器在你自己的机器上本地编译 `libfoo`，然后使用 `Libdl.dlopen()` 打开库，并通过 `ccall()` 调用导出的函数。一旦你用 Julia 编写了你的​​ C 绑定，你自然会希望与世界其他地方分享你的劳动成果，这正是 `BinaryBuilder` 可以帮助你的地方。`BinaryBuilder` 不仅会帮助你构建所有依赖项的编译版本，还会构建一个包装器 Julia 包（称为 [JLL 包](jll.md)）以帮助安装、版本控制和构建产品本地化。

`BinaryBuilder` 旅程的第一步是创建一个构建配方(build recipe)，通常命名为 `build_tarballs.jl`。Julia 社区策划了一棵构建配方树——[Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil)，其已经包含了许多如何编写 `build_tarballs.jl` 文件的示例。这些文件包括诸如：特定构建的名称、版本和源位置等信息，以及实际执行步骤（以 `bash` 脚本的形式）和构建应生成的产品。

成功构建的结果是一个自动生成的 JLL 包，通常上传到 github 组织[JuliaBinaryWrappers](https://github.com/JuliaBinaryWrappers/)。每个版本的每个构建的二进制文件都会上传到相关 JLL 包的 GitHub 发布页面。最后，会打开对 Julia 注册表 `General` 的合并请求，以便诸如上述 `Foo.jl` 之类的包可以通过简单地 `pkg> add libfoo_jll` 来下载二进制构件以及自动生成的 Julia 包装器代码。另请参阅 [FAQ](FAQ.md)，[构建提示](build_tips.md)，[构建故障排除](troubleshooting.md) 和 [棘手的陷阱](tricksy_gotchas.md) 以帮助解决常见问题。

### 交互界面

`BinaryBuilder.jl` 支持一种交互式方法，用于构建二进制依赖项并将用于构建它的命令捕获到 `build_tarballs.jl` 文件中：交互界面。要启动它，请运行

```julia
using BinaryBuilder
state = BinaryBuilder.run_wizard()
```

以及屏幕上的说明。你可以观看[asciinema demo](https://asciinema.org/a/304105)以了解使用向导向的方法。

!!! note
    该向导是一个很棒的工具，特别是刚开始用 BinaryBuilder 为新包创建简单的配方。然而，它缺乏在 `build_tarballs.jl` 脚本中可以使用的所有选项的完全控制。要生成此文件，可以克隆 `Yggdrasil`，复制现有的构建配方，修改它，并提交新的拉取请求（在 [构建包](building.md) 中有更详细的说明）。当你想要更新现有的配方而不是从头开始使用向导时，手动编辑 `build_tarballs.jl` 脚本也是推荐的方法。

### 手动创建或编辑 `build_tarballs.jl`

`build_tarballs.jl` 脚本可用作命令行实用程序，它支持若干选项以及用作目标的三元组列表。你可以在 [Command Line](@ref) 部分中找到有关脚本语法的更多信息，或者运行

```
julia build_tarballs.jl --help
```

你也可以使用下面的命令构建压缩包

```
julia build_tarballs.jl --debug --verbose
```

如果发生错误，`--debug` 选项将使你进入 BinaryBuilder 交互式 shell。如果构建失败，在找出修复构建所需的步骤之后，你必须手动更新 `build_tarballs.jl` 中的脚本。你应该再次运行上述命令，以确保一切都是正常的。

由于 `build_tarballs.jl` 将 [三元组](@ref Platforms) 压缩包的逗号分隔列表作为参数，因此你能只选择其中的几个。例如，通过

```
julia build_tarballs.jl --debug --verbose aarch64-linux-musl,arm-linux-musleabihf
```

你将只为 `aarch64-linux-musl` 和 `arm-linux-musleabihf` 目标平台运行构建脚本。

但是，如果你决定使用此工作流程，则需要手动提交 [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil/) 的拉取请求。

!!! note
    （译注）在脚本
    
    ```bash
    julia build_tarballs.jl --debug --verbose aarch64-linux-musl,arm-linux-musleabihf
    ```
    
    中，`--verbose` 后边指定目标平台的三元组列表，该列表可以通过执行
    
    ```julia
    using BinaryBuilder
    triplet.(supported_platforms())
    ```
    
    来查看。此外，多个平台以 `,` 隔开，且不能包含空格。

### GitHub 代码空间

如果你已经有了 [GitHub Codespaces](https://github.com/features/codespaces) 服务的访问权限，你可以在你的浏览器或者在 Visual Studio Code 上使用 BinaryBuilder 和上述所有工作流，也包括那些不被包本身支持的操作系统！前往 [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil/) 并创建一个新的代码空间。

## 这一切是如何工作的？

`BinaryBuilder.jl` 包装了一个经过仔细构造的 [root filesystem](rootfs.md)，以便提供支持运行 Julia 的广泛平台所需的交叉编译器集。然后，这个 _RootFS_ 用作 chroot jail 的沙盒进程，该进程在 RootFS 中运行，就仿佛它是整个世界一样。在 RootFS 中挂载包含输入源代码和（最终）输出二进制文件的工作区，并设置环境变量，以便构建工具使用特定目标平台的适当编译器。


## 可重复性

> [可重现构建](https://reproducible-builds.org/) 是一组软件开发实践，指能够创建从源代码到二进制代码的独立可验证路径。

`BinaryBuilder.jl` 实施了许多实现可重现构建所需的实践。

例如，构建环境是沙盒化的，并使用固定的树结构，因此具有可重现的[构建路径](https://reproducible-builds.org/docs/build-path/)。

`BinaryBuilder.jl` 使用的工具链还设置了一些[环境变量](https://reproducible-builds.org/docs/source-date-epoch/) 并强制执行某些有助于复现的 [编译器标志](https://reproducible-builds.org/docs/randomness/)。

虽然 `BinaryBuilder.jl` 不能保证始终具有可重现的构建，但它在大多数情况下都能做到这点。

`BinaryBuilder.jl` 中的可重复性还包括生成的压缩包：它们是使用 [`Tar.jl`](https://github.com/JuliaIO/Tar.jl) 创建的，采取了[一些措施](https://github.com/JuliaIO/Tar.jl/blob/1de4f92dc1ba4de4b54ac5279ec1d84fb15948f6/README.md#reproducibility)以确保具有相同 git 树哈希值的压缩包的可再现性。

如果你使用相同版本的 BinaryBuilder 多次重建同一个包，生成包含主要产品的压缩包（即，不包括不可复现的日志文件）应始终具有相同的 git 树哈希和 `sha256sum`。构建过程结束时将打印到屏幕上并存储在 [JLL 包](@ref JLL-packages) 的 `Artifacts.toml` 文件中。

但是有一些注意事项：

* 只有在使用 `BinaryBuilder.jl` 提供的工具链时才能预期再现性；

* 在 [非常具体的情况](https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1230) 中，macOS C/C++ 工具链不会生成可重现的二进制文件。

  当进行调试构建（`-g` 标志）_并且_不单独构建具有确定名称的目标文件时，会发生这种情况。（例如，如果直接从源文件构建和链接程序或共享库，让编译器自动创建中间目标文件随机名称）。

  我们决定不处理这种情况，因为在实践中，大多数包使用的构建系统会编译具有确定名称的中间目标文件，（这也是善用 `ccache` 的唯一方法，在 `BinaryBuilder.jl` 被广泛使用）并且通常不进行调试构建，因此完全回避了这个问题。

## 视频和教程

BinaryBuilder 已经在一些视频中介绍过，如果你想了解更多关于该框架的信息，你可能需要查看它们（括号中指定了日期，以明确视频的新旧程度）：


* [关于如何构建更好的二进制文件的 10 个技巧](https://www.youtube.com/watch?v=2e0PBGSaQaI)：Elliot Saba 在 JuliaCon 2018 的演讲介绍了早期版本的 BinaryBuilder (2018-08-09)

* [BinaryBuilder.jl 简介](https://www.youtube.com/watch?v=d_h8C4iCzno)：Mosè Giordano 的实时构建会话 (2020-04-10)

* [BinaryBuilder.jl - 二进制文件的精妙艺术](https://www.youtube.com/watch?v=3IyXsBwqll8)：Elliot Saba 和 Mosè Giordano 举办的 JuliaCon 2020 研讨会，指导用户使用 BinaryBuilder (2020-07-25)

* [你与 Julia 的第一个 BinaryBuilder.jl 配方](https://www.youtube.com/watch?v=7fkNcdbt4dg)：Miguel Raz Guzmán Macedo 的实时构建 (2021-04-07)

* [BinaryBuilder.jl —“正常工作”的二进制文件的精妙艺术](https://bbb.dereferenced.org/playback/presentation/2.3/75a49eebcb63d6fee8c55417ea7cc51768d86f3d-1621065511930)：Elliot Saba 和 Mosè Giordano 的 AlpineConf 2021 演讲，开始时间在 4:19:00 (2021-05-15)


* [BinaryBuilder.jl — 使用 Julia 的 Pkg 交付二进制库](https://www.youtube.com/watch?v=S__x3K31qnE)：Mosè Giordano 和 Elliot Saba 在 PackagingCon 2021 上的演讲 (2021-11-10)

