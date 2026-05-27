# GitHub Branch Protection — instelling via API

# Gebruik: bash github-branch-protection.sh
# Vereiste omgevingsvariabelen:
#   GITHUB_TOKEN  — Personal Access Token met repo-rechten
#   GITHUB_OWNER  — organisatie of gebruikersnaam
#   GITHUB_REPO   — naam van de repository

set -euo pipefail

: "${GITHUB_TOKEN:?Variabele GITHUB_TOKEN is niet ingesteld}"
: "${GITHUB_OWNER:?Variabele GITHUB_OWNER is niet ingesteld}"
: "${GITHUB_REPO:?Variabele GITHUB_REPO is niet ingesteld}"

BRANCH="main"
API="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/branches/${BRANCH}/protection"

echo "▶ Branch protection instellen op ${GITHUB_OWNER}/${GITHUB_REPO}:${BRANCH} ..."

curl -s -X PUT "${API}" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -d '{
    "required_status_checks": {
      "strict": true,
      "contexts": ["jenkins/pipeline"]
    },
    "enforce_admins": false,
    "required_pull_request_reviews": {
      "required_approving_review_count": 1
    },
    "restrictions": null
  }' | python3 -m json.tool

echo "✅ Branch protection actief — merge knop vereist nu: jenkins/pipeline ✓"
