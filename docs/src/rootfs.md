
# RootFS

# 根文件系统


The execution environment that all `BinaryBuilder.jl` builds are executed within is referred to as the "root filesystem" or _RootFS_.  This RootFS is built using the builder scripts contained within the [`0_Rootfs` directory](https://github.com/JuliaPackaging/Yggdrasil/tree/master/0_RootFS) within Yggdrasil.  The rootfs image is based upon the `alpine` docker image, and is used to build compilers for every target platform we support.  The target platform compiler toolchains are stored within `/opt/${triplet}`, so the 64-bit Linux (using `glibc` as the backing `libc`) compilers would be found in `/opt/x86_64-linux-gnu/bin`.

所有 `BinaryBuilder.jl` 构建所在的执行环境称为“根文件系统”或 _RootFS_。此 RootFS 是使用 Yggdrasil 中 [`0_Rootfs` 目录](https://github.com/JuliaPackaging/Yggdrasil/tree/master/0_RootFS) 包含的构建器脚本构建的。 rootfs 镜像基于 `alpine` docker 镜像，用于为我们支持的每个目标平台构建编译器。目标平台编译器工具链存储在 `/opt/${triplet}` 中，因此 64 位 Linux（使用 `glibc` 作为支持 `libc`）编译器将在 `/opt/x86_64-linux-gnu/bin` 中找到。


Each compiler "shard" is packaged separately, so that users do not have to download a multi-GB tarball just to build for a single platform.  There is an overall "root" shard, along with platform support shards, GCC shards, an LLVM shard, Rust shards, etc... These are all embedded within the bundled [`Artifacts.toml` file](https://github.com/JuliaPackaging/BinaryBuilder.jl/blob/master/Artifacts.toml), and `BinaryBuilder.jl` downloads them on-demand as necessary, making use of the new [Pkg.Artifacts system](https://julialang.github.io/Pkg.jl/dev/artifacts/) within Julia 1.3+.

每个编译器“分片”都是单独打包的，这样用户就不必为了构建单个平台而下载多 GB 的压缩包。有一个总的“根”分片，以及平台支持分片、GCC 分片、LLVM 分片、Rust 分片等...这些都嵌入在捆绑的 [`Artifacts.toml` 文件](https://github.com/JuliaPackaging/BinaryBuilder.jl/blob/master/Artifacts.toml)，而 `BinaryBuilder.jl` 会按需下载它们，利用 Julia 1.3+ 的新 [Pkg.Artifacts 系统](https://julialang.github.io/Pkg.jl/dev/artifacts/)。


Each shard is made available both as an unpacked directory tree, and as a `.squashfs` image.  `.squashfs` images take up significantly less disk space, however they unfortunately require `root` privileges on the host machine, and only work on Linux.  This will hopefully be fixed in a future Linux kernel release, but if you have `sudo` privileges, it is often desirable to use the `.squashfs` files to save network bandwidth and disk space.  See the [Environment Variables](environment_variables.md) for instructions on how to do that.

每个分片都可以作为解压的目录树以及 `.squashfs` 图像使用。 `.squashfs` 图像占用的磁盘空间要少得多，但不幸的是，它们需要主机上的 `root` 权限，并且只能在 Linux 上运行。这有望在未来的 Linux 内核版本中得到修复，但如果您拥有 sudo 权限，通常需要使用 `.squashfs` 文件来节省网络带宽和磁盘空间。有关如何执行此操作的说明，请参阅 [环境变量](environment_variables.md)。


When launching a process within the RootFS image, `BinaryBuilder.jl` sets up a set of environment variables to enable a target-specific compiler toolchain, among other niceties.  See the [Build Tips](build_tips.md) doc page for more details on that, along with the `src/Runner.jl` file within this repository for the implementation.

在 RootFS 映像中启动进程时，`BinaryBuilder.jl` 会设置一组环境变量以启用特定于目标的编译器工具链，以及其他细节。有关更多详细信息，请参阅 [Build Tips](build_tips.md) 文档页面，以及本仓库的 `src/Runner.jl` 文件。

