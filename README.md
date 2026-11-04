# Fasón 360 – Capacidad ociosa industrial + logística integral

PoC de Datos Georreferenciados · ISFT N° 199 – Logística. Stack: Supabase + React/Vite + deck.gl + Vercel.

## Descripción del proyecto (máx. 5 líneas)

Muchas pymes industriales del GBA tienen máquinas paradas, mientras otras empresas necesitan producir tiradas cortas y no tienen planta.
Armamos un dataset de 45 máquinas en parques industriales reales del GBA y 16 pedidos de prueba (datos simulados para la PoC).
El mapa muestra cada máquina con horas libres por proceso (inyección, extrusión, CNC, router, láser) y los pedidos con su recorrido cliente → planta.
Permite ver dónde está la capacidad ociosa, el estado logístico de cada pedido y qué planta conviene según cercanía y horas disponibles.
Incluye cotización estimada (fasón + flete). En una segunda versión: carga real de capacidad y tarifas por las pymes, ruteo de retiros y entregas, y seguimiento con OEE.

## Propuesta de valor

Gestión integral del fasón: **retiro de materia prima en el cliente → proceso en la planta con capacidad ociosa → entrega del producto terminado**. El cliente no busca taller ni contrata flete: pide horas de un proceso y recibe la pieza.

Diferencial frente a plataformas como Xometry: es geográfica y local (cercanía = menos flete y menos lead time), muestra la capacidad libre real de la semana e incluye la logística.

## Contenido

| Archivo | Para qué sirve |
|---|---|
| `dataset_maquinas.csv` | 45 máquinas (tabla `puntos`): proceso, horas libres, ocupación, parque industrial |
| `dataset_pedidos.csv` | 16 pedidos (tabla `pedidos`): cliente, planta asignada, estado, km logísticos |
| `supabase.sql` | Crea las dos tablas, habilita lectura pública y carga los datos |
| `src/App.jsx` | Consulta a Supabase, indicadores, mapa deck.gl, tooltip y simulador |
| `public/datos_ejemplo.json` | Copia de los datos para el modo demo (solo si falta configurar Supabase) |

Tabla `puntos`: `categoria` = proceso · `valor` = horas-máquina libres en la semana · `tarifa_hora` = precio de referencia en ARS por hora-máquina (simulado).
Tabla `pedidos`: `estado` = Retiro de materia prima / En proceso / Entrega en camino / Entregado · `km_logistica` = ida con MP + vuelta con producto.

## Qué muestra la app

- **4 indicadores** calculados con los datos de Supabase: máquinas con capacidad ociosa, horas libres de la semana, pedidos en curso y km de logística gestionados.
- **Mapa deck.gl**: puntos de máquinas por color de proceso (tamaño = horas libres), arcos cliente → planta por estado del pedido, mapa de calor opcional (HeatmapLayer, desafío nivel 2) y filtro por proceso.
- **Tooltip** al pasar el mouse: empresa, máquina, proceso, horas libres, ocupación; o datos del pedido.
- **Simulador de pedido**: click en el mapa para ubicar la empresa cliente, elegir proceso y horas necesarias → las 3 plantas con horas suficientes (ordenadas por menor costo total o por cercanía), con km, tiempo de traslado y **cotización**: fasón (horas × tarifa) + flete (km × $/km).
- **Cotización de pedidos**: el tooltip de cada pedido muestra su costo estimado (fasón + flete).

## Pasos

### 1. Supabase (≈10 min)
1. https://supabase.com → New project.
2. **SQL Editor** → New query → pegar todo `supabase.sql` → **Run**. La última consulta tiene que devolver `45`, `16` y `45` máquinas con tarifa.
3. **Table Editor**: verificar las tablas `puntos` y `pedidos`.
4. **Project Settings → API** (o *Data API / API Keys*): copiar **Project URL** y la clave **anon / publishable**. Nunca usar la `service_role`.

### 2. Probar en la PC (≈10 min)
Requiere Node.js 20 o superior (https://nodejs.org).
```bash
npm install
cp .env.example .env      # en Windows: copy .env.example .env
# editar .env y pegar la URL y la clave anon
npm run dev
```
Abrir http://localhost:5173. Arriba a la derecha tiene que decir **"Datos desde Supabase"**. Con F12 → Consola se ven los `console.log` de las consultas (Etapa 4).

### 3. GitHub (≈5 min)
```bash
git init && git add . && git commit -m "PoC Fason 360"
git branch -M main
git remote add origin https://github.com/USUARIO/fason-360.git
git push -u origin main
```
O desde la web: crear repo → *Add file → Upload files* (sin `node_modules` ni `.env`).

### 4. Vercel (≈5 min)
1. https://vercel.com → entrar con GitHub → **Add New → Project** → importar el repo.
2. Framework: **Vite**.
3. **Environment Variables**: `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`.
4. **Deploy** → abrir la URL desde el celular para comprobar. Si cargan las variables después, hacer **Redeploy**.

### 5. Entrega
URL de Vercel · captura del tablero (desde la URL publicada) · link al repo · los dos CSV · la descripción de arriba.

## Supuestos del simulador
Distancia = línea recta × 1,3 (factor de ruta urbana) · velocidad promedio 35 km/h en el conurbano · flete $ 1.800 por km (ida + vuelta) · tarifas por hora entre $ 18.500 (router madera) y $ 51.500 (centro de mecanizado grande), según proceso y tamaño de máquina. Valores de referencia simulados, en ARS sin IVA. El flete y los supuestos de distancia son parámetros al inicio de `App.jsx`; las tarifas están en la columna `tarifa_hora` de Supabase.
