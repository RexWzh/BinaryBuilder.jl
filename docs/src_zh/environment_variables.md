# 环境变量

`BinaryBuilder.jl` 支持多个环境变量来全局修改其行为：

* `BINARYBUILDER_AUTOMATIC_APPLE`：当设置为 `true` 时，这会自动同意 Apple macOS SDK 许可协议，从而能够为 macOS 系统构建二进制对象。

`BINARYBUILDER_USE_SQUASHFS`：当设置为 `true` 时，这将使用 `.squashfs` 图像而不是压缩包来下载交叉编译器碎片。这占用的磁盘空间明显减少，下载大小也略有减少，但需要在本地机器上使用 sudo 来挂载 `.squashfs` 图像。这是使用“特权”运行程序时的默认设置。

* `BINARYBUILDER_RUNNER`：设置为运行器字符串时，会更改 `BinaryBuilder.jl` 将用于将构建过程包装在沙箱中的执行引擎。有效值为 `"userns"`、`"privileged"` 和 `"docker"` 中的一个。如果未给出，`BinaryBuilder.jl` 将尽力猜测。

`BINARYBUILDER_ALLOW_ECRYPTFS`：当设置为 `true` 时，这允许从加密挂载中挂载 rootfs/shard/workspace 目录。这是默认禁用的，因为在撰写本文时，这会触发内核错误。为避免在主目录已加密的系统上出现这些内核错误，请将 `BINARYBUILDER_ROOTFS_DIR` 和 `BINARYBUILDER_SHARDS_DIR` 环境变量设置为加密主目录之外的路径。

* `BINARYBUILDER_USE_CCACHE`：当设置为 `true` 时，这会导致在构建环境中安装 `/root/.ccache` 卷，并且 `CC`、`CXX` 和 `FC` 环境变量具有 ` ccache` 放在它们前面。这可以显着加快同一主机上同一包的重建。请注意，默认情况下，`ccache` 将存储 5G 的缓存数据。

* `BINARYBUILDER_NPROC`：覆盖构建期间设置的环境变量 `${nproc}` 的值，请参阅[自动环境变量](@ref)。

