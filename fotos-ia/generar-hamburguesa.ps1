<#
  Genera las capas de la hamburguesa de "Brasa Burger" con fal.ai:
  1) FLUX Pro Ultra crea cada ingrediente sobre fondo blanco
  2) BiRefNet le quita el fondo
  3) Se recorta al contenido y se guarda como PNG transparente en muestra-hamburguesa\img\

    .\generar-hamburguesa.ps1                     # genera las que faltan
    .\generar-hamburguesa.ps1 -Fotos capa-queso -Rehacer

  Requiere: variable de entorno FAL_KEY.
#>
param(
    [string[]]$Fotos,
    [switch]$Rehacer
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Drawing

$ModeloFoto = 'fal-ai/flux-pro/v1.1-ultra'
$ModeloFondo = 'fal-ai/birefnet'
$Raiz = Split-Path $PSScriptRoot -Parent
$DirImg = Join-Path $Raiz 'muestra-hamburguesa\img'

# Mismo encuadre y luz para todas las capas, para que encajen al apilarlas
$Capa = 'isolated on a seamless pure white background, nothing else in frame, side view photographed from the front with the camera almost level with the object (about 10 degrees above), clearly showing its thickness and edge so it reads as a wide flat horizontal layer, centered, filling the frame horizontally, soft even studio lighting, professional food product photography, photorealistic, sharp focus, no text, no watermark, no plate'
$Foto = 'professional food photography, dramatic warm side light, dark charcoal background with soft smoke, shallow depth of field, photorealistic, no text, no watermark, no logos'

$Lista = @(
    # Capas (de arriba hacia abajo) -> PNG transparente
    @{ id = 'capa-pan-arriba'; tipo = 'capa'; ancho = 900
       prompt = "The top half of a glossy golden toasted brioche burger bun with sesame seeds, dome shape, $Capa" }
    @{ id = 'capa-lechuga';    tipo = 'capa'; ancho = 900
       prompt = "One wide ruffled leaf of fresh crisp green lettuce lying flat, as layered inside a burger, $Capa" }
    @{ id = 'capa-tomate';     tipo = 'capa'; ancho = 900
       prompt = "Two round slices of ripe red tomato stacked flat and slightly offset, seen edge-on from the side so they look like thin flat red discs with visible juicy cut edges, like the tomato layer of a burger seen from the side, $Capa" }
    @{ id = 'capa-tocino';     tipo = 'capa'; ancho = 900
       prompt = "Crispy fully cooked smoked bacon strips, deep reddish-brown and caramelized, wavy and crunchy, piled flat as a thin layer seen from the side, like the bacon layer of a burger, $Capa" }
    @{ id = 'capa-queso';      tipo = 'capa'; ancho = 900
       prompt = "One very thin square slice of orange cheddar cheese, soft and slightly melted, lying flat as a thin sheet seen from the side with its corners drooping down, like the cheese layer of a burger, not a block, $Capa" }
    @{ id = 'capa-carne';      tipo = 'capa'; ancho = 900
       prompt = "One thick juicy fully cooked beef burger patty, dark brown seared sides like a classic American diner burger patty, deep brown all over, no pink, no gray, caramelized smash-burger crust with crispy edges, natural rough ground beef texture, no grill grid pattern, glistening with juices, $Capa" }
    @{ id = 'capa-pan-abajo';  tipo = 'capa'; ancho = 900
       prompt = "The bottom half of a toasted brioche burger bun, flat toasted cut side facing up, $Capa" }

    # Fotos del menú -> JPG
    @{ id = 'menu-clasica'; tipo = 'foto'; ar = '1:1'; ancho = 700
       prompt = "Classic cheeseburger with lettuce, tomato and melted cheddar on a wooden board, $Foto" }
    @{ id = 'menu-doble';   tipo = 'foto'; ar = '1:1'; ancho = 700
       prompt = "Double smash burger with two beef patties, melted cheese and crispy bacon, juices dripping, on a wooden board, $Foto" }
    @{ id = 'menu-papas';   tipo = 'foto'; ar = '1:1'; ancho = 700
       prompt = "Golden crispy french fries in a small metal basket with a side of chipotle mayo, $Foto" }
)

function Invocar-Fal($modelo, $cuerpo) {
    if (-not $env:FAL_KEY) { throw 'Falta FAL_KEY.' }
    $headers = @{ Authorization = "Key $($env:FAL_KEY -replace '\s', '')" }
    $json = $cuerpo | ConvertTo-Json -Depth 5
    $cola = Invoke-RestMethod -Method Post -Uri "https://queue.fal.run/$modelo" -Headers $headers `
        -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($json))
    $limite = (Get-Date).AddMinutes(10)
    do {
        Start-Sleep -Seconds 3
        $estado = Invoke-RestMethod -Uri $cola.status_url -Headers $headers
        if ((Get-Date) -gt $limite) { throw 'Tiempo agotado esperando a fal.ai' }
    } while ($estado.status -ne 'COMPLETED')
    Invoke-RestMethod -Uri $cola.response_url -Headers $headers
}

# Reduce la imagen al ancho indicado y la guarda como JPEG calidad 82
function Optimizar-Jpg($origen, $destino, $ancho) {
    $img = [Drawing.Image]::FromFile($origen)
    try {
        $alto = [int]($img.Height * $ancho / $img.Width)
        $bmp = New-Object Drawing.Bitmap $ancho, $alto
        $g = [Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = 'HighQualityBicubic'
        $g.DrawImage($img, 0, 0, $ancho, $alto)
        $codec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
        $params = New-Object Drawing.Imaging.EncoderParameters 1
        $params.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality), 82L
        $bmp.Save($destino, $codec, $params)
        $g.Dispose(); $bmp.Dispose()
    } finally { $img.Dispose() }
}

# Recorta los bordes transparentes, reduce al ancho indicado y guarda como PNG
function Recortar-Png($origen, $destino, $ancho) {
    $img = [Drawing.Image]::FromFile($origen)
    try {
        $escala = [Math]::Min(1, 1600 / $img.Width)
        $w = [int]($img.Width * $escala); $h = [int]($img.Height * $escala)
        $bmp = New-Object Drawing.Bitmap $w, $h, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = 'HighQualityBicubic'
        $g.DrawImage($img, 0, 0, $w, $h); $g.Dispose()

        # Buscar el rectángulo con contenido (alfa > 20)
        $datos = $bmp.LockBits((New-Object Drawing.Rectangle 0, 0, $w, $h), 'ReadOnly', $bmp.PixelFormat)
        $bytes = New-Object byte[] ($datos.Stride * $h)
        [Runtime.InteropServices.Marshal]::Copy($datos.Scan0, $bytes, 0, $bytes.Length)
        $stride = $datos.Stride
        $bmp.UnlockBits($datos)
        $minX = $w; $minY = $h; $maxX = -1; $maxY = -1
        for ($y = 0; $y -lt $h; $y += 2) {
            $fila = $y * $stride
            for ($x = 0; $x -lt $w; $x += 2) {
                if ($bytes[$fila + $x * 4 + 3] -gt 20) {
                    if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
                    if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
                }
            }
        }
        if ($maxX -lt 0) { throw "La imagen quedó vacía: $origen" }
        $margen = 4
        $minX = [Math]::Max(0, $minX - $margen); $minY = [Math]::Max(0, $minY - $margen)
        $maxX = [Math]::Min($w - 1, $maxX + $margen); $maxY = [Math]::Min($h - 1, $maxY + $margen)
        $rect = New-Object Drawing.Rectangle $minX, $minY, ($maxX - $minX + 1), ($maxY - $minY + 1)

        $altoFinal = [int]($rect.Height * $ancho / $rect.Width)
        $salida = New-Object Drawing.Bitmap $ancho, $altoFinal, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g2 = [Drawing.Graphics]::FromImage($salida)
        $g2.InterpolationMode = 'HighQualityBicubic'
        $g2.DrawImage($bmp, (New-Object Drawing.Rectangle 0, 0, $ancho, $altoFinal), $rect, 'Pixel')
        $g2.Dispose()
        $salida.Save($destino, [Drawing.Imaging.ImageFormat]::Png)
        $salida.Dispose(); $bmp.Dispose()
    } finally { $img.Dispose() }
}

$Originales = Join-Path $PSScriptRoot 'originales'
New-Item -ItemType Directory -Force $Originales, $DirImg | Out-Null

foreach ($f in $Lista | Where-Object { -not $Fotos -or $Fotos -contains $_.id }) {
    $ext = if ($f.tipo -eq 'capa') { 'png' } else { 'jpg' }
    $destino = Join-Path $DirImg "$($f.id).$ext"
    if ((Test-Path $destino) -and -not $Rehacer) { Write-Host "[$($f.id)] ya existe, se salta"; continue }

    Write-Host "[$($f.id)] generando..."
    $ar = if ($f.tipo -eq 'capa') { '16:9' } else { $f.ar }
    $r = Invocar-Fal $ModeloFoto @{ prompt = $f.prompt; aspect_ratio = $ar; raw = $false; num_images = 1; output_format = 'jpeg'; safety_tolerance = '2' }
    $original = Join-Path $Originales "$($f.id).jpg"
    Invoke-WebRequest -Uri $r.images[0].url -OutFile $original

    if ($f.tipo -eq 'capa') {
        Write-Host "[$($f.id)] quitando fondo..."
        $sinFondo = Invocar-Fal $ModeloFondo @{ image_url = $r.images[0].url; output_format = 'png' }
        $png = Join-Path $Originales "$($f.id)-sin-fondo.png"
        Invoke-WebRequest -Uri $sinFondo.image.url -OutFile $png
        Recortar-Png $png $destino $f.ancho
    } else {
        Optimizar-Jpg $original $destino $f.ancho
    }
    Write-Host "[$($f.id)] listo ($([math]::Round((Get-Item $destino).Length / 1KB)) KB)"
}
