#!/usr/bin/env bash
set -e

git init linted-project
cd linted-project
git config user.email "dev@example.com"
git config user.name "Dev"

mkdir -p src .git/hooks

cat > src/calculator.py << 'PYEOF'
def add(a, b):
    return a + b

def subtract(a, b):
    return a - b
PYEOF

git add .
git commit -m "feat: add calculator module"

# Install a pre-commit hook that rejects trailing whitespace
cat > .git/hooks/pre-commit << 'HOOKEOF'
#!/usr/bin/env bash
# Reject commits if any staged Python file has trailing whitespace
files=$(git diff --cached --name-only | grep '\.py$')
if [ -n "$files" ]; then
    if echo "$files" | xargs grep -lP '\s+$' 2>/dev/null; then
        echo "ERROR: Trailing whitespace found in staged Python files. Please fix before committing."
        exit 1
    fi
fi
exit 0
HOOKEOF
chmod +x .git/hooks/pre-commit

# Write new version of calculator with trailing whitespace (added via printf)
printf 'def add(a, b):\n    return a + b\n\ndef subtract(a, b):\n    return a - b\n\ndef multiply(a, b):   \n    return a * b\n' > src/calculator.py

echo "Done. src/calculator.py has trailing whitespace and is unstaged in linted-project/"
