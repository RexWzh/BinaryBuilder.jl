using Documenter, BinaryBuilder, BinaryBuilderBase

makedocs(
    modules = [BinaryBuilder],
    sitename = "BinaryBuilder.jl",
    pages = [
        "主页" => "index.md",
        "构建包" => "building.md",
        "包的构建技巧" => "build_tips.md",
        "JLL 包" => "jll.md",
        "常见问题" => "FAQ.md",
        "构建故障排除" => "troubleshooting.md",
        "内部" => [
            "根文件系统" => "rootfs.md",
            "环境变量" => "environment_variables.md",
            "棘手的问题" => "tricksy_gotchas.md",
            "引用" => "reference.md",
        ],
    ],
    # strict = true,
)

deploydocs(
    repo = "github.com/RexWzh/BinaryBuilder.jl.git",
    # push_preview = true,
    versions = ["Chinese" => "v0.0.3"]
)
