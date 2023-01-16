
# 根文件系统

所有 `BinaryBuilder.jl` 构建所在的执行环境称为“根文件系统”或 _RootFS_。此 RootFS 是使用 Yggdrasil 中 [`0_Rootfs` 目录](https://github.com/JuliaPackaging/Yggdrasil/tree/master/0_RootFS) 包含的构建器脚本构建的。 rootfs 镜像基于 `alpine` docker 镜像，用于为我们支持的每个目标平台构建编译器。目标平台编译器工具链存储在 `/opt/${triplet}` 中，因此 64 位 Linux（使用 `glibc` 作为支持 `libc`）编译器将在 `/opt/x86_64-linux-gnu/bin` 中找到。

每个编译器“分片”都是单独打包的，这样用户就不必为了构建单个平台而下载多 GB 的压缩包。有一个总的“根”分片，以及平台支持分片、GCC 分片、LLVM 分片、Rust 分片等...这些都嵌入在捆绑的 [`Artifacts.toml` 文件](https://github.com/JuliaPackaging/BinaryBuilder.jl/blob/master/Artifacts.toml)，而 `BinaryBuilder.jl` 会按需下载它们，利用 Julia 1.3+ 的新 [Pkg.Artifacts 系统](https://julialang.github.io/Pkg.jl/dev/artifacts/)。

每个分片都可以作为解压的目录树以及 `.squashfs` 图像使用。 `.squashfs` 图像占用的磁盘空间要少得多，但不幸的是，它们需要主机上的 `root` 权限，并且只能在 Linux 上运行。这有望在未来的 Linux 内核版本中得到修复，但如果您拥有 sudo 权限，通常需要使用 `.squashfs` 文件来节省网络带宽和磁盘空间。有关如何执行此操作的说明，请参阅 [环境变量](environment_variables.md)。

在 RootFS 映像中启动进程时，`BinaryBuilder.jl` 会设置一组环境变量以启用特定于目标的编译器工具链，以及其他细节。有关更多详细信息，请参阅 [Build Tips](build_tips.md) 文档页面，以及本仓库的 `src/Runner.jl` 文件。

