#!/usr/bin/env bash
set -euo pipefail

BASE="http://localhost:8080"
LATEST="${LATEST_K8S_VERSION}"
OLDER="${OLDER_K8S_VERSION}"
FAIL=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1 — $2"; FAIL=1; }
check()        { [[ "$3" == *"$2"* ]] && pass "$1" || fail "$1" "expected '$2' in: $3"; }
check_absent() { [[ "$3" != *"$2"* ]] && pass "$1" || fail "$1" "'$2' should be absent in: $3"; }

# 1 — /docs/latest/ returns 200 (no redirect)
s=$(curl -si -H "Host: www.kubernetools.com" "$BASE/docs/latest/" | head -1)
check "1: /docs/latest/ → 200" "200" "$s"

# 2 — /docs/latest/ has no Location header
h=$(curl -si -H "Host: www.kubernetools.com" "$BASE/docs/latest/")
check_absent "2: /docs/latest/ → no Location header" "Location:" "$h"

# 3 — sub-path rewrite works under /docs/latest/
s=$(curl -si -H "Host: www.kubernetools.com" "$BASE/docs/latest/core/v1/pod/" | head -1)
check "3: /docs/latest/core/v1/pod/ → 200" "200" "$s"

# 4 — latest versioned path gets X-Robots-Tag: noindex
h=$(curl -sI -H "Host: www.kubernetools.com" "$BASE/docs/$LATEST/")
check "4: /docs/$LATEST/ → X-Robots-Tag: noindex" "noindex" "$h"

if [[ "$OLDER" != "$LATEST" ]]; then
  # 5 — older versioned path returns 200
  s=$(curl -si -H "Host: www.kubernetools.com" "$BASE/docs/$OLDER/" | head -1)
  check "5: /docs/$OLDER/ → 200" "200" "$s"

  # 6 — older versioned path gets X-Robots-Tag: noindex
  h=$(curl -sI -H "Host: www.kubernetools.com" "$BASE/docs/$OLDER/")
  check "6: /docs/$OLDER/ → X-Robots-Tag: noindex" "noindex" "$h"

  # 7 — sub-path on older version returns 200
  s=$(curl -si -H "Host: www.kubernetools.com" "$BASE/docs/$OLDER/core/v1/pod/" | head -1)
  check "7: /docs/$OLDER/core/v1/pod/ → 200" "200" "$s"

  # 8 — older versioned path has correct Cache-Control
  h=$(curl -sI -H "Host: www.kubernetools.com" "$BASE/docs/$OLDER/")
  check "8: /docs/$OLDER/ → Cache-Control: max-age=86400" "max-age=86400" "$h"
else
  echo "SKIP: 5, 6, 7, 8 — only one version in site, older == latest"
fi

# 9 — /docs/latest/ has no X-Robots-Tag (not a versioned path)
h=$(curl -sI -H "Host: www.kubernetools.com" "$BASE/docs/latest/")
check_absent "9: /docs/latest/ → no X-Robots-Tag" "X-Robots-Tag" "$h"

# 10 — /docs/latest/ has Cache-Control: max-age=86400
h=$(curl -sI -H "Host: www.kubernetools.com" "$BASE/docs/latest/")
check "10: /docs/latest/ → Cache-Control: max-age=86400" "max-age=86400" "$h"

# 11 — latest versioned path has Cache-Control: max-age=86400
h=$(curl -sI -H "Host: www.kubernetools.com" "$BASE/docs/$LATEST/")
check "11: /docs/$LATEST/ → Cache-Control: max-age=86400" "max-age=86400" "$h"

# 12 — bare domain returns 301
s=$(curl -si -H "Host: kubernetools.com" "$BASE/" | head -1)
check "12: kubernetools.com → 301" "301" "$s"

# 13 — bare domain redirects to https://www.kubernetools.com/
h=$(curl -si -H "Host: kubernetools.com" "$BASE/")
check "13: kubernetools.com → Location: https://www.kubernetools.com/" "https://www.kubernetools.com/" "$h"

exit $FAIL
