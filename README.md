# POC Java — Code kwaliteit pipeline

> **Proof of Concept** — Automatische code kwaliteitscontrole via GitHub Actions
> met deployment naar OpenShift via Jenkins.

---

## Inhoudsopgave

1. [Architectuuroverzicht](#architectuuroverzicht)
2. [Vereisten](#vereisten)
3. [Project opzetten](#project-opzetten)
4. [GitHub Secrets instellen](#github-secrets-instellen)
5. [Pipeline in actie](#pipeline-in-actie)
6. [Lokaal uitvoeren](#lokaal-uitvoeren)
7. [Jenkins job aanmaken](#jenkins-job-aanmaken)
8. [Resultaten bekijken](#resultaten-bekijken)
9. [Veelgestelde problemen](#veelgestelde-problemen)

---

## Architectuuroverzicht

```
Developer (lokaal)
      │
      │  git push
      ▼
GitHub (DevSecOpsPipeline repository)
      │
      │  GitHub Actions wordt automatisch getriggerd
      ▼
┌─────────────────────────────────────┐
│         GitHub Actions CI           │
│                                     │
│  Stap 1: Checkstyle                 │
│          → code stijl controleren   │
│          → stopt bij fouten         │
│                                     │
│  Stap 2: Maven test                 │
│          → unit tests uitvoeren     │
│          → stopt bij falende tests  │
│                                     │
│  Stap 3: SpotBugs                   │
│          → bug detectie             │
│          → stopt bij bugs           │
│                                     │
│  Stap 4: JaCoCo                     │
│          → coverage rapport         │
│          → minimum 70% vereist      │
│                                     │
│  Stap 5: Jenkins triggeren          │
│          → alleen op main branch    │
│          → alleen als alles slaagt  │
└─────────────────────────────────────┘
      │
      ▼
Jenkins (OpenShift)
      │
      ├── Deploy naar staging
      ├── Handmatige goedkeuring
      └── Deploy naar productie
```

---

## Vereisten

| Tool | Versie | Waarvoor |
|------|--------|----------|
| Java JDK | 17+ | Lokaal builden |
| Maven | 3.8+ | Build tool |
| Git | 2.x | Versiebeheer |
| GitHub account | - | Repository + Actions |
| OpenShift account | - | maureenmuys-dev namespace |

---

## Project opzetten

### 1. ZIP uitpakken en naar GitHub pushen

```bash
# ZIP uitpakken
unzip poc-java.zip
cd poc-java

# Git initialiseren (als nog niet gedaan)
git init
git remote add origin https://github.com/maureenmuys/DevSecOpsPipeline

# Bestanden toevoegen en pushen
git add .
git commit -m "feat: POC Java pipeline initieel"
git push -u origin main
```

### 2. Controleer of Actions actief is

Ga naar: https://github.com/maureenmuys/DevSecOpsPipeline/actions

Je ziet de workflow automatisch starten na de push.

---

## GitHub Secrets instellen

De pipeline heeft twee secrets nodig om Jenkins te kunnen triggeren.

### Stap 1 — Ga naar secrets pagina

```
https://github.com/maureenmuys/DevSecOpsPipeline/settings/secrets/actions
```

### Stap 2 — Voeg toe: JENKINS_USER

- Klik **"New repository secret"**
- Name: `JENKINS_USER`
- Secret: `maureenmuys`
- Klik **"Add secret"**

### Stap 3 — Voeg toe: JENKINS_TOKEN

- Klik **"New repository secret"**
- Name: `JENKINS_TOKEN`
- Secret: `<jouw Jenkins API token>`
- Klik **"Add secret"**

> **Jouw Jenkins URL:**
> https://jenkins-maureenmuys-dev.apps.rm3.7wse.p1.openshiftapps.com

---

## Pipeline in actie

De pipeline start automatisch bij elke `git push`. De checks lopen in volgorde:

```
Checkstyle → Tests → SpotBugs → JaCoCo → Jenkins
```

Als een stap faalt, stoppen alle volgende stappen. Je krijgt een e-mail
van GitHub als de pipeline faalt.

### Wat controleert elke stap?

**Checkstyle** controleert:
- Juiste naamgeving (klassen, methodes, variabelen)
- Geen ongebruikte imports
- Accolades op de juiste plaats
- Javadoc aanwezig op publieke methodes
- Geen tabs, wel spaties

**Maven test** controleert:
- Alle JUnit 5 tests slagen
- Geen compile fouten

**SpotBugs** detecteert:
- Null pointer risicos
- Onveilige bewerkingen
- Slechte coding patterns

**JaCoCo** controleert:
- Minimaal 70% van de code is gedekt door tests
- Genereert een HTML rapport

---

## Lokaal uitvoeren

Voer de checks lokaal uit voordat je pusht:

```bash
# Alles in één keer (aanbevolen)
mvn verify

# Of stap per stap:

# 1. Checkstyle
mvn checkstyle:check

# 2. Tests uitvoeren
mvn test

# 3. SpotBugs
mvn spotbugs:check

# 4. Coverage rapport genereren
mvn jacoco:report
# Rapport openen:
open target/site/jacoco/index.html   # Mac
start target/site/jacoco/index.html  # Windows
```

---

## Jenkins job aanmaken

### Stap 1 — Open Jenkins

```
https://jenkins-maureenmuys-dev.apps.rm3.7wse.p1.openshiftapps.com
```

### Stap 2 — Nieuwe job aanmaken

1. Klik **"New Item"**
2. Naam: `poc-deploy`
3. Kies **"Pipeline"**
4. Klik **OK**

### Stap 3 — Pipeline configureren

1. Scroll naar **"Build Triggers"**
2. Vink aan: **"Trigger builds remotely"**
3. Vul een token in, bijv. `poc-deploy-token`

4. Scroll naar **"Pipeline"**
5. Definition: **"Pipeline script from SCM"**
6. SCM: **Git**
7. Repository URL: `https://github.com/maureenmuys/DevSecOpsPipeline`
8. Script Path: `jenkins/Jenkinsfile`

9. Klik **Save**

### Stap 4 — GitHub Actions aanpassen

Pas de Jenkins URL aan in `.github/workflows/ci.yml`:

```yaml
- name: Jenkins triggeren
  run: |
    curl -X POST \
      "https://jenkins-maureenmuys-dev.apps.rm3.7wse.p1.openshiftapps.com/job/poc-deploy/buildWithParameters" \
      --user "${{ secrets.JENKINS_USER }}:${{ secrets.JENKINS_TOKEN }}" \
      --data-urlencode "GIT_COMMIT=${{ github.sha }}"
```

---

## Resultaten bekijken

### GitHub Actions resultaten

1. Ga naar: https://github.com/maureenmuys/DevSecOpsPipeline/actions
2. Klik op een workflow run
3. Klik op een stap voor details

**Groene vinkjes** = alles geslaagd
**Rode kruisjes** = fout gevonden, klik voor details

### Artifacts downloaden

Na een succesvolle run kan je downloaden:
- **jacoco-rapport** → HTML coverage rapport
- **test-resultaten** → JUnit XML rapporten

### Jenkins resultaten

1. Ga naar Jenkins
2. Klik op `poc-deploy`
3. Klik op een build nummer
4. Zie **Console Output** voor details

---

## Veelgestelde problemen

**Checkstyle faalt — "Missing Javadoc"**
```java
// Voeg Javadoc toe boven elke publieke methode:
/**
 * Beschrijving van de methode.
 *
 * @param x beschrijving parameter
 * @return beschrijving returnwaarde
 */
public int methode(int x) { ... }
```

**Tests falen — coverage onder 70%**
```
Schrijf extra tests voor niet-gedekte code.
Kijk in target/site/jacoco/index.html welke lijnen rood zijn.
```

**Jenkins trigger faalt — HTTP 403**
```
Controleer JENKINS_USER en JENKINS_TOKEN in GitHub Secrets.
Controleer of "Trigger builds remotely" aangevinkt is in Jenkins.
```

**SpotBugs — NullPointerException risico**
```java
// Slecht:
String s = getValue();
s.trim();

// Goed:
String s = getValue();
if (s != null) {
    s.trim();
}
```

---

*POC — maureenmuys-dev | OpenShift | GitHub Actions | Jenkins*
# DevSecOpsPipeline
# DevSecOpsPipeline

## Pipeline test

## Pipeline test


