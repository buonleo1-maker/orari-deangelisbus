# Strumenti Sassi in Bus: aggiornare, salvare su GitHub e pubblicare app e pannello.
# Si avvia con SassiInBus-Strumenti.bat (doppio clic).
$ErrorActionPreference = 'Continue'
$radice = Split-Path -Parent $PSScriptRoot
Set-Location $radice

function Titolo($t) { Write-Host ""; Write-Host "================================================================" -ForegroundColor DarkRed; Write-Host "  $t" -ForegroundColor White; Write-Host "================================================================" -ForegroundColor DarkRed }
function Ok($t) { Write-Host "  [OK] $t" -ForegroundColor Green }
function Ko($t) { Write-Host "  [!!] $t" -ForegroundColor Red }

function ControllaEnv {
  if (-not (Test-Path "$radice\.env")) {
    Ko "Manca il file .env con l'indirizzo e la chiave del database Sassi in Bus."
    if (Test-Path "$radice\.env.esempio") { Copy-Item "$radice\.env.esempio" "$radice\.env"; notepad "$radice\.env"; Write-Host "  Compila il file .env che si e' aperto, salvalo e rilancia la voce." }
    return $false
  }
  if ((Get-Content "$radice\.env" -Raw) -match 'INCOLLA-QUI') { Ko "Il file .env contiene ancora 'INCOLLA-QUI': compilalo."; notepad "$radice\.env"; return $false }
  return $true
}

function Pubblica($cartella, $progetto, $nome) {
  Titolo "PUBBLICA $nome"
  if (-not (ControllaEnv)) { return }
  Set-Location "$radice\$cartella"
  Write-Host "  Controllo le librerie (la prima volta ci vogliono alcuni minuti)..."; npm.cmd install --no-audit --no-fund
  npm.cmd run build
  if ($LASTEXITCODE -ne 0) { Ko "La compilazione non e' riuscita: copia i messaggi qui sopra e chiedi aiuto."; Set-Location $radice; return }
  npx.cmd wrangler pages deploy dist --project-name=$progetto --branch=main --commit-dirty=true
  if ($LASTEXITCODE -eq 0) { Ok "$nome pubblicato. Ricorda di salvare su GitHub (voce 3)." } else { Ko "Pubblicazione non riuscita. Se e' la prima volta, crea il progetto con la voce 6." }
  Set-Location $radice
}

while ($true) {
  Titolo "STRUMENTI SASSI IN BUS  -  $radice"
  Write-Host "   1) Prima installazione su questo PC (librerie di app e pannello)"
  Write-Host "   2) Aggiorna tutto          (INIZIO lavoro: scarica da GitHub)"
  Write-Host "   3) Salva tutto su GitHub   (FINE lavoro)"
  Write-Host "   4) Pubblica l'app          (audioguida.sassinbus.it)"
  Write-Host "   5) Pubblica il pannello    (pannello.sassinbus.it)"
  Write-Host "   6) Crea i progetti su Cloudflare (solo la prima volta)"
  Write-Host "   7) Copia di sicurezza su chiavetta USB"
  Write-Host "   0) Esci"
  $s = Read-Host "  Scelta"
  switch ($s) {
    '1' {
      Titolo "PRIMA INSTALLAZIONE"
      ControllaEnv | Out-Null
      foreach ($c in 'app', 'admin') { Write-Host "  Librerie di $c..."; Set-Location "$radice\$c"; npm.cmd install; Set-Location $radice }
      Ok "Librerie installate."
    }
    '2' { Titolo "AGGIORNA TUTTO"; git pull; if ($LASTEXITCODE -eq 0) { Ok "Aggiornato." } else { Ko "Aggiornamento non riuscito." } }
    '3' {
      Titolo "SALVA TUTTO SU GITHUB"
      $mod = git status --porcelain
      if (-not $mod) { Ok "Niente da salvare." }
      else {
        Write-Host "  File modificati:"; $mod | ForEach-Object { Write-Host "     $_" }
        $d = Read-Host "  Descrizione breve"
        if (-not $d) { $d = "Aggiornamento Sassi in Bus" }
        git add -A; git commit -m "$d"; git push
        if ($LASTEXITCODE -eq 0) { Ok "Salvato su GitHub." } else { Ko "Salvataggio non riuscito." }
      }
    }
    '4' { Pubblica 'app' 'sassinbus' "L'APP SASSI IN BUS" }
    '5' { Pubblica 'admin' 'sassinbus-pannello' "IL PANNELLO SASSI IN BUS" }
    '6' {
      Titolo "CREA I PROGETTI CLOUDFLARE (una volta sola)"
      Set-Location "$radice\app"
      npx.cmd wrangler pages project create sassinbus --production-branch=main
      npx.cmd wrangler pages project create sassinbus-pannello --production-branch=main
      Set-Location $radice
      Ok "Fatto (se dice che esistono gia', va bene lo stesso)."
    }
    '7' {
      Titolo "COPIA DI SICUREZZA SU CHIAVETTA USB"
      $usb = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceID -ne $env:SystemDrive -and ($_.DriveType -eq 2 -or $_.DriveType -eq 3) }
      if (-not $usb) { Ko "Nessuna chiavetta trovata. Inseriscila e riprova."; continue }
      $usb | ForEach-Object { Write-Host ("     {0}  {1}  (liberi {2:N1} GB)" -f $_.DeviceID, $_.VolumeName, ($_.FreeSpace / 1GB)) }
      $l = (Read-Host "  Lettera della chiavetta (es. D)").Trim().TrimEnd(':').ToUpper()
      if (-not $l -or -not (Test-Path "$($l):\")) { Ko "Unita' non trovata."; continue }
      $dest = "$($l):\DEANGELISBUS-COPIA\sassinbus"
      robocopy $radice $dest /MIR /XD node_modules dist .wrangler /R:1 /W:1 /NFL /NDL /NJH /NP | Out-Null
      if ($LASTEXITCODE -lt 8) { Set-Content "$dest\ULTIMA-COPIA.txt" ("Copia del " + (Get-Date -Format 'dd/MM/yyyy HH:mm') + " dal PC " + $env:COMPUTERNAME); Ok "Copiato in $dest" } else { Ko "Copia con errori (codice $LASTEXITCODE)" }
      Write-Host "  (La copia comprende anche il file .env: tieni la chiavetta al sicuro.)"
    }
    '0' { return }
    default { Write-Host "  Scelta non valida." }
  }
}
