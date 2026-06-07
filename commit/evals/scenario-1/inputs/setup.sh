#!/usr/bin/env bash
set -e

git init sdk
cd sdk
git config user.email "dev@example.com"
git config user.name "Dev"

mkdir -p src tests

cat > src/auth.py << 'PYEOF'
def authenticate(token):
    """Authenticate with the API using a token."""
    return {"token": token, "region": "us-east-1"}
PYEOF

cat > tests/test_auth.py << 'PYEOF'
from src.auth import authenticate

def test_authenticate():
    result = authenticate("mytoken")
    assert result["token"] == "mytoken"
PYEOF

git add .
git commit -m "feat: add authentication module"

# Breaking change: require explicit region parameter
cat > src/auth.py << 'PYEOF'
def authenticate(token, region):
    """Authenticate with the API using a token and explicit region.

    Args:
        token: API token string
        region: AWS region identifier (e.g. 'us-east-1', 'eu-west-1')

    BREAKING CHANGE: region parameter is now required.
    """
    return {"token": token, "region": region}
PYEOF

cat > tests/test_auth.py << 'PYEOF'
from src.auth import authenticate

def test_authenticate():
    result = authenticate("mytoken", "us-east-1")
    assert result["token"] == "mytoken"
    assert result["region"] == "us-east-1"

def test_authenticate_eu():
    result = authenticate("mytoken", "eu-west-1")
    assert result["region"] == "eu-west-1"
PYEOF

echo "Done. Breaking changes are unstaged in sdk/"
