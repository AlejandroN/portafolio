// Genera con IA (fal.ai, FLUX Pro Ultra) la mesa y las texturas del cuaderno de Alewox.
// Uso: node ia.mjs            (todas)  ·  node ia.mjs mesa   (solo esa)
// Necesita la variable de entorno FAL_KEY. Cada imagen cuesta unos 6 centavos de dólar.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const MODELO = "fal-ai/flux-pro/v1.1-ultra";
const ESTILO = "photorealistic, high detail, no text, no words, no letters, no logos, no watermark, no people, no hands";
const clave = (process.env.FAL_KEY || "").replace(/\s/g, "");
if (!clave) throw new Error("Falta la variable de entorno FAL_KEY (tu clave de fal.ai).");

const MESA = "Top-down flat lay photograph shot from directly above of a dark walnut wooden desk at night, warm golden light from an unseen desk lamp at the upper left casting a soft pool of light in the center, a white ceramic cup of black coffee near the top right corner, a yellow wooden pencil near the right edge, a small green succulent in a terracotta pot near the top left corner, a black smartphone face down near the bottom left corner, the entire large central area of the desk is completely empty and clear wood, there are no books, no notebooks, no papers and no keyboard anywhere, subtle wood grain, soft realistic shadows, cozy and cinematic";
const imagenes = [
  { archivo: "mesa.jpg", ar: "16:9", prompt: MESA },
  { archivo: "mesa-cel.jpg", ar: "9:16", prompt: MESA },
  { archivo: "papel.jpg", ar: "3:4", prompt: "Flat top-down macro photograph of blank cream colored paper filling the entire frame edge to edge, completely plain with no lines, soft even warm light, subtle natural paper fiber texture, very slight vignette" },
  { archivo: "pasta.jpg", ar: "3:4", prompt: "Flat top-down photograph of dark brown leather filling the entire frame edge to edge, fine natural leather grain, soft warm light from the upper left, subtle wear, no stitching, no objects" },
];

async function generar(prompt, ar) {
  const headers = { Authorization: `Key ${clave}`, "Content-Type": "application/json" };
  const cola = await fetch(`https://queue.fal.run/${MODELO}`, {
    method: "POST", headers,
    body: JSON.stringify({ prompt: `${prompt}, ${ESTILO}`, aspect_ratio: ar, num_images: 1, output_format: "jpeg", safety_tolerance: "2" }),
  }).then((r) => r.json());
  if (!cola.status_url) throw new Error(`fal.ai no aceptó la imagen: ${JSON.stringify(cola).slice(0, 200)}`);
  for (let i = 0; i < 200; i++) {
    await new Promise((r) => setTimeout(r, 3000));
    if ((await fetch(cola.status_url, { headers }).then((r) => r.json())).status === "COMPLETED") break;
  }
  const resultado = await fetch(cola.response_url, { headers }).then((r) => r.json());
  return Buffer.from(await fetch(resultado.images[0].url).then((r) => r.arrayBuffer()));
}

const dir = path.join(AQUI, "originales");
fs.mkdirSync(dir, { recursive: true });
const solo = process.argv.slice(2);
for (const f of imagenes.filter((f) => !solo.length || solo.includes(f.archivo.replace(".jpg", "")))) {
  process.stdout.write(`Generando ${f.archivo}… `);
  fs.writeFileSync(path.join(dir, f.archivo), await generar(f.prompt, f.ar));
  console.log("listo");
}
