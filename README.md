# PoC: GitHub PR + Jenkins in OpenShift

Proof of Concept die aantoont hoe een Pull Request automatisch
een Jenkins pipeline triggert in OpenShift, en de resultaten
terugkoppelt naar de GitHub merge-knop.

---

## Architectuur

```
Developer → GitHub PR → Webhook → Jenkins (OpenShift)
                                       ↓
                               Linter + Unit tests
                                       ↓
                         GitHub Commit Status API
                                       ↓
                          Merge knop ✓ of ✗
```

---

## Structuur

```
poc/
├── app/
│   ├── calculator.py          ← voorbeeldapplicatie
│   └── test_calculator.py     ← pytest unit tests
├── jenkins/
│   ├── Jenkinsfile            ← declaratieve pipeline (Groovy)
│   └── openshift-buildconfig.yaml  ← OpenShift resources
├── .github/
│   └── github-branch-protection.sh ← branch protection instellen
└── README.md
```

---

## Stap-voor-stap instelling

### 1. Vereisten

| Tool | Versie |
|------|--------|
| OpenShift CLI (`oc`) | 4.x of hoger |
| GitHub account | met repo-toegang |
| Jenkins | geïnstalleerd in OpenShift via Operator |

---

### 2. Repository aanmaken

```bash
# Fork of push deze map naar jouw GitHub repo
git init
git remote add origin https://github.com/JOUW-ORG/JOUW-REPO.git
git add .
git commit -m "chore: PoC initieel commit"
git push -u origin main
```

---

### 3. Jenkins instellen in OpenShift

```bash
# Inloggen op OpenShift
oc login https://jouw-cluster-api:6443

# Namespace aanmaken
oc new-project poc-pipeline

# GitHub token opslaan als Jenkins credential
# (Doe dit in Jenkins UI: Manage Jenkins → Credentials → Global → Add)
# ID: github-token
# Type: Secret text
# Value: ghp_xxxxxxxxxxxxxxxxxxxx
```

---

### 4. OpenShift BuildConfig deployen

Pas eerst de waarden aan in `jenkins/openshift-buildconfig.yaml`:
- `namespace` → jouw OpenShift namespace
- `uri` → jouw GitHub repository URL
- `WebHookSecretKey` → een sterk random geheim (bijv. `openssl rand -hex 32`)

```bash
oc apply -f jenkins/openshift-buildconfig.yaml
```

---

### 5. Webhook URL ophalen en instellen in GitHub

```bash
# Webhook URL opvragen
oc describe bc/poc-pipeline | grep "Webhook GitHub"
# Output: https://CLUSTER/apis/build.openshift.io/.../webhooks/poc-webhook-secret/github
```

Ga naar **GitHub → jouw repo → Settings → Webhooks → Add webhook**:
- **Payload URL**: de URL uit de vorige stap
- **Content type**: `application/json`
- **Secret**: de waarde van `WebHookSecretKey`
- **Events**: `Pull requests` + `Pushes`

---

### 6. Branch protection instellen

```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
export GITHUB_OWNER="jouw-org"
export GITHUB_REPO="jouw-repo"

bash .github/github-branch-protection.sh
```

Na dit commando vereist GitHub dat `jenkins/pipeline` groen is
voordat de merge-knop actief wordt.

---

### 7. Testen

```bash
# Maak een feature branch aan
git checkout -b feature/mijn-wijziging

# Doe een kleine aanpassing (bijv. voeg een functie toe aan calculator.py)
echo "" >> app/calculator.py

git add . && git commit -m "feat: testwijziging"
git push origin feature/mijn-wijziging
```

Open daarna een Pull Request op GitHub. Je ziet binnen 30 seconden:

- ⏳ `jenkins/pipeline — Pending`
- ✅ `jenkins/pipeline — Pipeline geslaagd` → merge-knop actief
- ❌ `jenkins/pipeline — Pipeline mislukt` → merge-knop geblokkeerd

---

### 8. Pipeline lokaal uitproberen

```bash
cd poc/
pip install pytest flake8

# Linter
flake8 app/ --max-line-length=100

# Tests
pytest app/ -v
```

---

## Veelgestelde vragen

**Q: Waarom kubernetes agent in het Jenkinsfile?**
Jenkins in OpenShift draait pipelines als tijdelijke pods. De `kubernetes`
agent start een Python-pod, voert de stappen uit en verwijdert de pod daarna.
Dit bespaart resources en isoleert builds van elkaar.

**Q: Hoe voeg ik meer checks toe?**
Voeg extra `stage`-blokken toe in `jenkins/Jenkinsfile`, bijvoorbeeld:
- `bandit` voor security scanning
- `coverage` voor testdekking
- `docker build` voor container-bouw

**Q: Hoe werkt de status-terugkoppeling zonder de GitHub plugin?**
De `setGitHubCommitStatus`-functie in het Jenkinsfile roept de
GitHub REST API rechtstreeks aan via `curl`. Zo werkt het ook zonder
de officiële Jenkins GitHub-plugin.
