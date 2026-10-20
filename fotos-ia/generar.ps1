<#
  Genera las fotos de las páginas de muestra con fal.ai (FLUX Pro Ultra)
  y las guarda optimizadas para web en <pagina>\img\.

    .\generar.ps1                       # genera las que faltan
    .\generar.ps1 -Fotos taco-hero      # solo algunas
    .\generar.ps1 -Fotos taco-hero -Rehacer

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

$Modelo = 'fal-ai/flux-pro/v1.1-ultra'
$Raiz = Split-Path $PSScriptRoot -Parent
$Estilo = 'professional commercial photography, natural light, sharp focus, realistic textures, photorealistic, no text, no watermark, no logos'

$Lista = @(
    # Taquería
    @{ id = 'taco-hero';     pagina = 'taqueria'; ar = '1:1'; ancho = 900
       prompt = "Overhead close-up of three Mexican al pastor tacos on a dark rustic clay plate, pineapple, cilantro, white onion, lime wedges and red salsa, warm night street-food lighting, $Estilo" }
    @{ id = 'taco-trompo';   pagina = 'taqueria'; ar = '4:3'; ancho = 1000
       prompt = "Al pastor trompo spit roasting at a Mexican taquería at night, a taquero's hands slicing marinated pork with a long knife, glowing embers, warm orange light, shallow depth of field, $Estilo" }
    @{ id = 'taco-local';    pagina = 'taqueria'; ar = '4:3'; ancho = 1000
       prompt = "Cozy small Mexican taquería at night seen from the street, colorful papel picado, red plastic stools, warm string lights, steam rising from the grill, no signs, no lettering anywhere, $Estilo" }
    @{ id = 'taco-gringa';   pagina = 'taqueria'; ar = '4:3'; ancho = 1000
       prompt = "Close-up of a Mexican gringa: flour tortilla with al pastor pork and melted cheese, cut in half showing cheese pull, on a paper-lined tray, warm light, $Estilo" }
    # Estética
    @{ id = 'estetica-hero';     pagina = 'estetica'; ar = '3:4'; ancho = 900
       prompt = "Elegant modern beauty salon interior, blush pink and cream tones, velvet styling chair in front of an arched mirror, dried flowers, soft natural window light, calm luxurious mood, $Estilo" }
    @{ id = 'estetica-balayage'; pagina = 'estetica'; ar = '3:4'; ancho = 800
       prompt = "Woman with long glossy wavy caramel balayage hair seen from behind in a bright salon, soft natural light, $Estilo" }
    @{ id = 'estetica-unas';     pagina = 'estetica'; ar = '1:1'; ancho = 700
       prompt = "Close-up of hands with an elegant pastel pink gel manicure resting on a cream towel, minimal background, soft light, $Estilo" }
    @{ id = 'estetica-novia';    pagina = 'estetica'; ar = '1:1'; ancho = 700
       prompt = "Bridal updo hairstyle with small pearl pins, seen from behind, soft romantic light, blurred salon background, $Estilo" }
    @{ id = 'estetica-facial';   pagina = 'estetica'; ar = '16:9'; ancho = 1100
       prompt = "Relaxing facial treatment at a spa, woman lying with eyes closed, towel wrapped on her head, esthetician's hands applying cream, calm warm atmosphere, $Estilo" }
    @{ id = 'estetica-salon';    pagina = 'estetica'; ar = '16:9'; ancho = 1100
       prompt = "Wide view of a bright minimalist beauty salon with three styling stations, round mirrors, plants and pink accents, nobody inside, $Estilo" }
    # Taller
    @{ id = 'taller-hero';        pagina = 'taller'; ar = '1:1'; ancho = 900
       prompt = "Mechanic in dark work uniform working under a car raised on a lift in a clean modern auto repair shop, orange accent lights, dramatic lighting, $Estilo" }
    @{ id = 'taller-frenos';      pagina = 'taller'; ar = '4:3'; ancho = 1000
       prompt = "Close-up of a mechanic with black gloves installing a new brake disc and caliper on a car wheel hub, workshop background, $Estilo" }
    @{ id = 'taller-diagnostico'; pagina = 'taller'; ar = '4:3'; ancho = 1000
       prompt = "Mechanic holding a diagnostic scanner tablet connected to a car under the dashboard, screen glowing, modern workshop, $Estilo" }
    @{ id = 'taller-aceite';      pagina = 'taller'; ar = '4:3'; ancho = 1000
       prompt = "Fresh golden motor oil being poured into a car engine, close-up, clean engine bay, workshop lighting, $Estilo" }

    # Segunda tanda: fotos en lugar de emojis
    @{ id = 'taco-suadero';    pagina = 'taqueria'; ar = '1:1'; ancho = 400
       prompt = "Close-up of two Mexican suadero tacos on small corn tortillas with chopped onion and cilantro, dark background, warm light, $Estilo" }
    @{ id = 'taco-campechano'; pagina = 'taqueria'; ar = '1:1'; ancho = 400
       prompt = "Close-up of a Mexican campechano taco with beef and crispy chorizo longaniza on a corn tortilla, onion and cilantro, dark background, warm light, $Estilo" }
    @{ id = 'taco-quesadilla'; pagina = 'taqueria'; ar = '1:1'; ancho = 400
       prompt = "Close-up of a Mexican corn quesadilla with melted Oaxaca cheese and meat, folded and cut, dark background, warm light, $Estilo" }
    @{ id = 'taco-agua';       pagina = 'taqueria'; ar = '1:1'; ancho = 400
       prompt = "Three tall glasses of Mexican aguas frescas: horchata, red jamaica and tamarind, with ice, on a rustic wooden table, warm light, $Estilo" }
    @{ id = 'taco-tortilla';   pagina = 'taqueria'; ar = '4:3'; ancho = 700
       prompt = "Hands pressing fresh corn tortillas from masa dough next to a hot comal with tortillas puffing up, Mexican kitchen, warm light, $Estilo" }
    @{ id = 'taco-salsas';     pagina = 'taqueria'; ar = '4:3'; ancho = 700
       prompt = "Three Mexican salsas in clay molcajete bowls: green tomatillo salsa, red chile de árbol salsa and orange habanero salsa, fresh chiles around, rustic table, $Estilo" }
    @{ id = 'estetica-corte';  pagina = 'estetica'; ar = '4:3'; ancho = 700
       prompt = "Hairstylist's hands cutting a woman's long brown hair with professional scissors and comb, bright salon, soft light, $Estilo" }
    @{ id = 'taller-afinacion';  pagina = 'taller'; ar = '4:3'; ancho = 700
       prompt = "Mechanic's gloved hands replacing a spark plug in a car engine during a tune-up, close-up, workshop lighting, $Estilo" }
    @{ id = 'taller-suspension'; pagina = 'taller'; ar = '4:3'; ancho = 700
       prompt = "Close-up of a car's front suspension with new shock absorber and coil spring, wheel removed, car on a lift, workshop lighting, $Estilo" }
    @{ id = 'taller-ac';         pagina = 'taller'; ar = '4:3'; ancho = 700
       prompt = "Mechanic connecting air conditioning recharge gauges and hoses to a car engine bay, close-up, workshop lighting, $Estilo" }

    # Generador de muestras de Alewox (tienda y consultorio)
    @{ id = 'tienda-hero';     pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 1000
       prompt = "Bright modern boutique store interior with clothing racks, wooden shelves with folded clothes and accessories, plants, warm natural light, nobody inside, $Estilo" }
    @{ id = 'tienda-ropa';     pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 700
       prompt = "Close-up of a clothing rack with neatly hung shirts and dresses in neutral colors in a boutique, soft light, $Estilo" }
    @{ id = 'tienda-regalos';  pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 700
       prompt = "Beautiful gift boxes wrapped with kraft paper and ribbons on a wooden counter of a small shop, candles and dried flowers, warm light, $Estilo" }
    @{ id = 'tienda-accesorios'; pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 700
       prompt = "Display of handbags, sunglasses and jewelry on minimalist shelves in a boutique, soft light, $Estilo" }
    @{ id = 'tienda-bolsas';   pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 700
       prompt = "Paper shopping bags with blank labels on a shop counter next to a card payment terminal, cozy boutique background blurred, $Estilo" }
    @{ id = 'consultorio-hero';  pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 1000
       prompt = "Modern bright medical clinic reception with white and light wood furniture, plants, clean minimalist design, nobody inside, $Estilo" }
    @{ id = 'consultorio-consulta'; pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 700
       prompt = "Doctor in white coat talking with a patient across a desk in a bright modern consulting room, faces not visible, hands and clipboard in focus, $Estilo" }
    @{ id = 'consultorio-equipo';   pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 700
       prompt = "Modern dental and medical examination chair in a spotless bright clinic room, soft daylight, nobody inside, $Estilo" }
    @{ id = 'consultorio-sala';     pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 700
       prompt = "Calm waiting room of a modern clinic with comfortable armchairs, plants and natural light, nobody inside, $Estilo" }
    @{ id = 'consultorio-detalle';  pagina = '..\mi-sitio\muestra'; ar = '4:3'; ancho = 700
       prompt = "Stethoscope, tablet and notebook on a clean white desk in a doctor's office, soft daylight, $Estilo" }

    # Página de Alewox: fotos cinematográficas
    @{ id = 'alewox-taqueria';  pagina = '..\mi-sitio'; ar = '16:9'; ancho = 1920
       prompt = "Full-frame cinematic photo at night of a Mexican taquero without hat, wearing a plain black t-shirt, slicing marinated al pastor pork from a vertical trompo spit with a long knife, pineapple on top, glowing grill and smoke, warm orange light on his face and hands, dark background with soft bokeh, moody, full bleed image without black bars, plain clothes, no signs, no lettering anywhere, $Estilo" }
    @{ id = 'alewox-barberia';  pagina = '..\mi-sitio'; ar = '16:9'; ancho = 1920
       prompt = "Cinematic film still inside a modern barbershop at dusk, a barber carefully trimming a client's beard, warm tungsten lights, dark walls, mirror reflections, moody and elegant, shallow depth of field, no lettering anywhere, $Estilo" }
    @{ id = 'alewox-taller';    pagina = '..\mi-sitio'; ar = '16:9'; ancho = 1920
       prompt = "Cinematic wide film still of an auto repair shop at golden hour in the Sonoran desert, a car raised on a lift, a mechanic as a silhouette, low sun flaring through the open garage door, dust floating in the warm light, moody, no lettering anywhere, $Estilo" }
    @{ id = 'alewox-cafe';      pagina = '..\mi-sitio'; ar = '16:9'; ancho = 1920
       prompt = "Cinematic film still of a young Mexican woman, owner of a small coffee shop, smiling behind the counter while looking at her smartphone, phone screen not visible, warm golden hour light through the window, espresso machine, shallow depth of field, no lettering anywhere, $Estilo" }
    @{ id = 'alewox-desierto';  pagina = '..\mi-sitio'; ar = '21:9'; ancho = 1920
       prompt = "Cinematic wide landscape of a Sonoran desert city at blue hour seen from a hill, warm city lights glowing in the valley, saguaro cactus silhouettes in the foreground, mountains on the horizon, deep blue and orange tones, $Estilo" }
    @{ id = 'alewox-estudio';   pagina = '..\mi-sitio'; ar = '3:4'; ancho = 900
       prompt = "Dark moody wooden desk at night with an open laptop seen from the side, its screen glowing with soft abstract orange and blue gradient shapes, a coffee cup, a pair of glasses and a smartphone face down, warm orange desk lamp, plant, cinematic, shallow depth of field, no paper, no notebook, no words, no letters anywhere, $Estilo" }
    @{ id = 'alewox-celular';   pagina = '..\mi-sitio'; ar = '3:4'; ancho = 900
       prompt = "Close-up of a hand holding a smartphone inside a busy Mexican restaurant at night, screen glowing softly and out of focus, warm bokeh lights in the background, cinematic, no readable text, $Estilo" }
    @{ id = 'alewox-mostrador'; pagina = '..\mi-sitio'; ar = '3:4'; ancho = 900
       prompt = "Small plain black acrylic stand holding a white card with only a QR code printed on it, on the wooden counter of a cozy Mexican restaurant, warm lights, shallow depth of field, cinematic, the card and the stand have absolutely no words, no letters, no logos, $Estilo" }
)

function Invocar-Fal($cuerpo) {
    if (-not $env:FAL_KEY) { throw 'Falta FAL_KEY.' }
    $headers = @{ Authorization = "Key $($env:FAL_KEY -replace '\s', '')" }
    $json = $cuerpo | ConvertTo-Json -Depth 5
    $cola = Invoke-RestMethod -Method Post -Uri "https://queue.fal.run/$Modelo" -Headers $headers `
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
function Optimizar($origen, $destino, $ancho) {
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

$Originales = Join-Path $PSScriptRoot 'originales'
New-Item -ItemType Directory -Force $Originales | Out-Null

foreach ($f in $Lista | Where-Object { -not $Fotos -or $Fotos -contains $_.id }) {
    $dirImg = Join-Path $Raiz "$($f.pagina)\img"
    New-Item -ItemType Directory -Force $dirImg | Out-Null
    $destino = Join-Path $dirImg "$($f.id).jpg"
    if ((Test-Path $destino) -and -not $Rehacer) { Write-Host "[$($f.id)] ya existe, se salta"; continue }
    Write-Host "[$($f.id)] generando..."
    $r = Invocar-Fal @{ prompt = $f.prompt; aspect_ratio = $f.ar; raw = $false; num_images = 1; output_format = 'jpeg'; safety_tolerance = '2' }
    $original = Join-Path $Originales "$($f.id).jpg"
    Invoke-WebRequest -Uri $r.images[0].url -OutFile $original
    Optimizar $original $destino $f.ancho
    Write-Host "[$($f.id)] listo ($([math]::Round((Get-Item $destino).Length / 1KB)) KB)"
}
