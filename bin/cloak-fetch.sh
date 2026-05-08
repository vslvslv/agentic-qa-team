#!/usr/bin/env bash
# Fetch URL text content via CloakBrowser (stealth Chromium, 49 C++ anti-bot patches).
# Replaces WebFetch in skills that hit permission prompts on source verification.
# Usage: cloak-fetch.sh <url> [max_chars]
#        Exit 0 + text on success; exit 1 + empty stdout on failure.

set -euo pipefail

URL="${1:?Usage: cloak-fetch.sh <url> [max_chars]}"
MAX_CHARS="${2:-3000}"

# Auto-install cloakbrowser if absent (silent)
python3 -c "import cloakbrowser" 2>/dev/null \
  || CLOAKBROWSER_AUTO_UPDATE=0 pip install -q cloakbrowser

CLOAKBROWSER_AUTO_UPDATE=0 python3 - "$URL" "$MAX_CHARS" <<'PYEOF'
import sys
from cloakbrowser import launch

url      = sys.argv[1]
max_chars = int(sys.argv[2])

browser = launch(headless=True)
try:
    page = browser.new_page()
    page.goto(url, wait_until="domcontentloaded", timeout=10000)
    text = page.inner_text("body")
    print(text[:max_chars])
except Exception as e:
    print(f"CLOAK_FETCH_ERROR: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    browser.close()
PYEOF
