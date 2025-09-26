#!/usr/bin/env bash
set -euo pipefail

# Installer for Claude Code Switch (CCS)
# - Writes a ccs() function into your shell rc so that `ccs kimi` works directly
# - Does NOT rely on modifying PATH or copying binaries
# - Idempotent: will replace previous CCS function block if exists

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/ccs.sh"
BEGIN_MARK="# >>> ccs function begin >>>"
END_MARK="# <<< ccs function end <<<"

# Detect which rc file to modify (prefer zsh)
detect_rc_file() {
  local shell_name
  shell_name="${SHELL##*/}"
  case "$shell_name" in
    zsh)
      echo "$HOME/.zshrc"
      ;;
    bash)
      echo "$HOME/.bashrc"
      ;;
    *)
      # Fallback to zshrc
      echo "$HOME/.zshrc"
      ;;
  esac
}

remove_existing_block() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  if grep -qF "$BEGIN_MARK" "$rc"; then
    # Remove the existing block between markers (inclusive)
    local tmp
    tmp="$(mktemp)"
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
      $0==b {inblock=1; next}
      $0==e {inblock=0; next}
      !inblock {print}
    ' "$rc" > "$tmp" && mv "$tmp" "$rc"
  fi
}

append_function_block() {
  local rc="$1"
  mkdir -p "$(dirname "$rc")"
  [[ -f "$rc" ]] || touch "$rc"
  cat >> "$rc" <<EOF
$BEGIN_MARK
# CCS: define a shell function that applies exports to current shell
ccs() {
  local script="$SCRIPT_PATH"
  if [[ ! -f "\$script" ]]; then
    echo "ccs error: script not found at \$script" >&2
    return 1
  fi
  case "\$1" in
    ""|"help"|"-h"|"--help"|"status"|"st"|"config"|"cfg"|"stats"|"rotate"|"test-keys")
      "\$script" "\$@"
      ;;
    *)
      eval "\$("\$script" "\$@")"
      ;;
  esac
}
$END_MARK
EOF
}

main() {
  if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "Error: ccs.sh not found next to install.sh: $SCRIPT_PATH" >&2
    exit 1
  fi
  chmod +x "$SCRIPT_PATH"

  local rc
  rc="$(detect_rc_file)"
  remove_existing_block "$rc"
  append_function_block "$rc"

  echo "✅ Installed ccs function into: $rc"
  echo "   Reload your shell or run: source $rc"
  echo "   Then use: ccs kimi  (or: ccs ds / ccs qwen / ccs glm / ccs claude / ccs opus)"
}

main "$@"
