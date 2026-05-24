#!/usr/bin/env bash
# install_claude_code.sh — install the @anthropic-ai/claude-code CLI on the runner.
#
# Used by .github/workflows/claude_code_review.yml. Lighter than cursor-review's
# install script because Claude Code ships as a regular npm package — no extra
# checksum / mirror logic needed.
#
# Honors CLAUDE_CODE_VERSION env var (set via .github/claude-code-config.env)
# to pin a specific version. Defaults to "latest".

set -euo pipefail

PACKAGE="@anthropic-ai/claude-code"
VERSION="${CLAUDE_CODE_VERSION:-latest}"

if ! command -v npm >/dev/null 2>&1; then
  echo "::error::npm is required but not installed on this runner"
  exit 1
fi

echo "==> Installing ${PACKAGE}@${VERSION}"
npm install -g "${PACKAGE}@${VERSION}"

# npm global bin is on PATH for ubuntu-latest; verify the binary resolves
if ! command -v claude >/dev/null 2>&1; then
  NPM_BIN="$(npm config get prefix)/bin"
  echo "::warning::'claude' not on PATH after install; trying ${NPM_BIN}"
  echo "${NPM_BIN}" >> "${GITHUB_PATH:-/dev/null}"
  export PATH="${NPM_BIN}:${PATH}"
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "::error::'claude' command not found after npm install"
  exit 1
fi

echo "✓ Claude Code installed:"
claude --version || echo "(version check returned non-zero, but binary exists)"
