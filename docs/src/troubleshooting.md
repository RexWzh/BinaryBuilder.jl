
# 构建故障排除

此页面收集了一些已知的构建错误并介绍了如何修复它们。

*如果您有其他提示，请提交带有建议的 PR。*


## 所有平台

### 常见留言

虽然在下面您会找到一些关于在 BinaryBuilder 中构建包时发现的常见问题的提示，但请记住，如果在构建过程中出现问题，没有修复它的灵丹妙药：您需要了解问题所在。大多数时候，这是一个反复试验的问题。最好的建议是访问构建环境并仔细阅读构建系统生成的日志文件：构建系统在屏幕上打印误导性错误消息的情况并不少见，而实际问题可能完全不同（例如“不能找到库 XYZ ”，而问题是他们运行查找库 XYZ 的命令，但由于不相关的原因而失败，例如检查中使用了错误的编译器标志）。了解构建系统正在做什么也将非常有用。

欢迎向 [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil/) 提出未能成功构建的配方的 PR，或在 [JuliaLang Slack] 的“#binarybuilder”频道中寻求帮助](https://julialang.org/slack/)。有人可能会在他们有空的时候帮助你，比如志愿者提供的任何支持。

### 如何检索正在进行的构建脚本

如果基于向导的构建在第一个平台目标之后失败，向导可能偶尔会退出而无法恢复（因为唯一的恢复模式是重试失败的平台）。在这种情况下，可以使用以下步骤检索上次构建状态和正在进行的构建脚本：

```
state = BinaryBuilder.Wizard.load_wizard_state() # select 'resume'
BinaryBuilder.Wizard.print_build_tarballs(stdout, state)
```

然后可以根据需要编辑构建脚本——例如禁用失败的平台——并直接使用 `julia build_tarballs.jl --debug --verbose` 重新运行（参见[手动构建文档](https://docs.binarybuilder.org/dev/#Manually-create-or-edit-build_tarballs.jl)) 调试和完成*无需*从头开始。

### 找不到依赖的头文件

有时构建系统找不到依赖项的头文件，即使它们已正确安装。发生这种情况时，您必须指明 C/C++ 预处理器文件的位置。

例如，如果项目使用 Autotools，您可以设置 `CPPFLAGS` 环境变量：

```sh
export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nprocs}
make install
```

作为例子，参见 [Cairo](https://github.com/JuliaPackaging/Yggdrasil/blob/9a1ae803823e0dba7628bc71ff794d0c79e39c95/C/Cairo/build_tarballs.jl#L16-L17) 的构建脚本。

相反，如果项目使用 CMake，您将需要使用不同的环境变量，因为 CMake 会忽略 `CPPFLAGS`。如果找不到头文件的编译器是C编译器，则需要将路径添加到 `CFLAGS` 变量（例如，`CFLAGS="-I${includedir}"`），如果这是一个 C++ 版本，你必须设置 `CXXFLAGS` 变量（例如，`CXXFLAGS="-I${includedir}"`）。

### 找不到依赖库

就像在上面的部分中一样，构建系统可能无法找到依赖项的库，即使它们安装在正确的位置，即 `${libdir}` 目录中。在这些情况下，您必须通过传递选项 `-L${libdir}` 来通知链接器库的位置。如何做到这一点的细节取决于所使用的特定构建系统。

对于基于 Autotools 和 CMake 的构建，您可以设置 `LDFLAGS` 环境变量：

```sh
export LDFLAGS="-L${libdir}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nprocs}
make install
```

作为例子，参见 [libwebp](https://github.com/JuliaPackaging/Yggdrasil/blob/dd1d1d0fbe6fee41806691e11b900961f9001a81/L/libwebp/build_tarballs.jl#L19-L21) 构建脚本（在这种情况下，只有在为 FreeBSD 构建时才需要） .

### 旧的 Autoconf 帮助脚本

使用 Autoconf 的软件包带有一些帮助脚本——比如 `config.sub` 和 `config.guess` —— 上游开发人员需要保持最新以便获得最新的改进。一些软件包提供了这些脚本的非常旧的副本，例如会导致不知道 Musl C 库。在这种情况下，在运行 `./configure` 之后你可能会得到类似这样的错误

```
checking build system type... Invalid configuration `x86_64-linux-musl': system `musl' not recognized
configure: error: /bin/sh ./config.sub x86_64-linux-musl failed
```

`BinaryBuilder` 环境提供实用程序 [`update_configure_scripts`](@ref utils_build_env) 来自动更新这些脚本，在执行 `./configure` 之前调用它：

```sh
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
```

### 使用旧的 GCC 版本构建一个库，该库具有使用较新的 GCC 版本构建的依赖项

`build_tarballs` 函数的关键字参数 `preferred_gcc_version` 允许您在需要时选择更新的编译器来构建库。纯 C 库具有良好的兼容性，因此使用较新编译器构建的库应该能够在使用较旧 GCC 版本的系统上运行而不会出现问题。但是，请记住，`BinaryBuilder.jl` 中的每个 GCC 版本都捆绑了特定版本的 binutils——它提供了 `ld` 链接器——请参阅[此表](https://github.com/JuliaPackaging/Yggdrasil/blob/master/RootFS.md#compiler-shards)。


`ld` 非常挑剔，该工具的给定版本不喜欢与被链接较新版本的库进行链接：这意味着如果您使用 GCC v6 构建库，则需要构建所有库 GCC >= v6 取决于它。如果你不这样做，你会得到这样一个神秘的错误：

```
/opt/x86_64-linux-gnu/bin/../lib/gcc/x86_64-linux-gnu/4.8.5/../../../../x86_64-linux-gnu/bin/ld: /workspace/destdir/lib/libvpx.a(vp8_cx_iface.c.o): unrecognized relocation (0x2a) in section `.text'
/opt/x86_64-linux-gnu/bin/../lib/gcc/x86_64-linux-gnu/4.8.5/../../../../x86_64-linux-gnu/bin/ld: final link failed: Bad value
```

解决方案是至少使用依赖项使用的最大 GCC 版本构建下游库：

```julia
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
```

例如，FFMPEG [必须使用 GCC v8 构建](https://github.com/JuliaPackaging/Yggdrasil/blob/9a1ae803823e0dba7628bc71ff794d0c79e39c95/F/FFMPEG/build_tarballs.jl#L140) 因为 LibVPX [需要 GCC v8](https://github.com/giordano/Yggdrasil/blob/2b13acd75081bc8105685602fcad175296264243/L/LibVPX/build_tarballs.jl)。

一般来说，我们会尝试使用尽可能旧的 GCC 版本（v4.8.5 是当前可用的最旧版本）来构建，以获得最大的兼容性。

### 运行外部可执行文件

`BinaryBuilder` 提供的构建环境是 `x86_64-linux-musl`，它可以运行以下平台的可执行文件：`x86_64-linux-musl`、`x86_64-linux-gnu`、`i686-linux-gnu` `。对于所有其他平台，如果构建系统尝试运行外部可执行文件，您将收到错误消息，通常类似于

```
./foreign.exe: line 1: ELF��
                       @@xG@8@@@@@@���@�@@����A�A����A�A���@�@: not found
./foreign.exe: line 1: syntax error: unexpected end of file (expecting ")")
```

这是交叉编译时最糟糕的情况之一，并且没有简单的解决方案。您必须查看构建过程以查看是否可以跳过运行可执行文件（例如，参见 [Yggdrasil#351](https://github.com/JuliaPackaging/Yggdrasil/pull/351)), 或者用别的东西代替。如果可执行文件是仅编译时实用程序，请尝试使用本机编译器构建它（例如，请参阅 [Yggdrasil#351](https://github.com/JuliaPackaging/Yggdrasil) 中用于构建本机 `mkdefs` 的补丁）

## Musl Linux

### `posix_memalign` 定义错误

为 Musl 平台编译有时会失败并显示错误消息

```
/opt/x86_64-linux-musl/x86_64-linux-musl/sys-root/usr/include/stdlib.h:99:5: error: from previous declaration ‘int posix_memalign(void**, size_t, size_t)’
 int posix_memalign (void **, size_t, size_t);
     ^
```

这是由于旧版本的 GCC 中针对此 libc 的错误，请参阅 [BinaryBuilder.jl#387](https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/387) 了解更多详细信息。

有两种选择可以解决此问题：

* 通过使用 `build_tarballs(...; preferred_gcc_version=v"6")` 需要 GCC 6。在某些情况下，这可能是最简单的选择。作为例子，参见 [Yggdrasil#3974](https://github.com/JuliaPackaging/Yggdrasil/pull/3974)。

* 如果使用旧版本的 GCC 对于更广泛的兼容性很重要，您可以应用 [此补丁](https://github.com/JuliaPackaging/Yggdrasil/blob/48ac662cd53e02aff0189c81008874a04f7172c7/Z/ZeroMQ/bundled/patches/mm_malloc.patch) 到构建工具链。作为例子，参见 [ZeroMQ](https://github.com/JuliaPackaging/Yggdrasil/blob/48ac662cd53e02aff0189c81008874a04f7172c7/Z/ZeroMQ/build_tarballs.jl#L20-L26) 的配方。

## PowerPC Linux

### 未构建共享库

有时候 `powerpc64le-linux-gnu` 的共享库编译成功后没有建好，审计失败，因为只编译了静态库。如果构建使用 Autotools，这很可能会发生，因为 `configure` 脚本是使用非常旧版本的 Autotools 生成的，它不知道如何为该系统构建共享库。这里的技巧是使用 `autoreconf` 重新生成 `configure` 脚本：

```sh
autoreconf -vi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
```

作为例子，参见 [Giflib](https://github.com/JuliaPackaging/Yggdrasil/blob/78fb3a7b4d00f3bc7fd2b1bcd24e96d6f31d6c4b/G/Giflib/build_tarballs.jl) 的构建器。如果您需要重新生成 `configure`，您可能需要运行 [`update_configure_scripts`](@ref utils_build_env) 以使其他平台也能正常工作。

## FreeBSD

### ```undefined reference to `backtrace_symbols'```

如果因为以下错误导致编译失败

```
undefined reference to `backtrace_symbols'
undefined reference to `backtrace'
```

那么你需要链接到 `execinfo`：

```sh
if [[ "${target}" == *-freebsd* ]]; then
    export LDFLAGS="-lexecinfo"
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nprocs}
make install
```

例子参见 [Yggdrasil#354](https://github.com/JuliaPackaging/Yggdrasil/pull/354) 和 [Yggdrasil#982](https://github.com/JuliaPackaging/Yggdrasil/pull/982)。

### ```undefined reference to `environ'```

此问题是由 `-Wl,--no-undefined` 标志引起的。如果未定义的引用一起出现，删除此标志也可以解决上述回溯问题。

## Windows

### 由于未定义的符号，Libtool 拒绝构建共享库

在为 Windows 构建时，有时 libtool 会因为未定义的符号而拒绝构建共享库。发生这种情况时，编译成功但 BinaryBuilder 的审计无法找到预期的 `LibraryProduct`。

在编译日志中，您通常可以找到类似的消息

```
libtool: warning: undefined symbols not allowed in i686-w64-mingw32 shared libraries; building static only
```

或者

```
libtool: error: can't build i686-w64-mingw32 shared library unless -no-undefined is specified
```

在这些情况下，您必须将 `-no-undefined` 选项传递给链接器，如第二条消息明确建议的那样。

正确的修复需要将 `-no-undefined` 标志添加到 `Makefile.am` 文件中相应 libtool 存档的 `LDFLAGS`。作为解决方案的例子，参考 [`CALCEPH`](https://github.com/JuliaPackaging/Yggdrasil/blob/d1e5159beef7fcf8c631e893f62925ca5bd54bec/C/CALCEPH/build_tarballs.jl#L19)、[`ERFA`](https://github.com/JuliaPackaging/Yggdrasil/blob/d1e5159beef7fcf8c631e893f62925ca5bd54bec/E/ERFA/build_tarballs.jl#L17) 和 [`libsharp2`](https://github.com/JuliaPackaging/Yggdrasil/blob/d1e5159beef7fcf8c631e893f62925ca5bd54bec/L/libsharp2/build_tarballs.jl#L19)。

修补 `Makefile.am` 文件的一种快速的替代方法是仅将 `LDFLAGS=-no-undefined` 传递给 `make`：

```sh
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(LDFLAGS="-no-undefined")
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nprocs} "${FLAGS[@]}"
make install
```

请注意，在 `./configure` 之前设置 `LDFLAGS=-no-undefined` 会使此操作失败，因为它会运行类似 `cc -no-undefined conftest.c` 的命令，这会扰乱编译器）。例子参见 [Yggdrasil#170](https://github.com/JuliaPackaging/Yggdrasil/pull/170)、[Yggdrasil#354](https://github.com/JuliaPackaging/Yggdrasil/pull/354)。

### Libtool 拒绝构建共享库，因为 `-lmingw32` 不是真实文件

如果您看到类似以下的错误：

```
[14:12:52] *** Warning: linker path does not have real file for library -lmingw32.
[14:12:52] *** I have the capability to make that library automatically link in when
[14:12:52] *** you link to this library.  But I can only do this if you have a
[14:12:52] *** shared version of the library, which you do not appear to have
[14:12:52] *** because I did check the linker path looking for a file starting
[14:12:52] *** with libmingw32 and none of the candidates passed a file format test
[14:12:52] *** using a file magic. Last file checked: /opt/x86_64-w64-mingw32/x86_64-w64-mingw32/sys-root/lib/libmingw32.a
```

这是 autoconf 的 AC_F77_LIBRARY_LDFLAGS（或 AC_FC_LIBRARY_LDFLAGS）宏中的错误。已提交补丁以修复此上游。

同时，您可以删除这些宏。它们通常不是必需的。


## 苹果系统

### CMake 抛出 “No known for CXX compiler”

例如，错误消息如下：

```
CMake Error in CMakeLists.txt:
  No known features for CXX compiler

  "Clang"

  version 12.0.0.
```

此问题是由于未设置 CMake 策略 CMP0025 引起的。该策略仅影响 AppleClang 的 CompilerId，但它还有关闭上游 clang 的特征检测的效果（这是我们正在使用的）作用在 CMake 3.18 之前的 CMake 版本。在项目定义之前（或获取 CMake 的更新版本），将

```
cmake_policy(SET CMP0025 NEW)
```

添加在 CMakeLists.txt 的最顶部。

