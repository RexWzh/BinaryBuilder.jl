using Documenter, BinaryBuilder, BinaryBuilderBase

en_pages = [
    "Home" => "index.md",
    "Building Packages" => "building.md",
    "Build Tips" => "build_tips.md",
    "JLL packages" => "jll.md",
    "FAQ" => "FAQ.md",
    "Build Troubleshooting" => "troubleshooting.md",
    "Internals" => [
        "RootFS" => "rootfs.md",
        "Environment Variables" => "environment_variables.md",
        "Tricksy Gotchas" => "tricksy_gotchas.md",
        "Reference" => "reference.md",
    ],
]

zh_pages = [
    "主页" => "src_zh/index.md",
    "构建包" => "src_zh/building.md",
    "包的构建技巧" => "src_zh/build_tips.md",
    "JLL 包" => "src_zh/jll.md",
    "常见问题" => "src_zh/FAQ.md",
    "构建故障排除" => "src_zh/troubleshooting.md",
    "内部" => [
        "根文件系统" => "src_zh/rootfs.md",
        "环境变量" => "src_zh/environment_variables.md",
        "棘手的问题" => "src_zh/tricksy_gotchas.md",
        "参考 API" => "src_zh/reference.md",
    ],
]

mix_pages = [
    "主页" => "src_mix/index.md",
    "构建包" => "src_mix/building.md",
    "包的构建技巧" => "src_mix/build_tips.md",
    "JLL 包" => "src_mix/jll.md",
    "常见问题" => "src_mix/FAQ.md",
    "构建故障排除" => "src_mix/troubleshooting.md",
    "内部" => [
        "根文件系统" => "src_mix/rootfs.md",
        "环境变量" => "src_mix/environment_variables.md",
        "棘手的问题" => "src_mix/tricksy_gotchas.md",
        "参考 API" => "src_mix/reference.md",
    ],
]

makedocs(
    modules = [BinaryBuilder],
    sitename = "BinaryBuilder.jl",
    pages = [
        "English" => en_pages,
        # "简体中文" => zh_pages,
        "English & 简体中文" => mix_pages,
    ],
    strict = true,
)

deploydocs(
    repo = "github.com/RexWzh/BinaryBuilder.jl.git",
)
