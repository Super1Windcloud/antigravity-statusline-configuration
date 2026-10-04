#!/opt/homebrew/bin/python3
"""Antigravity CLI custom statusline."""

import json
import os
import re
import sys
import time
import unicodedata

HOME = os.path.expanduser("~")
CONFIG_DIR = os.path.join(HOME, ".gemini", "antigravity-cli")
CONVERSATIONS = os.path.join(CONFIG_DIR, "conversations")
SETTINGS_PATH = os.path.join(CONFIG_DIR, "settings.json")

MODE_ALIASES = {
    "accept-edits": "accept-edits",
    "acceptedits": "accept-edits",
    "accept_edits": "accept-edits",
    "plan": "plan",
    "planning": "plan",
    "default": "default",
    "ask": "ask",
    "request-review": "review",
    "request_review": "review",
    "auto-approve": "auto",
    "auto": "auto",
}


def text(value):
    if value is None:
        return ""
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, (int, float, bool)):
        return str(value)
    return ""


def pick(data, *paths):
    for path in paths:
        cur = data
        ok = True
        for key in path.split("."):
            if isinstance(cur, dict) and key in cur:
                cur = cur[key]
            else:
                ok = False
                break
        if ok and cur not in (None, ""):
            return cur
    return None


def load_settings():
    try:
        with open(SETTINGS_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def as_pct(value):
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        number = float(value)
        if 0 <= number <= 1:
            number *= 100
        if number < 0:
            return None
        return int(round(number))
    if isinstance(value, str):
        stripped = value.strip().rstrip("%")
        try:
            return as_pct(float(stripped))
        except ValueError:
            return None
    if isinstance(value, dict):
        for key in (
            "remaining_percentage",
            "remaining_percent",
            "remaining_fraction",
            "remaining",
            "percent",
            "pct",
        ):
            if key in value and value[key] not in (None, ""):
                pct = as_pct(value[key])
                if pct is not None:
                    return pct
    return None


def to_fraction(value):
    if isinstance(value, bool) or value in (None, ""):
        return None
    if isinstance(value, str):
        stripped = value.strip().rstrip("%")
        try:
            value = float(stripped)
        except ValueError:
            return None
    if isinstance(value, (int, float)):
        number = float(value)
        if 0 <= number <= 1:
            return number
        if 0 <= number <= 100:
            return number / 100.0
    return None


def pct_label(fraction):
    if fraction is None:
        return ""
    fraction = max(0.0, min(1.0, fraction))
    return str(int(round(fraction * 100)))


def token_number(value):
    if isinstance(value, bool) or value in (None, ""):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value.strip())
        except ValueError:
            return None
    return None


def format_tokens(n):
    if n is None or n < 0:
        return ""
    if n >= 1_000_000:
        val = n / 1_000_000
        return f"{val:.1f}M".replace(".0M", "M")
    if n >= 1_000:
        val = n / 1_000
        return f"{val:.0f}k" if val >= 10 else f"{val:.1f}k".replace(".0k", "k")
    return str(int(n))


def context_info(data):
    window = pick(data, "context_window")
    if not isinstance(window, dict):
        window = {}
    remaining = to_fraction(
        window.get("remaining_percentage")
        if window.get("remaining_percentage") not in (None, "")
        else window.get("remaining_fraction")
        if window.get("remaining_fraction") not in (None, "")
        else window.get("remaining")
    )
    size = token_number(window.get("context_window_size") or window.get("size"))
    used_tokens = token_number(window.get("total_input_tokens"))
    output_tokens = token_number(window.get("total_output_tokens"))
    if used_tokens is None:
        usage = window.get("current_usage")
        if isinstance(usage, dict):
            used_tokens = token_number(usage.get("input_tokens")) or 0
            output_tokens = token_number(usage.get("output_tokens")) or 0
            used_tokens = used_tokens + output_tokens
    elif output_tokens is not None:
        used_tokens = used_tokens + output_tokens

    if remaining is None:
        used = to_fraction(
            window.get("used_percentage")
            if window.get("used_percentage") not in (None, "")
            else window.get("used_fraction")
            if window.get("used_fraction") not in (None, "")
            else window.get("used")
        )
        if used is not None:
            remaining = 1.0 - used
        elif size and size > 0 and used_tokens is not None:
            remaining = max(0.0, 1.0 - (used_tokens / size))

    pct_str = pct_label(remaining) or "100"
    tok_detail = ""
    if used_tokens and used_tokens > 0:
        used_str = format_tokens(used_tokens)
        if size and size > 0:
            tok_detail = f"{used_str}/{format_tokens(size)}"
        else:
            tok_detail = used_str

    return pct_str, tok_detail


def remaining_pct(data):
    pct_str, _ = context_info(data)
    return pct_str



def quota_bucket_fraction(bucket):
    if bucket is None:
        return None
    if not isinstance(bucket, dict):
        return to_fraction(bucket)
    remaining = to_fraction(
        bucket.get("remaining_fraction")
        if bucket.get("remaining_fraction") not in (None, "")
        else bucket.get("remaining_percentage")
        if bucket.get("remaining_percentage") not in (None, "")
        else bucket.get("remaining_percent")
        if bucket.get("remaining_percent") not in (None, "")
        else bucket.get("remaining")
    )
    if remaining is not None:
        return remaining
    used = to_fraction(
        bucket.get("used_fraction")
        if bucket.get("used_fraction") not in (None, "")
        else bucket.get("used_percentage")
        if bucket.get("used_percentage") not in (None, "")
        else bucket.get("used")
    )
    if used is not None:
        return 1.0 - used
    return None


def quota_pct(data):
    quota = pick(data, "quota")
    if quota is None:
        return ""
    if not isinstance(quota, dict):
        return pct_label(to_fraction(quota))
    direct_keys = {
        "remaining_percentage",
        "remaining_percent",
        "remaining_fraction",
        "remaining",
        "used_percentage",
        "used_fraction",
        "used",
    }
    if any(key in quota for key in direct_keys):
        labeled = pct_label(quota_bucket_fraction(quota))
        if labeled:
            return labeled
    fractions = []
    for key, bucket in quota.items():
        if key in direct_keys:
            continue
        fraction = quota_bucket_fraction(bucket)
        if fraction is not None:
            fractions.append(fraction)
    if not fractions:
        return ""
    return pct_label(min(fractions))


def cost_text(value):
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, dict):
        inner = value.get("estimated")
        if inner is None:
            inner = value.get("total_cost_usd")
        if inner is None:
            inner = value.get("total_usd")
        if inner is None:
            inner = value.get("total")
        if isinstance(inner, (int, float, str)):
            return str(inner)
    return ""


def number_text(value):
    if isinstance(value, bool):
        return ""
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if value.is_integer():
            return str(int(value))
        return f"{value:.2f}".rstrip("0").rstrip(".")
    if isinstance(value, str):
        stripped = value.strip()
        if stripped:
            return stripped
    if isinstance(value, dict):
        for key in (
            "remaining",
            "remaining_credits",
            "available",
            "available_credits",
            "amount",
            "total",
        ):
            if key in value:
                inner = number_text(value[key])
                if inner:
                    return inner
    return ""


def credits_text(data, settings):
    value = pick(
        data,
        "credits",
        "remaining_credits",
        "quota.remaining_credits",
        "quota.credits",
        "current_usage.remaining_credits",
        "current_usage.credits",
    )
    amount = number_text(value)
    if not amount:
        return ""
    use_g1 = settings.get("useG1Credits")
    if use_g1 is None:
        use_g1 = pick(data, "useG1Credits", "use_g1_credits")
    prefix = "g1:" if use_g1 else "cr:"
    return prefix + amount


def mode_text(data, settings):
    value = pick(
        data,
        "execution_mode",
        "agentMode",
        "agent_mode",
        "permission_mode",
        "mode",
    )
    if value is None:
        value = settings.get("agentMode")
    raw = text(value).lower().replace(" ", "-")
    if not raw:
        return ""
    return MODE_ALIASES.get(raw, raw)


def effort_text(data):
    value = pick(data, "effort", "model.effort", "current_usage.effort")
    raw = text(value).lower()
    if not raw:
        return ""
    return raw


def sandbox_on(value):
    if value in (True, 1, "1", "true", "True", "on", "enabled", "sandbox"):
        return True
    if value in (False, 0, "0", "false", "False", "off", "disabled"):
        return False
    if isinstance(value, dict):
        for key in ("enabled", "on", "active", "is_enabled"):
            if key in value:
                return sandbox_on(value[key])
        mode = text(value.get("mode")).lower()
        if mode:
            return sandbox_on(mode)
    return False


def sandbox_text(data, settings):
    value = pick(data, "sandbox", "sandboxMode", "sandbox_mode")
    if value is None:
        value = settings.get("enableTerminalSandbox")
        if value is None:
            value = settings.get("sandboxMode")
    return "sandbox" if sandbox_on(value) else ""


def subagent_count(value):
    if isinstance(value, bool):
        return 0
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, list):
        return len(value)
    if isinstance(value, dict):
        for key in ("count", "active", "running", "length"):
            if isinstance(value.get(key), (int, float)):
                return int(value[key])
        return len(value)
    return 0


def subagents_text(data):
    value = pick(data, "subagents", "subagent_count", "current_usage.subagents")
    count = subagent_count(value)
    if count <= 0:
        return ""
    return f"agents:{count}"


def background_tasks_text(data):
    value = pick(
        data,
        "tasks",
        "tasks_count",
        "background_tasks",
        "running_tasks",
        "active_tasks",
        "current_usage.tasks",
    )
    count = subagent_count(value)
    if count <= 0:
        return ""
    return f"tasks:{count}"



def vim_text(data):
    value = pick(data, "vim")
    if value in (None, False, "", {}):
        return ""
    if isinstance(value, str):
        mode = value.strip()
        return f"vim:{mode}" if mode else "vim"
    if isinstance(value, dict):
        enabled = value.get("enabled")
        mode = text(value.get("mode") or value.get("display") or value.get("status"))
        if enabled is False and not mode:
            return ""
        if mode:
            return f"vim:{mode}"
        if enabled:
            return "vim"
    return ""


def smart_cwd(cwd, git_root=None):
    if not cwd:
        return ""
    home = str(HOME)
    path = os.path.abspath(cwd)
    if path == home:
        return "~"
    if git_root and path.startswith(git_root):
        repo_name = os.path.basename(git_root)
        if path == git_root:
            return repo_name
        rel = os.path.relpath(path, git_root)
        parts = [p for p in rel.split(os.sep) if p]
        if len(parts) <= 2:
            return f"{repo_name}/{rel}"
        return f"{repo_name}/…/{parts[-1]}"
    if path.startswith(home + "/"):
        rel = "~/" + path[len(home) + 1:]
    else:
        rel = path
    parts = [p for p in rel.split("/") if p]
    if len(parts) <= 3:
        return rel
    return f"~/…/{parts[-2]}/{parts[-1]}"


def truncate_cwd(cwd):
    return smart_cwd(cwd)


def basename_cwd(cwd):
    if not cwd:
        return ""
    home = str(HOME)
    path = cwd.rstrip("/") or cwd
    if path == home:
        return "~"
    parts = [p for p in path.split("/") if p != ""]
    return parts[-1] if parts else path


def git_info(cwd):
    if not cwd or not os.path.isdir(cwd):
        return "", ""
    cur = os.path.abspath(cwd)
    git_dir = None
    git_root = None
    for _ in range(8):
        check_path = os.path.join(cur, ".git")
        if os.path.isdir(check_path):
            git_dir = check_path
            git_root = cur
            break
        elif os.path.isfile(check_path):
            try:
                with open(check_path, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read().strip()
                if content.startswith("gitdir:"):
                    real_git = content[7:].strip()
                    if not os.path.isabs(real_git):
                        real_git = os.path.normpath(os.path.join(cur, real_git))
                    git_dir = real_git
                    git_root = cur
                    break
            except Exception:
                pass
        parent = os.path.dirname(cur)
        if parent == cur:
            break
        cur = parent

    if not git_dir:
        return "", ""

    branch = ""
    head_file = os.path.join(git_dir, "HEAD")
    if os.path.isfile(head_file):
        try:
            with open(head_file, "r", encoding="utf-8", errors="ignore") as f:
                c = f.read().strip()
            if c.startswith("ref: refs/heads/"):
                branch = c[16:]
            elif c:
                branch = c[:7]
        except Exception:
            pass

    if not branch:
        try:
            import subprocess
            out = subprocess.check_output(
                ["git", "-c", "gc.auto=0", "rev-parse", "--abbrev-ref", "HEAD"],
                cwd=cwd,
                stderr=subprocess.DEVNULL,
                timeout=0.08,
            )
            branch = out.decode("utf-8", "replace").strip()
        except Exception:
            pass

    if not branch:
        return "", git_root

    state = ""
    if os.path.isdir(os.path.join(git_dir, "rebase-merge")) or os.path.isdir(os.path.join(git_dir, "rebase-apply")):
        state = "[rebase]"
    elif os.path.isfile(os.path.join(git_dir, "MERGE_HEAD")):
        state = "[merge]"
    elif os.path.isfile(os.path.join(git_dir, "CHERRY_PICK_HEAD")):
        state = "[cherry-pick]"

    # Non-blocking async cached dirty check
    dirty = ""
    try:
        h = abs(hash(git_root)) % 1000000
        cache_file = f"/tmp/agy_git_{h}.cache"
        now = time.time()
        cache_mtime = 0
        if os.path.isfile(cache_file):
            try:
                with open(cache_file, "r") as cf:
                    parts = cf.read().split(":")
                    if len(parts) == 2:
                        cache_mtime = float(parts[0])
                        dirty = parts[1]
            except Exception:
                pass

        if now - cache_mtime > 4.0:
            import subprocess
            updater = (
                f"import time, subprocess;"
                f"res = subprocess.run(['git', '-c', 'gc.auto=0', '-C', '{cwd}', 'diff-files', '--quiet'], "
                f"stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL);"
                f"d = '*' if res.returncode != 0 else '';"
                f"open('{cache_file}', 'w').write(f'{{time.time()}}:{{d}}')"
            )
            subprocess.Popen(["python3", "-c", updater], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    full_branch = f"{branch}{dirty}{state}"
    return full_branch, git_root


def git_branch(cwd):
    b, _ = git_info(cwd)
    return b



def fmt_duration(seconds, running=False):
    if running or seconds is None or seconds < 0:
        return ""
    total = int(round(seconds))
    if total < 1:
        return "took:0s"
    hours, rem = divmod(total, 3600)
    minutes, secs = divmod(rem, 60)
    if hours:
        text_value = f"{hours}h{minutes:02d}m"
    elif minutes:
        text_value = f"{minutes}m{secs:02d}s"
    else:
        text_value = f"{secs}s"
    return "took:" + text_value


def ms_to_seconds(value):
    if isinstance(value, (int, float)) and value >= 0:
        return value / 1000.0
    return None


def duration_from_json(data):
    running = False
    value = pick(
        data,
        "last_turn.duration_ms",
        "last_turn.elapsed_ms",
        "turn.duration_ms",
        "current_usage.duration_ms",
        "cost.total_duration_ms",
        "duration_ms",
        "elapsed_ms",
    )
    seconds = ms_to_seconds(value)
    started = pick(data, "turn.started_at_ms", "current_usage.started_at_ms")
    ended = pick(data, "turn.ended_at_ms", "current_usage.ended_at_ms")
    if seconds is None and isinstance(started, (int, float)):
        end = ended if isinstance(ended, (int, float)) else time.time() * 1000
        seconds = max(0.0, (end - started) / 1000.0)
        running = ended is None
    if seconds is None:
        return ""
    return fmt_duration(seconds, running=running)


def decode_varint(buf, index):
    result = 0
    shift = 0
    while index < len(buf):
        byte = buf[index]
        index += 1
        result |= (byte & 0x7F) << shift
        if byte < 0x80:
            return result, index
        shift += 7
        if shift > 70:
            break
    return None, index


def walk_fields(buf):
    import struct
    index = 0
    fields = []
    length = len(buf)
    while index < length:
        key, index = decode_varint(buf, index)
        if key is None:
            break
        field_no = key >> 3
        wire = key & 7
        if wire == 0:
            value, index = decode_varint(buf, index)
            if value is None:
                break
            fields.append((field_no, value, None))
        elif wire == 1:
            if index + 8 > length:
                break
            value = struct.unpack_from("<Q", buf, index)[0]
            index += 8
            fields.append((field_no, value, None))
        elif wire == 2:
            size, index = decode_varint(buf, index)
            if size is None or index + size > length:
                break
            fields.append((field_no, None, buf[index:index + size]))
            index += size
        elif wire == 5:
            if index + 4 > length:
                break
            value = struct.unpack_from("<I", buf, index)[0]
            index += 4
            fields.append((field_no, value, None))
        else:
            break
    return fields


def proto_timestamp(raw):
    if not raw:
        return None
    seconds = None
    nanos = 0
    for field_no, value, blob in walk_fields(raw):
        if field_no == 1 and value is not None:
            seconds = value
        elif field_no == 2 and value is not None:
            nanos = value
    if seconds is None:
        return None
    if 1577836800 <= seconds <= 1893456000:
        return seconds + nanos / 1e9
    return None


def step_times(metadata):
    if not metadata:
        return None, None
    created = None
    ended = None
    for field_no, _value, blob in walk_fields(metadata):
        ts = proto_timestamp(blob)
        if ts is None:
            continue
        if field_no == 1:
            created = ts
        elif field_no in (7, 8, 32):
            ended = ts if ended is None else max(ended, ts)
    return created, ended


def duration_from_conversation(session_id):
    if not session_id:
        return ""
    db_path = os.path.join(CONVERSATIONS, f"{session_id}.db")
    if not os.path.isfile(db_path):
        return ""
    try:
        import sqlite3
        conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True, timeout=0.05)
        try:
            # Fast index query: only fetch the last user step and the last step
            row_user = conn.execute(
                "select idx, metadata from steps where step_type = 14 order by idx desc limit 1"
            ).fetchone()
            if not row_user:
                return ""
            user_idx, user_meta = row_user
            user_start, _ = step_times(user_meta)
            if user_start is None:
                return ""

            row_last = conn.execute(
                "select status, metadata from steps where idx >= ? order by idx desc limit 1",
                (user_idx,),
            ).fetchone()
            if not row_last:
                return ""
            last_status, last_meta = row_last
            created, ended = step_times(last_meta)
            last_end = ended if ended is not None else created
        finally:
            conn.close()
    except Exception:
        return ""

    running = last_status not in (3, 4, 5)
    end = time.time() if running or last_end is None else last_end
    return fmt_duration(end - user_start, running=running)


def ansi(code, value):
    return f"\033[{code}m{value}\033[0m" if value else ""


def quota_color(pct_text):
    try:
        pct = int(pct_text)
    except ValueError:
        return "2"
    if pct <= 10:
        return "1;31"
    if pct <= 30:
        return "1;33"
    return "2"


def visible_width(s):
    if not s:
        return 0
    clean = re.sub(r"\x1b\[[0-9;]*[a-zA-Z]", "", s)
    width = 0
    for ch in clean:
        if unicodedata.east_asian_width(ch) in ("F", "W"):
            width += 2
        else:
            width += 1
    return width


def get_terminal_width(data):
    for key in (
        "terminal_width",
        "terminalWidth",
        "columns",
        "width",
        "terminal_columns",
    ):
        val = data.get(key)
        if isinstance(val, (int, float)) and val > 0:
            return int(val)
        if isinstance(val, str) and val.strip().isdigit() and int(val.strip()) > 0:
            return int(val.strip())
    try:
        col = int(os.environ.get("COLUMNS", ""))
        if col > 0:
            return col
    except (KeyError, ValueError):
        pass
    try:
        col = os.get_terminal_size(1).columns
        if col > 0:
            return col
    except Exception:
        pass
    try:
        col = os.get_terminal_size(2).columns
        if col > 0:
            return col
    except Exception:
        pass
    try:
        with open("/dev/tty") as tty:
            col = os.get_terminal_size(tty.fileno()).columns
            if col > 0:
                return col
    except Exception:
        pass
    return 0


def align_statusline(left_str, right_str, term_width, fallback_right_str=None):
    if not right_str:
        return left_str
    if not left_str:
        if term_width > 0:
            gap = term_width - visible_width(right_str)
            if gap > 0:
                return (" " * gap) + right_str
        return right_str

    w_left = visible_width(left_str)
    w_right = visible_width(right_str)

    if term_width > 0:
        gap = term_width - w_left - w_right
        if gap >= 1:
            return f"{left_str}{' ' * gap}{right_str}"
        if fallback_right_str and fallback_right_str != right_str:
            w_fb = visible_width(fallback_right_str)
            gap_fb = term_width - w_left - w_fb
            if gap_fb >= 1:
                return f"{left_str}{' ' * gap_fb}{fallback_right_str}"

    return f"{left_str} {right_str}"


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        data = {}
    if not isinstance(data, dict):
        data = {}

    settings = load_settings()
    status_line_cfg = settings.get("statusLine")
    if not isinstance(status_line_cfg, dict):
        status_line_cfg = {}
    is_stacked = pick(data, "stack_with_default", "statusLine.stack_with_default")
    if is_stacked is None:
        is_stacked = status_line_cfg.get("stack_with_default", False)
    is_stacked = bool(is_stacked)

    model = pick(data, "model")
    if isinstance(model, dict):
        model = pick(model, "display_name") or pick(model, "display") or pick(model, "id")
    model = text(model)

    cwd = text(pick(data, "cwd", "workspace.current_dir", "workspace.project_dir"))
    if not cwd:
        try:
            cwd = os.getcwd()
        except Exception:
            cwd = ""
    title = text(pick(data, "conversation_title"))
    quota = quota_pct(data)
    credits = credits_text(data, settings)
    mode = mode_text(data, settings)
    effort = effort_text(data)
    sandbox = sandbox_text(data, settings)
    agents = subagents_text(data)
    vim = vim_text(data)
    cost = cost_text(pick(data, "cost"))
    duration = duration_from_json(data)
    if not duration:
        session_id = text(
            pick(data, "session_id", "conversation_id", "conversation.id")
        )
        duration = duration_from_conversation(session_id)

    left_parts = []
    branch, git_root = git_info(cwd)
    if branch:
        left_parts.append(ansi("1;35", f"git:{branch}"))
    if title:
        left_parts.append(ansi("1;33", title))
    if not is_stacked and model:
        left_parts.append(ansi("2", model))

    ctx_pct, ctx_tok = context_info(data)
    ctx_label = f"ctx:{ctx_pct}%"
    if ctx_tok:
        ctx_label += f" ({ctx_tok})"
    left_parts.append(ansi(quota_color(ctx_pct), ctx_label))
    if quota:
        left_parts.append(ansi(quota_color(quota), f"quota:{quota}%"))
    if credits:
        left_parts.append(ansi("2", credits))
    if not is_stacked:
        if mode:
            mode_code = "1;33" if mode == "plan" else "1;36"
            left_parts.append(ansi(mode_code, mode))
        if effort:
            left_parts.append(ansi("2", effort))
    if sandbox:
        left_parts.append(ansi("1;32", sandbox))
    tasks = background_tasks_text(data)
    if tasks:
        left_parts.append(ansi("1;36", tasks))
    if agents:
        left_parts.append(ansi("1;35", agents))
    if vim:
        left_parts.append(ansi("1;35", vim))
    if duration:
        left_parts.append(ansi("1;32", duration))
    if cost:
        left_parts.append(ansi("2", f"${cost}"))

    left_str = " ".join(left_parts)

    dir_part = smart_cwd(cwd, git_root=git_root)
    right_str = ansi("1;36", dir_part) if dir_part else ""
    fb_dir = basename_cwd(cwd)
    fallback_right_str = ansi("1;36", fb_dir) if fb_dir else ""

    term_width = get_terminal_width(data)
    line = align_statusline(
        left_str,
        right_str,
        term_width,
        fallback_right_str=fallback_right_str,
    )
    sys.stdout.write(line + "\n")


if __name__ == "__main__":
    main()
