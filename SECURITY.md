# Security Guide

This project authenticates to the **Canva Connect API** with an OAuth 2.0 `client_id` + `client_secret`.

## Where secrets live

| Item | Location | In git? |
|---|---|---|
| `Canva_ClientId` | `Data\Config.xlsx` (sheet `CanvaPoster`) | No (`*.xlsx` is in `.gitignore`) |
| `Canva_ClientSecret` | `Data\Config.xlsx` (sheet `CanvaPoster`) | No (`*.xlsx` is in `.gitignore`) |
| `access_token` + `refresh_token` | `Data\Temp\canva_tokens.json` | No (explicitly gitignored) |

**Trade-off**: credentials are **plaintext on disk** inside `Config.xlsx`. Anyone with file-system access to the project folder can open the workbook and read them. This is acceptable on a trusted single-user attended robot machine, but **not** acceptable on shared machines or servers with multiple Windows users.

If you ever need stronger protection, see "Future hardening" at the bottom.

---

## 1. Rotate the previously-leaked secret (do this once)

An old client secret was committed to `Scripts\canva_reauth.ps1` in earlier versions of this repo. That secret is compromised and must be rotated:

1. Log into <https://www.canva.com/developers/integrations>.
2. Open the Canva Connect integration used by this robot.
3. Under **Credentials**, click **Regenerate client secret**.
4. Put the new values into `Data\Config.xlsx`:
   - Row `Canva_ClientId` = new `client_id` (e.g. `OC-XXXXXXXXX`)
   - Row `Canva_ClientSecret` = new `client_secret`
5. Save and close Excel.

Optional but recommended: purge the old secret from git history — see §4.

---

## 2. Re-auth script (`Scripts\canva_reauth.ps1`)

The script no longer contains hard-coded secrets. It resolves credentials in this order:

1. Command-line parameters: `-ClientId <id>` and `-ClientSecret <SecureString>`
2. Environment variables: `CANVA_CLIENT_ID` and `CANVA_CLIENT_SECRET`
3. Interactive prompts (`Read-Host`, with `-AsSecureString` for the secret)

Typical usage (only needed when the refresh token is invalid or absent):

```powershell
# You will be prompted for Client ID and Client Secret (secret is hidden input)
powershell -ExecutionPolicy Bypass -File .\Scripts\canva_reauth.ps1

# Or pass secret explicitly (SecureString):
$sec = Read-Host 'secret' -AsSecureString
powershell -ExecutionPolicy Bypass -File .\Scripts\canva_reauth.ps1 -ClientId 'OC-XXX' -ClientSecret $sec
```

The resulting `Data\Temp\canva_tokens.json` contains only the short-lived `access_token` + `refresh_token` — not the `client_secret`.

---

## 3. Moving the project to another machine

Because `Config.xlsx` and tokens are gitignored, a fresh clone will not have them. On the new machine you must manually provide:

| File | How to get it there |
|---|---|
| `Data\Config.xlsx` | Copy from your working machine, or create from template |
| `Data\Input\Emails_Local.xlsx` | Copy from your working machine |
| `Data\Fonts\*.otf` | Copy from your working machine |
| `Data\Temp\canva_tokens.json` | Not required — will be created by `canva_reauth.ps1` on first run |

Also required on the new machine:

- **Microsoft Edge** (built-in on Windows 10/11).
- **UiPath Studio/Robot** with internet access so NuGet packages declared in `project.json` can be restored on first open.
- If the project uses the Gmail connection (`Module_SendGmail.xaml`), the robot must have access to the GSuite Integration Service connection, or you must update the `ConnectionId` attribute to one the new machine is authorised for.

---

## 4. Purging the leaked secret from git history (optional)

Rotating the secret (§1) is the single most important step — once rotated, the old value in history is worthless. If you still want to remove it from history for hygiene:

**Option A — `git filter-repo` (recommended)**

```bash
pip install git-filter-repo
git clone --mirror <repo-url> repo-mirror.git
cd repo-mirror.git
git filter-repo --replace-text ../replacements.txt
git push --force --all
git push --force --tags
```

`replacements.txt` lives **outside** the repo and maps leaked strings to placeholders:

```
<leaked-canva-client-secret>==>REDACTED_CANVA_SECRET
<leaked-canva-client-id>==>REDACTED_CANVA_CLIENT_ID
```

Look up the exact leaked strings in `git log -p` first, then delete `replacements.txt` afterwards.

**Option B — BFG Repo-Cleaner**

```bash
bfg --replace-text replacements.txt my-repo.git
cd my-repo.git && git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force
```

All collaborators must re-clone after the force push.

---

## 5. Pre-commit guard (optional)

Add `.git/hooks/pre-commit` on your local clone (not versioned) to block obvious leaks:

```sh
#!/bin/sh
if git diff --cached | grep -E 'cnvca[a-zA-Z0-9_\-]{20,}|OC-[A-Z0-9]{10,}' >/dev/null; then
    echo "ERROR: Possible Canva secret in staged diff. Commit blocked."
    echo "If this is a false positive, commit with --no-verify."
    exit 1
fi
```

Make it executable: `chmod +x .git/hooks/pre-commit`.

---

## 6. Future hardening (if requirements change)

If this project ever needs stronger protection than "plaintext in a gitignored Excel file", consider one of:

- **UiPath Orchestrator Credential Asset** — secret lives in the Orchestrator vault, never touches disk. Suitable once the robot is connected to Orchestrator.
- **Windows Credential Manager** — secret stored in the per-user Windows Vault (DPAPI-protected).
- **DPAPI-encrypted local file** — secret encrypted with the Windows user account key, decrypted at runtime.

Ask before implementing — these change the workflow structure.
