# 影 / YING — 中英双语版源码与素材包

这是本地 zero-shadow 项目的源码快照，未修改原始项目文件。

## 内容
- Godot 工程 project.godot、场景、GDScript 脚本、着色器与自动加载脚本。
- assets/ 下的全部现有素材，包括被 .gitignore 忽略但已存在的素材。
- 剧情 data/story.xml、中英翻译 data/i18n.json、字体及许可说明。
- 导出配置、Web 加载页面、测试、项目文档、素材来源与锁定清单。
- 现有 inputs/ 输入文件及 site/ 文件也已保留。
- SOURCE_MANIFEST.json 记录原始文件路径、字节数及 SHA-256，用于完整性核对。

## 打开方式
解压后，用兼容本项目的 Godot 4.7 打开 zero-shadow/project.godot。
首次导入时，Godot 会重新生成 .godot/ 缓存。源码包不是可直接双击运行的发行版。
项目的 npm 命令依赖 Manus Game Runtime（GAME_RUNTIME）；该平台运行时不属于本项目源码，未复制到包中。直接编辑 Godot 工程不需要打包携带该运行时。

## 排除内容
未包含 .godot/、Git/Manus 本地状态与历史、日志目录、.work/ 临时工作区、node_modules/、dist/ 等构建目录以及 outputs/。未包含本地环境机密配置。
原 README 中部分段落为历史说明，请以当前工程配置及 README 顶部双语说明为准。
