
# 包的构建技巧

BinaryBuilder 提供了一个方便的环境来实现跨平台构建。但是许多库都有复杂的构建脚本，可能需要进行调整以支持所有 BinaryBuilder 目标。

如果您的构建因某些错误而失败，请查看 [构建故障排除](@ref) 页面。

*如果您有其他技巧，请带着建议提交 PR。*

## 根据目标发起不同的 shell 命令

有时，您需要根据目标平台调整构建脚本。这可以在 shell 脚本中完成。这是来自 [`OpenBLAS`](https://github.com/JuliaPackaging/Yggdrasil/blob/685cdcec9f0f0a16f7b90a1671af88326dcf5ab1/O/OpenBLAS/build_tarballs.jl) 的示例：

```sh
# Set BINARY=32 on i686 platforms and armv7l
if [[ ${nbits} == 32 ]]; then
    flags="${flags} BINARY=32"
fi
```

以下是具有特定目标检查的脚本的其他示例：

* [Kaleido](https://github.com/JuliaPackaging/Yggdrasil/blob/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/K/Kaleido/build_tarballs.jl#L20-L25) - Windows 和 macOS 的不同步骤


* [Libical](https://github.com/JuliaPackaging/Yggdrasil/blob/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/L/Libical/build_tarballs.jl#L21-L25) - 32 位检查

通过为不同的目标集运行不同的构建脚本，也可以为每个目标运行完全不同的脚本。以下是 Windows 构建与其他目标分离的示例：

* [Git](https://github.com/JuliaPackaging/Yggdrasil/blob/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/G/Git/build_tarballs.jl#L22-L26)

## 自动配置构建

自动配置构建通常非常简单，下边是一个典型的方法：

```sh
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
```

以下是自动配置构建脚本的示例：


* [Patchelf](https://github.com/JuliaPackaging/Yggdrasil/blob/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/P/Patchelf/build_tarballs.jl#L18-L20)

* [LibCURL](https://github.com/JuliaPackaging/Yggdrasil/blob/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/L/LibCURL/build_tarballs.jl#L55-L57)

## CMake 构建

对于 CMake，向导将建议一个用于运行 CMake 的模板。典例如下：

```sh
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
```

工具链文件设置了几个 CMake 环境变量以提供更好的跨平台支持，例如 `CMAKE_SYSROOT`、`CMAKE_C_COMPILER` 等。包含 CMake 部分的构建示例包括：


* [JpegTurbo](https://github.com/JuliaPackaging/Yggdrasil/blob/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/J/JpegTurbo/build_tarballs.jl#L19-L21)

* [Sundials](https://github.com/JuliaPackaging/Yggdrasil/blob/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/S/Sundials/Sundials%405/build_tarballs.jl#L42-L55)

  - 对于 Windows 系统，需要将 *.dll 文件从 `${prefix}/lib` 复制到 `${libdir}`

  - 需要 `KLU_LIBRARY_DIR="$libdir"` 以便 CMake 的 `find_library` 可以从 KLU 中找到库


## Meson 构建

BinaryBuilder 还支持使用 Meson 进行构建。因为这将是一个交叉编译，你必须指定一个 Meson 交叉文件：

```sh
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release
```


使用 `meson` 配置项目后，您可以使用

```
ninja -j${nproc}
ninja install
```

如果 `meson.build` 文件存在，向导会自动建议使用 Meson。


使用 Meson 执行的构建示例包括：


* [gdk-pixbuf](https://github.com/JuliaPackaging/Yggdrasil/blob/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/G/gdk_pixbuf/build_tarballs.jl#L22-L35):

  meson 在这里使用依赖于平台的选项；


* [libepoxy](https://github.com/JuliaPackaging/Yggdrasil/blob/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/L/Libepoxy/build_tarballs.jl#L19-L25):

  该脚本修改 Meson 交叉文件中的 `c_args` 以添加包含目录；


* [xkbcommon](https://github.com/JuliaPackaging/Yggdrasil/blob/2f3638292c99fa6032634517f8a1aa8360d6fe8d/X/xkbcommon/build_tarballs.jl#L26-L30).

## Go 构建


可以通过将 `:go` 添加到 [`build_tarballs`](@ref) 的 `compilers` 关键字参数来请求 BinaryBuilder 提供的 Go 工具链：`compilers=[:c, :go]`。基于 Go 的包通常可以使用 `go` 构建和安装：

```sh
go build -o ${bindir}
```

BinaryBuilder 提供的 Go 工具链会自动选择合适的目标。

使用 Go 的包示例：

* [pprof](https://github.com/JuliaPackaging/Yggdrasil/blob/ea43d07d264046e8c94a460907bba209a015c10f/P/pprof/build_tarballs.jl#L21-L22)：它使用 `go build` 编译程序并手动移动可执行文件到 `${bindir}`。

## Rust 构建

可以通过将 `:rust` 添加到 [`build_tarballs`](@ref) 的 `compilers` 关键字参数来请求 BinaryBuilder 提供的 Rust 工具链：`compilers=[:c, :rust]`。基于 Rust 的包通常可以用 `cargo` 构建：

```sh
cargo build --release
```

BinaryBuilder 提供的 Rust 工具链会自动选择合适的目标和要使用的并行作业数。但是请注意，您可能必须在 `${prefix}` 中手动安装该产品。阅读包的安装说明，以防他们推荐不同的构建过程。

使用 Rust 的包示例：

* [Tokei](https://github.com/JuliaPackaging/Yggdrasil/blob/ea43d07d264046e8c94a460907bba209a015c10f/T/Tokei/build_tarballs.jl#L14-L15)：它使用 `cargo build` 编译程序并手动移动可执行文件到`${bindir}`;

* [Librsvg](https://github.com/JuliaPackaging/Yggdrasil/blob/ea43d07d264046e8c94a460907bba209a015c10f/L/Librsvg/build_tarballs.jl#L35-L45)：它使用基于 Autoconf 的构建系统，该系统将在内部调用“cargo build” , 但用户必须遵循 `./configure` + `make` + `make install` 顺序。

!!! 警告
  当前使用的 Rust 工具链不适用于 `i686-w64-mingw32`（32 位 Windows）平台。

## 在向导中编辑文件

在向导中，`vim` 编辑器可用于编辑文件。但是，它不会在构建脚本中留下任何记录。通常需要提供补丁文件或使用类似 `sed` 的东西。如果文件需要修补，我们建议使用 `git` 将整个工作树添加到新的存储库中，进行所需的更改，然后使用 `git diff -p` 输出一个补丁，该补丁可以包含在您的构建配方中。

你可以很容易地包含像补丁这样的本地文件，方法是将它们放在 `bundled/patches` 嵌套目录中，然后提供 `./bundled` 作为构建的 `sources` 之一。作为例子，参见 [`OpenBLAS`](https://github.com/JuliaPackaging/Yggdrasil/tree/8d5a27e24016c0ff2eae379f15dca17e79fd4be4/O/OpenBLAS/OpenBLAS%400.3.13)。

## 自动环境变量

以下环境变量在构建环境中自动设置，应该用于构建项目。有时，您可能需要调整它们（例如，[在 macOS 和 FreeBSD 上使用 GCC](@ref)）。

* `CC`: C 交叉编译器

* `CXX`: C++ 交叉编译器

* `FC`: Fortran 交叉编译器

上述变量指向目标环境的实用程序。要引用主机环境的实用程序，请在前面加上 `HOST` 或附加 `_HOST`。例如，`HOSTCC` 和 `CC_HOST` 指向本机 C 编译器。

这些是您可能偶尔需要在构建过程中设置的其他环境变量

* `CFLAGS`: C 编译器的选项

* `CXXFLAGS`：C++ 编译器的选项

* `CPPFLAGS`: C 预处理器的选项

* `LDFLAGS`：链接器的选项

* `PKG_CONFIG_PATH`：以冒号分隔的目录列表，用于搜索 `.pc` 文件

* `PKG_CONFIG_SYSROOT_DIR`：修改 `-I` 和 `-L` 以使用位于目标 sysroot 中的目录

以下变量可用于控制不同目标系统上的构建脚本，但不应由用户修改：

* `prefix`：所有产品应该安装的顶级目录的路径。这将是生成的压缩包的顶级目录

* `libdir`：应该安装共享库的目录路径。这是为 Windows 构建时的 `${prefix}/bin`，对于所有其他平台为 `${prefix}/lib`

* `bindir`：可执行文件安装目录的路径。这相当于 `${prefix}/bin`

* `includedir`：头文件安装目录的路径。这相当于 `${prefix}/include`

* 具有类似含义的类似变量存在于 `host` 前缀（其中安装了 [`HostBuildDependency`](@ref)）：`${host_prefix}`、`${host_bindir}`、`${host_libdir}`、` ${host_includedir}`

* `target`: 目标平台

* `bb_full_target`：完整的目标平台，包含诸如 libstdc++ 字符串 ABI 平台标签和 libgfortran 版本之类的东西

* `MACHTYPE`：主机平台的三元组

* `nproc`：主机的处理器数量，对并行构建很有用（例如，`make -j${nproc}`）

* `nbits`：目标架构的位数（通常为 32 或 64）

* `proc_family`：目标处理器系列（例如，“intel”、“power”或“arm”）

* `dlext`：目标系统上共享库的扩展。 Windows 为“dll”，macOS 为“dylib”，其他 Unix 系统为“so”

* `exeext`：目标系统上可执行文件的扩展名，拓展名需加上 `.`。对于 Windows 为“.exe”，对于所有其他目标平台为空字符串“”

* `SRC_NAME`: 正在构建的项目名称

## 在 macOS 和 FreeBSD 上使用 GCC

对于这些目标系统，Clang 是默认编译器，但是某些程序可能与 Clang 不兼容。

对于使用 CMake 构建的程序（请参阅 [CMake build](#CMake-builds-1) 部分），您可以使用位于 `${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake` 中的 GCC 工具链文件。

如果您要构建的项目使用 GNU 构建系统（也称为 Autotools），则不会自动切换为使用 GCC，但您必须设置适当的变量。例如，此设置可用于使用适用于 FreeBSD 和 macOS 的 GCC 构建大多数 C/C++ 程序：

```sh
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi
```


## 目标系统与主机系统的依赖关系
> 译注：这节与 [构建包](#building) 的 二进制依赖 一节对应。

BinaryBuilder 提供了一个交叉编译环境，这意味着通常目标平台（构建二进制文件最终将运行的地方）和主机平台（当前正在进行编译的地方）之间存在区别。特别是，在一般的构建环境中，您不能运行为目标平台构建的二进制可执行文件。

要使构建正常工作，可能存在不同类型的依赖关系，例如：

* 当前构建的最终产品（二进制可执行文件或其他库）需要链接到的二进制库。这些库必须是为目标平台构建的。您可以将此类依赖项安装为 [`Dependency`](@ref)，这也将是生成的 JLL 包的依赖项。这是最常见的依赖类；

* 二进制库或非二进制可执行文件（通常是实际上可以在构建环境中运行的 shell 脚本），用于构建过程中专门需要的目标平台，而不是构建的最终产品在目标系统上运行。您可以将此类依赖项安装为 [`BuildDependency`](@ref)。请记住，它们_不会_被添加为生成的 JLL 包的依赖项；

* 在构建过程中专门需要运行的二进制可执行文件。它们通常不能为目标平台构建，因此不能作为 `Dependency` 或 `BuildDependency` 安装。但是你有两个选择：

  * 如果它们在 `x86_64-linux-musl` 平台的 JLL 包中可用，您可以将它们安装为 [`HostBuildDependency`](@ref)。为了将目标平台的二进制文件与主机系统的二进制文件分开，这些依赖项将安装在 `${host_prefix}` 下，特别是可执行文件将出现在 `${host_bindir}` 下，它会自动添加到 ` ${PATH}` 环境变量；

  * 如果它们存在于 Alpine Linux 存储库中，您可以使用系统包管理器 [`apk`](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management) 安装它们。

  请记住，此类依赖项是为主机平台构建的：如果要为目标平台构建的库需要链接到另一个二进制库，将其安装为 `HostBuildDependency` 或 `apk` 将无济于事。

您需要了解要编译的包的构建过程，以便了解依赖项属于这些类中的哪些。


## 安装许可证文件

生成的压缩包应该带有您要安装库的许可证。如果在成功构建结束时，`${WORKSPACE}/srcdir` 中只有一个目录，BinaryBuilder 将在其中查找具有典型许可证名称的文件（如 `LICENSE`、`COPYRIGHT` 等一些扩展组合）并自动将它们安装到 `${prefix}/share/licenses/${SRC_NAME}/`。如果在最终的压缩包中，此目录中没有文件，则会发出警告，提醒您提供许可证文件。

如果许可证文件没有自动安装（例如，因为 `${WORKSPACE}/srcdir` 中有多个目录，或者因为文件名与预期模式不匹配），您必须手动安装该文件。在构建脚本中，您可以使用 `install_license` 命令。请参阅下面的 [构建环境中的实用程序](@ref utils_build_env) 部分。

## [构建环境中的实用程序](@id utils_build_env)


除了标准的 Unix 工具之外，在构建环境中还有 BinaryBuilder 提供的一些额外命令。以下是其中一些命令的列表：

* `atomic_patch`：应用补丁的实用程序。它类似于标准的 `patch`，但当无法应用补丁时它会优雅地失败：

  ```sh
  atomic_patch -p1 /path/to/file.patch
  ```

* `flagon`：将一些编译器标志转换为当前平台所需的实用程序。例如，要从静态存档构建共享库：

  ```sh
  cc -o "${libdir}/libfoo.${dlext}" -Wl,$(flagon --whole-archive) libfoo.a -Wl,$(flagon --no-whole-archive) -lm
  ```
  当前支持的标记为：

  * `--whole-archive`

  * `--no-whole-archive`

  * `--relative-rpath-link`

* `install_license`：将文件安装到 `${prefix}/share/licenses/${SRC_NAME}` 的实用程序：

  ```sh
  install_license ${WORKSPACE}/srcdir/THIS_IS_THE_LICENSE.md
  ```

* `update_configure_scripts`：更新自动配置脚本的实用程序。有时库会附带过时的自动配置脚本（例如，旧的 `configure.sub` 无法识别 `aarch64` 平台或使用 Musl C 库的系统）。只需运行

  ```sh
  update_configure_scripts
  ```

  获得更新的版本。使用 `--reconf` 标志，它还会在之后运行 `autoreconf -i -f`：

  ```sh
  update_configure_scripts --reconf
  ```