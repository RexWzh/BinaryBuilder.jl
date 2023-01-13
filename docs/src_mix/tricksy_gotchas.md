
# Tricksy Gotchas
# 棘手的问题

There are a plethora of gotchas when it comes to binary compilation and distribution that must be appropriately addressed, or the binaries will only work on certain machines and not others.  Here is an incomplete list of things that `BinaryBuilder.jl` takes care of for you:

在遇到二进制编译和分发方面时，存在大量问题需进行适当处理，否则二进制文件只能在某些机器上运行，而不能在其他机器上运行。以下是 `BinaryBuilder.jl` 为您处理的事情的不完整列表：


* Uniform compiler interface

* 统一的编译器接口


No need to worry about invoking compilers through weird names; just run `gcc` within the proper environment and you'll get the appropriate cross-compiler.  Triplet-prefixed names (such as `x86_64-linux-gnu-gcc`) are, of course, also available, and the same version of `gcc`, `g++` and `gfortran` is used across all platforms.

不用担心通过奇怪的名字调用编译器；只需在适当的环境中运行 `gcc`，您就会得到适当的交叉编译器。三元组前缀名称（例如 `x86_64-linux-gnu-gcc`）当然也可用，并且所有平台都使用相同版本的 `gcc`、`g++` 和 `gfortran`。


* `glibc` versioning

* `glibc` 版本控制


On Linux platforms that use `glibc` as the C runtime library (at the time of writing, this is the great majority of most desktop and server distros), it is necessary to compile code against a version of `glibc` that is _older_ than any glibc version it will be run on.  E.g. if your code is compiled against `glibc v2.5`, it will run on `glibc v2.6`, but it will not run on `glibc v2.4`.  Therefore, to maximize compatibility, all code should be compiled against as old a version of `glibc` as possible.

在使用 `glibc` 作为 C 运行库的 Linux 平台上（在撰写本文时，这是绝大多数桌面和服务器发行版的情况），有必要针对比起将要运行的 `glibc` 版本更 _旧_ 的版本编译代码。例如，如果您的代码是针对 `glibc v2.5` 编译的，它将在 `glibc v2.6` 上运行，但不会在 `glibc v2.4` 上运行。因此，为了最大限度地提高兼容性，所有代码都应尽可能针对旧版本的 `glibc` 进行编译。


* `gfortran` versioning

* `gfortran` 版本控制


When compiling FORTRAN code, the `gfortran` compiler has broken ABI compatibility in the 6.X -> 7.X transition, and the 7.X -> 8.X transition.  This means that code built with `gfortran` 6.X cannot be linked against code built with `gfortran` 7.X.  We therefore compile all `gfortran` code against multiple different `gfortran` versions, then at runtime decide which to download based upon the currently running process' existing linkage.

编译 FORTRAN 代码时，`gfortran` 编译器破坏了 6.X -> 7.X 转换和 7.X -> 8.X 转换中的 ABI 兼容性。这意味着使用 `gfortran` 6.X 构建的代码不能与使用 `gfortran` 7.X 构建的代码链接。因此，我们针对多个不同的 `gfortran` 版本编译所有 `gfortran` 代码，然后在运行时根据当前运行进程的现有链接决定下载哪个。


* `cxx11` string ABI

* `cxx11` 字符串 ABI


When switching from the `cxx03` standard to `cxx11` in GCC 5, the internal layout of `std::string` objects changed.  This causes incompatibility between C++ code passing strings back and forth across the public interface if they are not built with the same C++ string ABI.  We therefore detect when `std::string` objects are being passed around, and warn that you need to build two different versions, one with `cxx03`-style strings (doable by setting `-D_GLIBCXX_USE_CXX11_ABI=0` for newer GCC versions) and one with `cxx11`-style strings.

在 GCC 5 中从“cxx03”标准切换到“cxx11”时，“std::string”对象的内部布局发生了变化。如果 C++ 代码不是使用相同的 C++ 字符串 ABI 构建的，这会导致在公共接口上来回传递字符串的 C++ 代码之间不兼容。因此，我们检测 std::string 对象何时被传递，并警告您需要构建两个不同的版本，一个具有 cxx03 样式的字符串（通过为较新的 GCC 版本设置 -D_GLIBCXX_USE_CXX11_ABI=0 来实现）和一个带有 `cxx11` 风格的字符串。


* Library Dependencies

* 库依赖


A large source of problems in binary distribution is improper library linkage.  When building a binary object that depends upon another binary object, some operating systems (such as macOS) bake the absolute path to the dependee library into the dependent, whereas others rely on the library being present within a default search path.  `BinaryBuilder.jl` takes care of this by automatically discovering these errors and fixing them by using the `RPATH`/`RUNPATH` semantics of whichever platform it is targeting.  Note that this is technically a build system error, and although we will fix it automatically, it will raise a nice yellow warning during build prefix audit time.

二进制分发中的一大问题是不正确的库链接。在构建依赖于另一个二进制对象的二进制对象时，一些操作系统（例如 macOS）将依赖库的绝对路径烘焙到依赖项中，而其他操作系统依赖于存在于默认搜索路径中的库。 `BinaryBuilder.jl` 通过自动发现这些错误并使用其目标平台的 `RPATH`/`RUNPATH` 语义修复它们来解决这个问题。请注意，这在技术上是一个构建系统错误，虽然我们会自动修复它，但它会在构建前缀审核期间发出一个很好的黄色警告。


* Embedded absolute paths

* 嵌入式绝对路径


Similar to library dependencies, plain files (and even symlinks) can have the absolute location of files embedded within them.  `BinaryBuilder.jl` will automatically transform symlinks to files within the build prefix to be the equivalent relative path, and will alert you if any files within the prefix contain absolute paths to the build prefix within them.  While the latter cannot be automatically fixed, it may help in tracking down problems with the software later on.

与库依赖项类似，普通文件（甚至符号链接）可以在其中嵌入文件的绝对位置。 `BinaryBuilder.jl` 会自动将构建前缀内文件的符号链接转换为等效的相对路径，如果前缀内的任何文件包含指向构建前缀的绝对路径，则会提醒您。虽然后者不能自动修复，但它可能有助于以后跟踪软件问题。


* Instruction Set Differences

* 指令集差异


When compiling for architectures that have evolved over time (such as `x86_64`), it is important to target the correct instruction set, otherwise a binary may contain instructions that will run on the computer it was compiled on, but will fail rather ungracefully when run on a machine that does not have as new a processor.  `BinaryBuilder.jl` will automatically disassemble every built binary object and inspect the instructions used, warning the user if a binary is found that does not conform to the agreed-upon minimum instruction set architecture.  It will also notice if the binary contains a `cpuid` instruction, which is a good sign that the binary is aware of this issue and will internally switch itself to use only available instructions.

在为随着时间的推移而发展的体系结构（例如“x86_64”）进行编译时，以正确的指令集为目标很重要，否则二进制文件可能包含将在其编译所在的计算机上运行的指令，但在以下情况下会相当不正常地失败在没有新处理器的机器上运行。 `BinaryBuilder.jl` 将自动反汇编每个构建的二进制对象并检查所使用的指令，如果发现二进制文件不符合商定的最小指令集架构，则会警告用户。它还会注意到二进制文件是否包含“cpuid”指令，这是二进制文件意识到此问题并将在内部切换为仅使用可用指令的好兆头。

