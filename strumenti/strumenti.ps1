# =====================================================================
#  STRUMENTI DEANGELISBUS - lavorare da qualsiasi PC + copia su USB
#  Progetti: app Orari (repo orari-deangelisbus, ramo main)
#            gestionale (repo deangelisbus-gestionale, ramo master)
#  Avvio: doppio clic su "DeAngelisBus-Strumenti.bat"
#  NB: testi senza accenti di proposito (compatibilita' PowerShell 5).
# =====================================================================
$ErrorActionPreference = 'Continue'
# Le cartelle si ricavano dalla posizione di questo script: <BASE>\orari-deangelisbus\strumenti
# Sul PC:        C:\DEANGELISBUS\orari-deangelisbus\strumenti
# Su chiavetta:  X:\DEANGELISBUS-USB-v21\orari-deangelisbus\strumenti  (qualsiasi lettera)
$ORARI       = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$BASE        = Split-Path $ORARI -Parent
$DRIVE       = (Split-Path $ORARI -Qualifier)
# "chiavetta" = qualsiasi unita' diversa da quella di Windows (alcune chiavette grandi risultano come dischi fissi)
$SU_USB      = ($DRIVE -ne $env:SystemDrive)
$URL_ORARI   = 'https://github.com/buonleo1-maker/orari-deangelisbus.git'
$URL_GEST    = 'https://github.com/buonleo1-maker/deangelisbus-gestionale.git'
$PROGETTO_SB = 'hmdpaypyljdgoehztbvi'
$PAGES_ORARI = 'orari-deangelisbus'
$PAGES_GEST  = 'amministrazione-deangelisbus-v2'

function Titolo($t) { Write-Host ''; Write-Host ('=' * 64) -ForegroundColor DarkCyan; Write-Host "  $t" -ForegroundColor Cyan; Write-Host ('=' * 64) -ForegroundColor DarkCyan }
function Ok($t)     { Write-Host "  [OK] $t" -ForegroundColor Green }
function Avviso($t) { Write-Host "  [!]  $t" -ForegroundColor Yellow }
function Errore($t) { Write-Host "  [X]  $t" -ForegroundColor Red }
function Chiedi($t) { return (Read-Host "  $t") }
function SiNo($t)   { $r = Read-Host "  $t (s/n)"; return ($r -match '^[sSyY]') }

# ---------- dove sono i progetti su questo PC ----------
function Trova-RepoGestionale {
  # Cerca il repository del gestionale sotto BASE (fino a 2 livelli), SALTANDO archivi, backup e copie vecchie.
  $escludi = '(?i)archivio|backup|bkp|old|copia|vecchi|solo-pagine|node_modules|usb-v21|dist'
  $cand = @()
  $cand += Get-ChildItem $BASE -Directory -Force -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -ne 'orari-deangelisbus' -and $_.Name -notmatch $escludi }
  $cand += $cand | ForEach-Object { Get-ChildItem $_.FullName -Directory -Force -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -notmatch $escludi } }
  foreach ($c in $cand) {
    $d = $c.FullName
    if (-not (Test-Path (Join-Path $d '.git'))) { continue }
    $url = (git -C $d remote get-url origin 2>$null)
    if ($url -notmatch 'deangelisbus-gestionale') { continue }
    # deve contenere davvero l'app (in radice o nella sottocartella 2-SORGENTE-APP)
    if ((Test-Path "$d\2-SORGENTE-APP\src\components\AdminShell.tsx") -or (Test-Path "$d\src\components\AdminShell.tsx")) { return $d }
  }
  return $null
}
function Trova-AppGestionale($repo) {
  if (-not $repo) { return $null }
  $sotto = "$repo\2-SORGENTE-APP"
  $a = Test-Path "$sotto\src\components\AdminShell.tsx"
  $b = Test-Path "$repo\src\components\AdminShell.tsx"
  if ($a -and $b) {
    Avviso "Trovate DUE copie del gestionale:"
    Write-Host "     1) $sotto"
    Write-Host "     2) $repo"
    $s = Chiedi "Quale uso? (1 = quella su GitHub, consigliata)"
    if ($s -eq '2') { return $repo } else { return $sotto }
  }
  if ($a) { return $sotto }
  if ($b) { return $repo }
  return $null
}
function Stato-Postazione {
  $script:REPO_GEST = Trova-RepoGestionale
  $script:APP_GEST  = Trova-AppGestionale $script:REPO_GEST
}

# ---------- controlli ----------
function Controlla-Programmi {
  $ok = $true
  if (Get-Command git -ErrorAction SilentlyContinue) { Ok ("Git: " + (git --version)) } else { Errore "Git non installato: scaricalo da https://git-scm.com"; $ok = $false }
  if (Get-Command node -ErrorAction SilentlyContinue) { Ok ("Node.js: " + (node --version)) } else { Errore "Node.js non installato: scarica la versione LTS da https://nodejs.org"; $ok = $false }
  return $ok
}
function Controlla-Env($cartella, $nome) {
  # accetta .env, .env.local o .env.production (Vite li legge tutti)
  $f = @('.env', '.env.local', '.env.production') | ForEach-Object { Join-Path $cartella $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $f) { Errore "$nome - manca il file .env (o .env.local) in $cartella"; return $false }
  $t = Get-Content $f -Raw
  if ($t -notmatch 'VITE_SUPABASE_URL\s*=\s*["'']?https://' -or $t -notmatch 'VITE_SUPABASE_ANON_KEY\s*=\s*["'']?(eyJ|sb_publishable_)' -or $t -notmatch $PROGETTO_SB) {
    Errore "$nome - il file $(Split-Path $f -Leaf) non e' completo (servono VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY del progetto $PROGETTO_SB)"; return $false
  }
  Ok "$nome - file $(Split-Path $f -Leaf) presente e corretto"; return $true
}
function Scrivi-Env($cartella, $chiave) {
  $testo = "VITE_SUPABASE_URL=https://$PROGETTO_SB.supabase.co`r`nVITE_SUPABASE_ANON_KEY=$chiave`r`n"
  [IO.File]::WriteAllText((Join-Path $cartella '.env'), $testo, (New-Object System.Text.UTF8Encoding $false))
}

# ---------- 1. prima installazione ----------
function Prima-Installazione {
  Titolo "PRIMA INSTALLAZIONE SU QUESTO PC"
  if (-not (Controlla-Programmi)) { Avviso "Installa i programmi mancanti, chiudi e riapri, poi ripeti."; return }

  if (-not (git config --global user.name)) {
    git config --global user.name (Chiedi "Nome per i commit (es. Leo Buonamassa)")
    git config --global user.email (Chiedi "Email del tuo account GitHub")
  }
  Ok ("Identita' Git: " + (git config --global user.name) + " <" + (git config --global user.email) + ">")

  if (-not (Test-Path $BASE)) { New-Item -ItemType Directory $BASE | Out-Null }

  if (Test-Path "$ORARI\.git") { Ok "App Orari gia' presente in $ORARI" }
  else { Write-Host "  Scarico l'app Orari..."; git clone $URL_ORARI $ORARI }

  Stato-Postazione
  if ($script:REPO_GEST) { Ok "Gestionale gia' presente in $($script:REPO_GEST)" }
  else {
    $dest = "$BASE\2-SORGENTE-APP\2-SORGENTE-APP"
    Avviso "Il gestionale (come repository Git) non e' presente in ${BASE}: lo scarico da GitHub."
    if (Test-Path $dest) { Avviso "La cartella $dest esiste ma non e' il gestionale: la rinomino in $dest-vecchia"; Rename-Item $dest "$dest-vecchia" }
    if (-not (Test-Path "$BASE\2-SORGENTE-APP")) { New-Item -ItemType Directory "$BASE\2-SORGENTE-APP" | Out-Null }
    Write-Host "  Scarico il gestionale (ramo master)..."
    git clone -b master $URL_GEST $dest
    Stato-Postazione
  }

  # file .env (non stanno su GitHub)
  $chiave = $null
  foreach ($c in @($ORARI, $script:APP_GEST)) {
    if ($c -and (Test-Path "$c\.env")) { $m = Select-String -Path "$c\.env" -Pattern '^VITE_SUPABASE_ANON_KEY=((eyJ|sb_publishable_)\S+)'; if ($m) { $chiave = $m.Matches[0].Groups[1].Value } }
  }
  if (-not $chiave) {
    Write-Host "  Serve la chiave 'anon public' di Supabase (Project Settings > API Keys > Legacy > anon)."
    $chiave = Chiedi "Incolla qui la chiave (inizia con eyJ)"
  }
  foreach ($p in @(@($ORARI, 'App Orari'), @($script:APP_GEST, 'Gestionale'))) {
    if ($p[0] -and -not (Test-Path "$($p[0])\.env")) { Scrivi-Env $p[0] $chiave; Ok "$($p[1]) - creato il file .env" }
  }

  foreach ($p in @(@($ORARI, 'App Orari'), @($script:APP_GEST, 'Gestionale'))) {
    if ($p[0]) { Write-Host "  Installo le librerie di $($p[1]) (qualche minuto)..."; Push-Location $p[0]; npm.cmd install --no-audit --no-fund; Pop-Location }
  }

  Write-Host "  Controllo l'accesso a Cloudflare..."
  Push-Location $ORARI
  npx.cmd wrangler whoami 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) { Avviso "Si apre il browser: accedi a Cloudflare e premi Allow"; npx.cmd wrangler login }
  Pop-Location
  Ok "Postazione pronta."
}

# ---------- 2. aggiorna (inizio lavoro) ----------
function Aggiorna-Repo($cartella, $nome) {
  if (-not $cartella -or -not (Test-Path "$cartella\.git")) { Avviso "$nome non trovato su questo PC (usa la voce 1)"; return }
  Write-Host "  $nome..." -ForegroundColor White
  $lock = Get-ChildItem $cartella -Recurse -Filter package-lock.json -Depth 2 -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch 'node_modules|usb-v21' }
  $prima = ($lock | ForEach-Object { (Get-FileHash $_.FullName).Hash }) -join ''
  $modifiche = git -C $cartella status --porcelain
  if ($modifiche) { Avviso "$nome ha modifiche non salvate: le salvo prima di aggiornare? (altrimenti il pull potrebbe fermarsi)"; if (SiNo "Salvo ora") { Salva-Repo $cartella $nome } }
  git -C $cartella pull
  if ($LASTEXITCODE -ne 0) { Errore "$nome - aggiornamento non riuscito: leggi il messaggio qui sopra"; return }
  $dopo = ($lock | ForEach-Object { (Get-FileHash $_.FullName).Hash }) -join ''
  if ($prima -ne $dopo) { Write-Host "  Librerie cambiate: reinstallo..."; foreach ($l in $lock) { Push-Location $l.DirectoryName; npm.cmd install --no-audit --no-fund; Pop-Location } }
  Ok "$nome aggiornato"
}
function Aggiorna-Tutto {
  Titolo "AGGIORNA TUTTO (da fare quando inizi a lavorare)"
  Stato-Postazione
  Aggiorna-Repo $ORARI 'App Orari'
  Aggiorna-Repo $script:REPO_GEST 'Gestionale'
  Scarica-Backup -Silenzioso
}

# ---------- 3. salva (fine lavoro) ----------
function Salva-Repo($cartella, $nome) {
  if (-not $cartella -or -not (Test-Path "$cartella\.git")) { Avviso "$nome non trovato su questo PC"; return }
  $modifiche = git -C $cartella status --porcelain
  if (-not $modifiche) {
    git -C $cartella push 2>$null | Out-Null
    Ok "$nome - niente da salvare"; return
  }
  Write-Host "  $nome - file modificati:" -ForegroundColor White
  $modifiche | ForEach-Object { Write-Host "     $_" }
  if ($modifiche -match '(^|[\\/ ])\.env(\.local|\.production)?$') { Errore "$nome - c'e' un file .env nell'elenco: NON lo carico. Controlla il .gitignore."; return }
  if (-not (SiNo "Salvo queste modifiche su GitHub")) { return }
  $msg = Chiedi "Descrizione breve (es. nuovi orari Montescaglioso)"
  if (-not $msg) { $msg = "Aggiornamento del " + (Get-Date -Format 'dd/MM/yyyy HH:mm') }
  git -C $cartella add -A
  $env_in = git -C $cartella diff --cached --name-only | Where-Object { $_ -match '(^|/)\.env(\.local|\.production)?$' }
  if ($env_in) { git -C $cartella reset -q; Errore "$nome - un .env stava per essere caricato: annullato. Aggiungi .env al .gitignore."; return }
  git -C $cartella commit -m $msg
  git -C $cartella push
  if ($LASTEXITCODE -eq 0) { Ok "$nome salvato su GitHub" } else { Errore "$nome - push non riuscito: leggi il messaggio qui sopra" }
}
function Salva-Tutto {
  Titolo "SALVA TUTTO SU GITHUB (da fare prima di cambiare PC)"
  Stato-Postazione
  Salva-Repo $ORARI 'App Orari'
  Salva-Repo $script:REPO_GEST 'Gestionale'
}

# ---------- 4/5. pubblica ----------
function Pubblica($cartella, $nome, $progetto, $ramo) {
  Titolo "PUBBLICA $nome"
  if (-not $cartella) { Errore "$nome non trovato su questo PC"; return }
  if (-not (Controlla-Env $cartella $nome)) { Errore "Pubblicazione annullata: senza .env corretto il sito online smetterebbe di funzionare."; return }
  if (-not (SiNo "Compilo e pubblico $nome online")) { return }
  Push-Location $cartella
  npm.cmd run build
  if ($LASTEXITCODE -ne 0) { Pop-Location; Errore "Compilazione non riuscita: niente e' stato pubblicato."; return }
  if ($ramo) { npx.cmd wrangler pages deploy dist --project-name=$progetto --branch=$ramo --commit-dirty=true }
  else       { npx.cmd wrangler pages deploy dist --project-name=$progetto --commit-dirty=true }
  $esito = $LASTEXITCODE
  Pop-Location
  if ($esito -eq 0) { Ok "$nome pubblicato. Ricorda di salvare su GitHub (voce 3)." } else { Errore "Pubblicazione non riuscita: leggi il messaggio qui sopra" }
}

# ---------- 6. copia su USB ----------
function Copia-Usb {
  Titolo "COPIA DI SICUREZZA SU CHIAVETTA USB"
  if ($SU_USB) { Avviso "Stai gia' lavorando dalla chiavetta: la copia serve solo quando lavori dal disco del PC."; return }
  Stato-Postazione
  $usb = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=2" -ErrorAction SilentlyContinue
  if (-not $usb) { Errore "Nessuna chiavetta USB trovata. Inseriscila e riprova."; return }
  $usb | ForEach-Object { Write-Host ("     {0}  {1}  (liberi {2:N1} GB)" -f $_.DeviceID, $_.VolumeName, ($_.FreeSpace / 1GB)) }
  $lettera = Chiedi "Lettera della chiavetta (es. D)"
  $lettera = $lettera.Trim().TrimEnd(':').ToUpper()
  if (-not (Test-Path "$($lettera):\")) { Errore "Unita' $($lettera): non trovata"; return }
  $dest = "$($lettera):\DEANGELISBUS-COPIA"
  $escludi = @('node_modules', 'dist', '.wrangler', 'build', '.gradle')
  foreach ($p in @(@($ORARI, 'orari-deangelisbus'), @($script:REPO_GEST, 'gestionale'))) {
    if (-not $p[0]) { continue }
    Write-Host "  Copio $($p[1])..."
    robocopy $p[0] "$dest\$($p[1])" /MIR /XD $escludi /R:1 /W:1 /NFL /NDL /NJH /NP | Out-Null
    if ($LASTEXITCODE -lt 8) { Ok "$($p[1]) copiato in $dest\$($p[1])" } else { Errore "$($p[1]) - copia con errori (codice $LASTEXITCODE)" }
  }
  Set-Content "$dest\ULTIMA-COPIA.txt" ("Copia del " + (Get-Date -Format 'dd/MM/yyyy HH:mm') + " dal PC " + $env:COMPUTERNAME)
  Avviso "La chiavetta e' solo una COPIA DI SICUREZZA: si lavora sempre sul PC e si salva su GitHub."
}

# ---------- 7. controllo generale ----------
function Controllo {
  Titolo "CONTROLLO DI QUESTA POSTAZIONE ($env:COMPUTERNAME)"
  Controlla-Programmi | Out-Null
  Stato-Postazione
  if (Test-Path "$ORARI\.git") {
    Ok "App Orari: $ORARI (ramo $(git -C $ORARI branch --show-current))"
    Controlla-Env $ORARI 'App Orari' | Out-Null
    git -C $ORARI fetch -q 2>$null; $st = git -C $ORARI status -sb | Select-Object -First 1; Write-Host "       $st"
  } else { Avviso "App Orari non presente (usa la voce 1)" }
  if ($script:REPO_GEST) {
    Ok "Gestionale: repo $($script:REPO_GEST) (ramo $(git -C $script:REPO_GEST branch --show-current))"
    if ($script:APP_GEST) { Ok "Gestionale: app da compilare in $($script:APP_GEST)"; Controlla-Env $script:APP_GEST 'Gestionale' | Out-Null }
    git -C $script:REPO_GEST fetch -q 2>$null; $st = git -C $script:REPO_GEST status -sb | Select-Object -First 1; Write-Host "       $st"
  } else { Avviso "Gestionale non presente (usa la voce 1)" }
  Write-Host "  (Se accanto al ramo compare 'behind' devi aggiornare; se compare 'ahead' devi salvare.)"
}

# ---------- 8. collegamento sul Desktop ----------
function Collegamento-Desktop {
  if ($SU_USB) { Avviso "Stai usando la chiavetta: l'icona smetterebbe di funzionare quando la togli. Usa il .bat dalla chiavetta."; return }
  $bat = Join-Path $PSScriptRoot 'DeAngelisBus-Strumenti.bat'
  $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'DeAngelisBus Strumenti.lnk'
  $sh = New-Object -ComObject WScript.Shell
  $s = $sh.CreateShortcut($lnk); $s.TargetPath = $bat; $s.WorkingDirectory = $PSScriptRoot; $s.Save()
  Ok "Creato il collegamento sul Desktop: 'DeAngelisBus Strumenti'"
}


# ---------- 9. backup del database su PC/chiavetta ----------
$BACKUP_DIR = Join-Path $BASE 'BACKUP-DATABASE'
$BACKUP_KEY = Join-Path $BACKUP_DIR 'chiave-backup.txt'
function Leggi-Env($chiave) {
  foreach ($f in @("$ORARI\.env", "$ORARI\.env.local")) {
    if (Test-Path $f) { $r = Get-Content $f | Where-Object { $_ -like "$chiave=*" } | Select-Object -First 1; if ($r) { return ($r -replace "^$chiave=", '').Trim() } }
  }
  return $null
}
function Scarica-Backup([switch]$Silenzioso) {
  if (-not $Silenzioso) { Titolo "SCARICA I BACKUP DEL DATABASE ($BACKUP_DIR)" }
  New-Item -ItemType Directory -Force $BACKUP_DIR | Out-Null
  if (-not (Test-Path $BACKUP_KEY)) {
    if ($Silenzioso) { return }
    Write-Host "  Serve la chiave dei backup (una volta sola per postazione). Su Supabase, SQL Editor, esegui:"
    Write-Host "    select decrypted_secret from vault.decrypted_secrets where name = 'backup_download_key';" -ForegroundColor Cyan
    $sec = Read-Host "  Incolla qui la chiave (non viene mostrata)" -AsSecureString
    $k = ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))).Trim()
    if (-not $k) { Avviso "Nessuna chiave: annullato"; return }
    [IO.File]::WriteAllText($BACKUP_KEY, $k)
    if (Test-Path $BACKUP_KEY) { Ok "Chiave salvata in $BACKUP_KEY (non verra' piu' chiesta)" } else { Avviso "Non riesco a salvare la chiave: la chiedero' di nuovo la prossima volta" }
  }
  $url = Leggi-Env 'VITE_SUPABASE_URL'; $anon = Leggi-Env 'VITE_SUPABASE_ANON_KEY'
  if (-not $url) { $url = "https://$PROGETTO_SB.supabase.co" }
  $chiave = if (Test-Path $BACKUP_KEY) { ([IO.File]::ReadAllText($BACKUP_KEY)).Trim() } else { $k }
  $h = @{ 'x-backup-key' = $chiave }; if ($anon) { $h['apikey'] = $anon }
  try { $r = Invoke-RestMethod -Method Post -Uri "$url/functions/v1/backup-dati" -Headers $h -ContentType 'application/json' -Body '{"azione":"elenco-pc"}' -TimeoutSec 120 }
  catch {
    if ($Silenzioso) { Avviso "Backup database: copie non scaricate ($($_.Exception.Message))"; return }
    Errore "Impossibile leggere l'elenco dei backup: $($_.Exception.Message)"
    if ("$($_.Exception.Message)" -match '403') { Avviso "Chiave non valida: la cancello, riprova con la voce 9."; Remove-Item $BACKUP_KEY -Force -ErrorAction SilentlyContinue }
    return
  }
  $nuove = 0
  foreach ($c in $r.copie) {
    $dest = Join-Path $BACKUP_DIR $c.file
    if ((Test-Path $dest) -and ((Get-Item $dest).Length -eq [int64]$c.dimensione)) { continue }
    try { Invoke-WebRequest -Uri $c.url -OutFile $dest -UseBasicParsing -TimeoutSec 300; $nuove++ } catch { Avviso "Non scaricato: $($c.file)" }
  }
  foreach ($c in $r.copie) {   # struttura del database (file .sql) di ogni copia
    if (-not $c.struttura -or -not $c.struttura.url) { continue }
    $dest = Join-Path $BACKUP_DIR $c.struttura.file
    if (Test-Path $dest) { continue }
    try { Invoke-WebRequest -Uri $c.struttura.url -OutFile $dest -UseBasicParsing -TimeoutSec 120 } catch { Avviso "Non scaricato: $($c.struttura.file)" }
  }
  $tot = (Get-ChildItem $BACKUP_DIR -Filter '*.json.gz' -ErrorAction SilentlyContinue).Count
  Ok "Backup database: $nuove copie nuove scaricate, $tot copie in $BACKUP_DIR"
  if (-not $Silenzioso -and $r.copie.Count -gt 0) { Write-Host "  Ultima copia: $($r.copie[0].creato_il) ($([math]::Round($r.copie[0].dimensione/1KB)) KB)" }
}

# ---------- avvio ----------
$sd = git config --global --get-all safe.directory 2>$null
if (-not ($sd -contains '*')) { git config --global --add safe.directory '*' }   # evita il blocco di Git su chiavette
if ($SU_USB) {
  Titolo "MODALITA' CHIAVETTA ($BASE)"
  Avviso "Lavori dalla chiavetta: prima scarico le ultime modifiche da GitHub."
  Aggiorna-Tutto
  Avviso "Ricorda: prima di togliere la chiavetta usa la voce 3 (Salva tutto)."
}

# ---------- menu ----------
while ($true) {
  $dove = if ($SU_USB) { "CHIAVETTA $DRIVE" } else { "PC $env:COMPUTERNAME" }
  Titolo "STRUMENTI DEANGELISBUS  -  $dove  ($BASE)"
  Write-Host "   1) Prima installazione su questo PC"
  Write-Host "   2) Aggiorna tutto          (INIZIO lavoro: scarica le modifiche da GitHub)"
  Write-Host "   3) Salva tutto su GitHub   (FINE lavoro, prima di cambiare PC)"
  Write-Host "   4) Pubblica l'app Orari    (orari.deangelisbus.it)"
  Write-Host "   5) Pubblica il gestionale  (amministrazione)"
  Write-Host "   6) Copia di sicurezza su chiavetta USB"
  Write-Host "   7) Controllo di questa postazione"
  Write-Host "   8) Crea collegamento sul Desktop"
  Write-Host "   9) Scarica i backup del database (copie su questo PC/chiavetta)"
  Write-Host "   0) Esci"
  $scelta = Chiedi "Scelta"
  switch ($scelta) {
    '1' { Prima-Installazione }
    '2' { Aggiorna-Tutto }
    '3' { Salva-Tutto }
    '4' { Pubblica $ORARI 'APP ORARI' $PAGES_ORARI 'main' }
    '5' { Stato-Postazione; Pubblica $script:APP_GEST 'GESTIONALE' $PAGES_GEST $null }
    '6' { Copia-Usb }
    '7' { Controllo }
    '8' { Collegamento-Desktop }
    '9' { Scarica-Backup }
    '0' {
      if ($SU_USB) {
        Stato-Postazione
        $da = @($ORARI, $script:REPO_GEST) | Where-Object { $_ -and (git -C $_ status --porcelain) }
        if ($da) { Avviso "Ci sono modifiche non salvate su GitHub."; if (SiNo "Salvo prima di uscire") { Salva-Tutto } }
      }
      return
    }
    default { Avviso "Scelta non valida" }
  }
}
