# Antigravity Statusline Configuration

## 配置、skills 与插件的同步安装

本仓库可独立使用，安装不依赖其他配置仓库。需要 Python 3.11+、Git 和对应 CLI；OpenCode 依赖安装需要 npm。

```bash
# 仓库绝对路径执行；同步本机配置及 skills 到仓库
/path/to/antigravity-statusline-configuration/sync.sh

# 查看安装计划，不修改本机、不联网安装
/path/to/antigravity-statusline-configuration/install.sh --dry-run

# 安装配置、共享 skills 和插件
/path/to/antigravity-statusline-configuration/install.sh

# 仅部署仓库内文件，报告尚未恢复的插件与外部依赖
/path/to/antigravity-statusline-configuration/install.sh --offline
```

- `.harness.json` 声明本仓库的布局和默认同步范围；`scripts/harness.py` 随仓库分发，可独立运行。
- 原有全局指令、配置、状态栏和 hooks 保持各自布局；新增 `harness/shared/skills/` 保存共享 skills 及其配套资源。
- 安装将共享 skills 同时部署到 `~/.agents/skills/` 和 Antigravity 原生目录 `~/.gemini/config/skills/`，不依赖软链接或其他工具的插件缓存。
- `plugins.json` 记录可恢复的插件来源；有来源的插件通过真实 CLI 安装，插件附带的 skills 随插件恢复。
- 覆盖前备份到 `~/.harness-backups/<时间>/`；JSON 配置合并保留本机凭据，不清空用户技能或其他配置。
- 常见凭据字段不入库，拒绝沿目标软链接覆盖其他文件。skills 包保留原始内容，包括上游测试样例；提交前仍需检查自定义资源中的凭据。
- `--home /path/to/home` 可导出或安装到指定用户目录；正常目录软链接在导出时展开，运行时缓存、登录状态和会话不纳入同步。
- 同步采用增量覆盖，不自动删除仓库文件。第三方插件按市场当前版本恢复，不承诺锁定全部插件版本。缺少 CLI 或离线跳过的项目会逐项列出，安装失败返回非零状态。

CLI 配置部署到 `~/.gemini/antigravity-cli/`；`global/` 保存并部署 `~/.gemini/config/` 的全局指令、skills、agents、rules 和 workflows。状态栏 shebang 调整为安装时使用的 Python。插件通过 `agy plugin install <Git URL>` 恢复；历史 `plugins/` 目录仅作参考，不作为已安装状态。[Antigravity 插件文档](https://www.antigravity.google/docs/plugins?tab=cli)

验证：

```bash
python3 -B -m unittest discover -s /path/to/antigravity-statusline-configuration/tests -v
bash -n /path/to/antigravity-statusline-configuration/install.sh /path/to/antigravity-statusline-configuration/sync.sh
```


⚡ 高性能、高信息密度、环境自适应的 **Google Antigravity CLI** 状态栏（Statusline）生产级配置与脚本。

---

## ✨ 核心特性

- 🚀 **极致低延迟（~27ms - 35ms）**：
  - 纯物理级性能压榨，跳过环境管理器（如 mise/asdf/pyenv）的多层 Shim 寻址；
  - 极简化内建导入（冷启动导入仅 0.99ms），零 heavy package 依赖；
  - Git 脏状态（Dirty Check）全异步后台刷新 + 4s TTL 临时缓存，在大仓库（数万文件）中主线程耗时由 200ms+ 降低至 **< 1ms**。
- 🌿 **全场景 Git 上下文感知**：
  - 原生支持常规分支、Detached HEAD（自动截取前 7 位 commit hash）；
  - 支持复杂 Git 状态指示：变基中 `[rebase]`、合并冲突 `[merge]`、挑拣中 `[cherry-pick]` 以及未暂存标记 `*`；
  - 原生支持 **Git Worktree** 与 **Git Submodule**（自动解析 `gitdir: ` 指针路径）。
- 📊 **Token 上下文用量多维透视**：
  - 突破单一百分比展示，提供 `ctx: 92% (75k/1M)` 真实用量透视，一眼洞察单轮上下文吞吐与总量边界。
- 🤖 **后台任务感知**：
  - 自动检测并显示当前后台运行的 Agent/Subagent 任务数（如 `tasks:1`），任务结束自动静默消失。
- 📐 **智能路径收敛与弹性对齐**：
  - `smart_cwd`：Git 仓库内自动锚定 `仓库名/.../子目录`，非 Git 路径自动折叠 `$HOME` 为 `~`；
  - 左右两端对齐自适应：根据终端列宽弹性排版，窄屏/分屏模式下支持优雅降级折叠。

---

## 📸 显示效果样例

```text
git:main* ctx:92% (75k/1M) tasks:1                          my-awesome-repo
```

遇到复杂 Git 状态（如变基冲突）：
```text
git:3a5bc7d [rebase]* ctx:88% (120k/1M)                     my-awesome-repo
```

---

## 🚀 一键安装

克隆仓库后，用仓库的绝对路径执行 `install.sh --dry-run` 预览，再执行 `install.sh`。新安装流程见本文开头：部署配置、全局指令和 skills，备份覆盖文件，并通过 `agy` 恢复插件。脚本不会启动模型会话；状态栏渲染可用下方示例输入单独验证。

---

## ⚙️ 手动配置说明

如需手动配置，可在 `~/.gemini/antigravity-cli/settings.json` 中配置 `statusLine` 项：

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/your_user/.gemini/antigravity-cli/statusline.sh",
    "enabled": true,
    "stack_with_default": true
  }
}
```

### 配置项解析
| 参数 | 类型 | 说明 |
| :--- | :--- | :--- |
| `type` | `string` | 必须为 `"command"` |
| `command` | `string` | 状态栏脚本的绝对路径 |
| `enabled` | `boolean` | 是否启用状态栏 |
| `stack_with_default` | `boolean` | 是否与默认状态栏上下堆叠显示（建议设为 `true`） |

---

## 🛠️ 文件目录结构

```text
.
├── LICENSE                     # MIT 许可证
├── README.md                   # 详细使用与架构说明
├── install.sh                  # 一键部署与无缝升级脚本
├── GEMINI.md                   # 全局全栈工程规范与交付契约（命令安全、锁文件防线、Conventional Commits）
├── settings.json               # 生产环境配置（含权限、模型与状态栏挂载）
├── settings.json.example       # 配置示例参考
└── statusline.sh               # 状态栏核心脚本（Python 实现，~27ms 渲染）
```

---

## 📄 License

[MIT](LICENSE) © SuperWindcloud
