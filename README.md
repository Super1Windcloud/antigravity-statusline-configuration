# Antigravity Statusline Configuration

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

克隆仓库并执行安装脚本：

```bash
git clone git@github.com:Super1Windcloud/antigravity-statusline-configuration.git
cd antigravity-statusline-configuration
./install.sh
```

安装脚本将自动执行以下操作：
1. 探测宿主机最快、最直接的 `python3` 可执行环境；
2. 自动备份现存的 `~/.gemini/antigravity-cli/statusline.sh`；
3. 将优化版脚本部署至 `~/.gemini/antigravity-cli/statusline.sh` 并赋予执行权限；
4. 安全注入配置到 `~/.gemini/antigravity-cli/settings.json`（保留所有其他设置不变）；
5. 自动运行 Smoke Test 验证状态栏渲染与耗时。

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
├── settings.json.example       # 配置示例参考
└── statusline.sh               # 状态栏核心脚本（Python 实现，~27ms 渲染）
```

---

## 📄 License

[MIT](LICENSE) © SuperWindcloud
