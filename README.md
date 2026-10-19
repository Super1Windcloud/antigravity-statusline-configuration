# Antigravity Statusline Configuration

## 配置同步与 Testkit 安装

本仓库独立使用；技能范围仅为 [Testkit](https://github.com/winhok/testkit)。需要 Python 3.11+、Git 和 Antigravity CLI；OpenCode 依赖安装另需 npm。

```bash
/path/to/antigravity-statusline-configuration/sync.sh
/path/to/antigravity-statusline-configuration/install.sh --dry-run
/path/to/antigravity-statusline-configuration/install.sh
/path/to/antigravity-statusline-configuration/install.sh --offline
```

- `sync.sh` 同步原有全局指令、配置、状态栏和 hooks，跳过本机所有 skills 目录。
- `plugins.json` 仅保留 Testkit 插件及来源。Antigravity 的安装入口仅恢复 Testkit skills，不安装其他技能插件。
- GitHub 不保存本机 skills 副本、系统 skills、其他 skills 的脚本或素材；`.gitignore` 阻止这些目录再次入库。本机已有的其他 skills 不会被卸载。
- Claude Code 使用 `claude plugin install testkit@testkit`；Antigravity 使用 `agy plugin install https://github.com/winhok/testkit.git`；OpenCode 从清单固定的 Git commit 拉取 Testkit，部署到原生 `skills/<name>/SKILL.md`。
- 旧版 `plugins/` 下的登记文件只作历史参考，不参与自动安装；安装来源以根目录 `plugins.json` 为准。旧清单中的其他插件也会被安装脚本忽略。
- 覆盖前备份到 `~/.harness-backups/<时间>/`，JSON 配置合并保留本机凭据；`--home /path/to/home` 指定导出或安装目录。
- 常见凭据字段会过滤，登录状态、会话、运行时缓存不入库；提交前仍需审查自定义配置。
- `--dry-run` 不修改本机、不联网安装；`--offline` 仅部署配置，报告尚未恢复的 Testkit 和依赖。缺少 CLI 会报告跳过项，安装失败返回非零状态。

验证：`python3 -B -m unittest discover -s /path/to/antigravity-statusline-configuration/tests -v`。

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
