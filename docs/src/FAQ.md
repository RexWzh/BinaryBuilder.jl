
# 常见问题

### 我在编译 `<project name here>` 时遇到问题

首先，确保您可以在您尝试编译它的任何平台上本地编译该项目。确保这点后，就在互联网上搜索，看看是否有其他人在为该平台交叉编译该项目时遇到问题。特别是，大多数较小的项目应该没问题，但较大的项目（尤其是任何进行任何类型的引导的项目）可能需要在其构建系统中加入一些额外的智能以支持交叉编译。最后，如果您仍然遇到困难，请尝试通过 JuliaLang slack 中的 [`#binarybuilder` 频道](https://julialang.slack.com/archives/C674ELDNX) 寻求帮助。

### 我如何使用它来编译我的 Julia 代码？

这个包不编译 Julia 代码；它编译 C/C++/Fortran 依赖项。回想你使用 `IJulia` 并且需要下载/安装 `libnettle` 的时候。这个包的目的是使生成的压缩包可以尽可能轻松地下载/安装。

### 我听说的 macOS SDK 许可协议是什么？

Apple 限制 macOS SDK 的分发和使用，这是为 macOS 目标构建软件的必要组件。请阅读[Apple 与 Xcode SDK 协议](https://images.apple.com/legal/sla/docs/xcode.pdf) 以获取更多有关使用 SDK 构建软件时您同意的限制和法律条款的信息适用于苹果操作系统。版权法是一个复杂的领域，您不应从互联网上的常见问题解答中获取法律建议。该工具包旨在主要在 Linux 上运行，但它当然可以在 macOS 机器上的虚拟化环境中使用，或者直接通过运行 Linux Apple 硬件来使用。 Docker runner 在 macOS 机器上实现虚拟化方法。默认情况下，`BinaryBuilder.jl` 不会在非苹果主机操作系统上自动下载或使用 macOS SDK，除非将 `BINARYBUILDER_AUTOMATIC_APPLE` 环境变量设置为 `true`。

### 我可以使用其他环境变量吗？

是的，[看看这里](environment_variables.md)。


### 嘿，这很酷，我可以将它用于我的非 Julia 相关项目吗？

当然！ `BinaryBuilder.jl` 使用的交叉编译器生成的二进制文件与 Julia 无关。尽管与此软件交互的最佳界面始终是此包中定义的 Julia 界面，但您也可以自由地将这些软件工具用于其他项目。请注意，交叉编译器映像是通过多阶段引导过程构建的，[有关详细信息，请参阅此存储库](https://github.com/JuliaPackaging/Yggdrasil)。进一步注意上面的 **macOS SDK 许可协议**。

### 在第 XXX 行，中止（不允许操作）！

一些 linux 发行版在他们的 `overlayfs` 实现中有一个错误，阻止我们在用户命名空间中安装覆盖文件系统。请参阅[此 Ubuntu 内核错误报告](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1531747)，了解有关情况的描述以及 Ubuntu 如何在其内核中对其进行修补。要解决此问题，您可以在“特权容器”模式下启动 `BinaryBuilder.jl`。 BinaryBuilder 应该会自动检测这种情况，但是如果自动检测不起作用或者您想消除警告，您可以将 `BINARYBUILDER_RUNNER` 环境变量设置为 `privileged`。不幸的是，这涉及在每次启动 BinaryBuilder 会话时运行 `sudo`，但另一方面，这成功地解决了 Arch linux 等发行版上的问题。

### 我必须构建一个没有 Makefile 的非常小的项目，我该怎么办？

BinaryBuilder 需要的是找到整理在 `$prefix` 目录下的相关文件（共享库或可执行文件等...）：库应该到 `${libdir}`，可执行文件到 `${bindir}`。您可能需要创建这些目录。您可以自由选择是创建一个简单的 Makefile 来构建项目，还是在 `build_tarballs.jl` 脚本中执行所有操作。

当脚本完成时，BinaryBuilder 期望在 `${libdir}` 或 `${bindir}` 中找到至少一个为预期架构构建的工件。

还请记住，您应该根据需要使用标准环境变量，如 `CC`、`CXX`、`CFLAGS`、`LDFLAGS` 以便交叉编译。请参阅 [构建提示](build_tips.md) 部分中的变量列表。

### 我可以在特定的构建环境中打开一个 shell 来进行一些快速测试吗？

是的！您可以使用 [`BinaryBuilder.runshell(platform)`](@ref BinaryBuilderBase.runshell) 在当前目录中快速启动 shell，而无需设置有效的 `build_tarballs.jl` 脚本。例如，

```
julia -e 'using BinaryBuilder; BinaryBuilder.runshell(Platform("i686", "windows"))'
```

将在 Windows 32 位构建环境中打开一个 shell，不加载任何源代码。您系统的当前工作目录将安装在此 BinaryBuilder 环境中的 `${WORKSPACE}` 上。

### 我可以在不通过 Yggdrasil 的情况下在本地发布 JLL 包吗？

您始终可以使用 `build_tarballs.jl` 脚本的 `--deploy` 标志在您的机器上构建一个 JLL 包。阅读帮助 (`--help`) 了解更多信息。

一个常见的用例是，您想为 `Libfoo` 构建一个 JLL 包，它将用作构建 `Quxlib` 的依赖项，并且您想要确保同时构建 `Libfoo` 和 `Quxlib` 将在将所有拉取请求提交到 [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil/) 之前工作。您可以为 `Libfoo` 准备 `build_tarballs.jl` 脚本，然后使用

```
julia build_tarballs.jl --debug --verbose --deploy="MY_USERNAME/Libfoo_jll.jl"
```

将 `MY_USERNAME` 替换为您的 GitHub 用户名：这将为所有请求的平台构建压缩包，并将它们上传到 `MY_USERNAME/Libfoo_jll.jl` 的版本，其中也将创建 JLL 包。如上所述，如果您只想编译其中的一些，您可以将参数传递给您要构建 tarball 的平台的三元组列表。在 Julia REPL 中，您可以将此包安装为任何未注册的包

```julia
]add https://github.com/MY_USERNAME/Libfoo_jll.jl.git
```

或开发它

```julia
]dev https://github.com/MY_USERNAME/Libfoo_jll.jl.git
```

由于此包未注册，您必须使用完整的 [`PackageSpec`](https://julialang.github.io/Pkg.jl/v1/api/#Pkg.PackageSpec) 规范将其添加为本地的依赖项 `Quxlib` 的构建器：

```julia
    Dependency(PackageSpec(; name = "Libfoo_jll",  uuid = "...", url = "https://github.com/MY_USERNAME/Libfoo_jll.jl.git"))
```

你当然可以反过来构建和部署这个包

```
julia build_tarballs.jl --debug --verbose --deploy="MY_USERNAME/Quxlib_jll.jl"
```

请注意，`PackageSpec` 也可以指向本地路径：例如，`PackageSpec(; name="Libfoo_jll", uuid="...", path="/home/myname/.julia/dev/Libfoo_jll")` .这在 [在本地构建自定义 JLL 包](@ref) 而不是将其部署到远程 Git 存储库时特别有用。

### 源列表中的那些数字是什么？我如何得到它们？

源列表是 [`BinaryBuilder.AbstractSource`](@ref) 的向量。哈希值是什么取决于来源是什么：

* 对于 [`FileSource`](@ref) 或 [`ArchiveSource`](@ref)，哈希值是 64 个字符的 SHA256 校验和。如果您有该文件的副本，则可以使用 Julia 计算哈希值

```julia
  using SHA
  open(path_to_the_file, "r") do f
       bytes2hex(sha256(f))
  end
  ```
  其中 `path_to_the_file` 是包含文件路径的字符串。或者，您可以使用命令行实用程序 `curl` 和 `shasum` 来计算远程文件的哈希值：

  ```
  $ curl -L http://example.org/file.tar.gz | shasum -a 256
  ```

  将 `http://example.org/file.tar.gz` 替换为您要下载的文件的实际 URL。

* 对于 [`GitSource`](@ref)，哈希值是您要 `check out` 的修订版的 40 个字符的 SHA1 哈希值。为了可重复性，您必须指出特定的修订版，而不是分支或标签名称，它们是会改变的。

