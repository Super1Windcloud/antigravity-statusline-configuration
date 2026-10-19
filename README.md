# Antigravity Statusline Configuration

安装与同步仅操作 `~/.gemini/antigravity-cli/` 和 `~/.gemini/config/`，不读写其他 agent 或 `~/.agents/` 的配置。`--only` 仅接受本仓库所属 agent，跨 agent 参数会在执行前报错；`--repo` 不会扩大范围。 Testkit 运行环境独立存放于 `~/.local/share/harness-testkit/antigravity/`；系统工具仍复用本机安装。

## Testkit 完整依赖与 Figma 安装

本仓库可独立部署 Antigravity。默认一并安装 Testkit 完整 skills、Python/移动端/浏览器/性能/视频/逆向工具依赖，并同步 Figma 插件安装来源。需要 Python 3.11+、Git；macOS 系统包通过已有 Homebrew 补齐。core/full 均需要 Node 24+、npm 10+，缺少时尝试由 Homebrew 准备。

```bash
~/super/antigravity-statusline-configuration/sync.sh
~/super/antigravity-statusline-configuration/install.sh --dry-run
~/super/antigravity-statusline-configuration/install.sh
~/super/antigravity-statusline-configuration/install.sh --dependencies core
~/super/antigravity-statusline-configuration/install.sh --offline
```

- 普通安装默认 `--dependencies full`；core 仅准备核心 Python 和 mobile-mcp；none 跳过运行环境/MCP 构建。
- 默认安装并登记 mobile-mcp，full 另含 Playwright MCP；使用 SDK 和独立运行目录的实际路径，不只复制 JSON。
- 插件安装允许列表为 Testkit、Figma；其他本机 skills 不同步到 GitHub，也不卸载。插件缓存、依赖缓存和登录凭据不入库。
- 运行环境位于 `~/.local/share/harness-testkit/antigravity/`；全局指令会补充 `source .../env.sh` 的使用约定。
- 覆盖前备份；保留原有设置、凭据与其他 MCP。`--dry-run` 无写入和下载；`--offline` 不联网安装，只部署配置并报告待安装项。
- Xcode、设备信任、SDK 许可、WDA 签名、Midscene 模型凭据和 Figma OAuth 仍需本机准备，安装失败会返回非零状态。

详见 [完整依赖与 MCP 配置](runtime/README.md)、[实际验证范围](VALIDATION.md)。验证命令：`python3 -B -m unittest discover -s ~/super/antigravity-statusline-configuration/tests -v`。

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
