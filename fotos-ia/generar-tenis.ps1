<#
  Genera el producto 3D de "Duna Runner" con fal.ai:
  1) FLUX Pro Ultra crea la foto del tenis sobre fondo blanco
  2) TRELLIS convierte la foto en un modelo 3D (.glb)
  Guarda la foto y el modelo en muestra-tenis\modelo\

    .\generar-tenis.ps1            # genera lo que falte
    .\generar-tenis.ps1 -Rehacer   # vuelve a generar todo

  Requiere: variable de entorno FAL_KEY.
#>
param([switch]$Rehacer)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Raiz = Split-Path $PSScriptRoot -Parent
$Dir = Join-Path $Raiz 'muestra-tenis\modelo'
$Originales = Join-Path $PSScriptRoot 'originales'
New-Item -ItemType Directory -Force $Dir, $Originales | Out-Null

$Prompt = 'A single modern running sneaker, sand beige knit upper with terracotta orange accents, chunky white foam midsole, dark gum rubber outsole, three-quarter side view from the front right, whole shoe visible, centered, isolated on a seamless pure white background, soft even studio lighting, professional product photography, photorealistic, sharp focus, no logos, no text, no brand marks'

function Invocar-Fal($modelo, $cuerpo) {
    if (-not $env:FAL_KEY) { throw 'Falta FAL_KEY.' }
    $headers = @{ Authorization = "Key $($env:FAL_KEY -replace '\s', '')" }
    $json = $cuerpo | ConvertTo-Json -Depth 5
    $cola = Invoke-RestMethod -Method Post -Uri "https://queue.fal.run/$modelo" -Headers $headers `
        -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($json))
    $limite = (Get-Date).AddMinutes(15)
    do {
        Start-Sleep -Seconds 4
        $estado = Invoke-RestMethod -Uri $cola.status_url -Headers $headers
        if ((Get-Date) -gt $limite) { throw 'Tiempo agotado esperando a fal.ai' }
    } while ($estado.status -ne 'COMPLETED')
    Invoke-RestMethod -Uri $cola.response_url -Headers $headers
}

$foto = Join-Path $Originales 'tenis-foto.jpg'
$urlFoto = Join-Path $Originales 'tenis-foto.url'
$glb = Join-Path $Dir 'tenis.glb'

if ($Rehacer -or -not (Test-Path $urlFoto)) {
    Write-Host '[tenis] generando foto...'
    $r = Invocar-Fal 'fal-ai/flux-pro/v1.1-ultra' @{ prompt = $Prompt; aspect_ratio = '4:3'; raw = $false; num_images = 1; output_format = 'jpeg'; safety_tolerance = '2' }
    Invoke-WebRequest -Uri $r.images[0].url -OutFile $foto
    Set-Content -Path $urlFoto -Value $r.images[0].url -Encoding ascii
    Write-Host '[tenis] foto lista'
}

if ($Rehacer -or -not (Test-Path $glb)) {
    Write-Host '[tenis] creando modelo 3D (tarda unos minutos)...'
    $m = Invocar-Fal 'fal-ai/trellis' @{ image_url = (Get-Content $urlFoto -Raw).Trim(); texture_size = 1024; mesh_simplify = 0.95 }
    Invoke-WebRequest -Uri $m.model_mesh.url -OutFile $glb
    Write-Host "[tenis] modelo listo ($([math]::Round((Get-Item $glb).Length / 1KB)) KB)"
}
