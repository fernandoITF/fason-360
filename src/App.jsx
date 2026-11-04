import { useEffect, useMemo, useState } from 'react'
import DeckGL, { ScatterplotLayer, ArcLayer, LineLayer, HeatmapLayer } from 'deck.gl'
import { Map } from 'react-map-gl/maplibre'
import { supabase } from './supabaseClient'

const MAP_STYLE = 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json'
const VISTA_INICIAL = { longitude: -58.6, latitude: -34.6, zoom: 9, pitch: 25, bearing: 0 }

// Color por proceso productivo
const PROCESOS = {
  'Inyección': [37, 99, 235],
  'Extrusión': [147, 51, 234],
  'Torno CNC': [234, 88, 12],
  'Centro de mecanizado': [220, 38, 38],
  'Router CNC madera': [101, 163, 13],
  'Corte láser': [8, 145, 178],
}
// Color por estado del pedido (logística integral)
const ESTADOS = {
  'Retiro de materia prima': [234, 179, 8],
  'En proceso': [37, 99, 235],
  'Entrega en camino': [147, 51, 234],
  'Entregado': [100, 116, 139],
}
const VEL_PROMEDIO_KMH = 35 // tránsito urbano / conurbano
const FACTOR_RUTA = 1.3 // línea recta -> distancia por calle

const fmt = (n) => Number(n).toLocaleString('es-AR')
const rgb = (c) => `rgb(${c.join(',')})`

function distanciaKm([lng1, lat1], [lng2, lat2]) {
  const R = 6371
  const toRad = (g) => (g * Math.PI) / 180
  const dLat = toRad(lat2 - lat1)
  const dLng = toRad(lng2 - lng1)
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2
  return 2 * R * Math.asin(Math.sqrt(h)) * FACTOR_RUTA
}

export default function App() {
  const [maquinas, setMaquinas] = useState([])
  const [pedidos, setPedidos] = useState([])
  const [estado, setEstado] = useState('cargando')
  const [error, setError] = useState('')
  const [filtro, setFiltro] = useState('Todos')
  const [verPedidos, setVerPedidos] = useState(true)
  const [verCalor, setVerCalor] = useState(false)
  const [visitas, setVisitas] = useState(null)
  const [hover, setHover] = useState(null)

  // Simulador de pedido
  const [procesoSim, setProcesoSim] = useState('Inyección')
  const [horasSim, setHorasSim] = useState(8)
  const [cliente, setCliente] = useState([-58.3816, -34.6037]) // Obelisco por defecto

  // Contador de visitas: suma 1 por sesión de navegador y muestra el total
  useEffect(() => {
    if (!supabase) return
    let yaContada = false
    try { yaContada = sessionStorage.getItem('fason360_visita') === '1' } catch (e) {}
    async function contar() {
      if (yaContada) {
        const { data } = await supabase.from('visitas').select('total').eq('id', 1).single()
        if (data) setVisitas(data.total)
        return
      }
      try { sessionStorage.setItem('fason360_visita', '1') } catch (e) {}
      const { data, error } = await supabase.rpc('registrar_visita')
      if (!error) setVisitas(data)
    }
    contar()
  }, [])

  // Etapa 4: consulta a Supabase
  useEffect(() => {
    async function cargar() {
      if (!supabase) {
        const res = await fetch('/datos_ejemplo.json')
        const demo = await res.json()
        setMaquinas(demo.maquinas)
        setPedidos(demo.pedidos)
        setEstado('demo')
        return
      }
      const [m, p] = await Promise.all([
        supabase.from('puntos').select('*').order('id'),
        supabase.from('pedidos').select('*').order('id'),
      ])
      if (m.error || p.error) {
        setError((m.error || p.error).message)
        setEstado('error')
        return
      }
      console.log('Máquinas desde Supabase:', m.data)
      console.log('Pedidos desde Supabase:', p.data)
      setMaquinas(m.data)
      setPedidos(p.data)
      setEstado('ok')
    }
    cargar()
  }, [])

  const maqVisibles = useMemo(
    () => (filtro === 'Todos' ? maquinas : maquinas.filter((d) => d.categoria === filtro)),
    [maquinas, filtro]
  )
  const pedVisibles = useMemo(
    () => (filtro === 'Todos' ? pedidos : pedidos.filter((d) => d.proceso === filtro)),
    [pedidos, filtro]
  )

  // Etapa 7: indicadores calculados con los datos de Supabase
  const kpi = useMemo(() => {
    const horas = maquinas.reduce((s, d) => s + d.valor, 0)
    const activos = pedidos.filter((p) => p.estado !== 'Entregado').length
    const km = pedidos.reduce((s, p) => s + p.km_logistica, 0)
    const ocup = maquinas.length ? Math.round(maquinas.reduce((s, d) => s + d.ocupacion_pct, 0) / maquinas.length) : 0
    return { maquinas: maquinas.length, horas, activos, km, ocup }
  }, [maquinas, pedidos])

  // Simulador: plantas más cercanas con horas suficientes para el proceso elegido
  const sugeridas = useMemo(() => {
    return maquinas
      .filter((m) => m.categoria === procesoSim && m.valor >= horasSim)
      .map((m) => {
        const km = distanciaKm(cliente, [m.longitud, m.latitud])
        return { ...m, kmIda: km, kmTotal: km * 2, minutos: Math.round((km / VEL_PROMEDIO_KMH) * 60) }
      })
      .sort((a, b) => a.kmIda - b.kmIda)
      .slice(0, 3)
  }, [maquinas, procesoSim, horasSim, cliente])

  // Etapa 5: capas de deck.gl (posición = [longitud, latitud])
  const capas = [
    verCalor &&
      new HeatmapLayer({
        id: 'calor',
        data: maqVisibles,
        getPosition: (d) => [d.longitud, d.latitud],
        getWeight: (d) => d.valor,
        radiusPixels: 70,
      }),
    verPedidos &&
      new ArcLayer({
        id: 'pedidos',
        data: pedVisibles,
        getSourcePosition: (d) => [d.cliente_lng, d.cliente_lat],
        getTargetPosition: (d) => [d.planta_lng, d.planta_lat],
        getSourceColor: (d) => [...ESTADOS[d.estado], 230],
        getTargetColor: (d) => [...ESTADOS[d.estado], 230],
        getWidth: 3,
        getHeight: 0.5,
        pickable: true,
      }),
    verPedidos &&
      new ScatterplotLayer({
        id: 'clientes',
        data: pedVisibles,
        getPosition: (d) => [d.cliente_lng, d.cliente_lat],
        getFillColor: [255, 255, 255],
        getLineColor: (d) => ESTADOS[d.estado],
        stroked: true,
        lineWidthMinPixels: 3,
        radiusMinPixels: 5,
        getRadius: 150,
        pickable: true,
      }),
    new ScatterplotLayer({
      id: 'maquinas',
      data: maqVisibles,
      getPosition: (d) => [d.longitud, d.latitud],
      getFillColor: (d) => [...PROCESOS[d.categoria], 220],
      getLineColor: [255, 255, 255],
      stroked: true,
      lineWidthMinPixels: 1,
      getRadius: (d) => 60 + d.valor * 12,
      radiusMinPixels: 6,
      radiusMaxPixels: 20,
      pickable: true,
    }),
    new LineLayer({
      id: 'sim-lineas',
      data: sugeridas,
      getSourcePosition: () => cliente,
      getTargetPosition: (d) => [d.longitud, d.latitud],
      getColor: [15, 23, 42],
      getWidth: 3,
    }),
    new ScatterplotLayer({
      id: 'sim-cliente',
      data: [{ pos: cliente }],
      getPosition: (d) => d.pos,
      getFillColor: [15, 23, 42],
      getLineColor: [250, 204, 21],
      stroked: true,
      lineWidthMinPixels: 3,
      radiusMinPixels: 8,
      getRadius: 300,
    }),
  ].filter(Boolean)

  // Etapa 6: información al pasar el mouse
  const tooltip = ({ object, layer }) => {
    if (!object) return null
    if (layer.id === 'maquinas')
      return {
        html: `<b>${object.nombre}</b><br/>
          Proceso: <b>${object.categoria}</b><br/>
          Horas libres esta semana: <b>${object.valor} h</b><br/>
          Ocupación actual: ${object.ocupacion_pct}%<br/>
          ${object.parque} · ${object.partido}`,
      }
    if (layer.id === 'pedidos' || layer.id === 'clientes')
      return {
        html: `<b>${object.codigo} · ${object.cliente}</b><br/>
          Proceso: ${object.proceso} en ${object.planta}<br/>
          Estado: <b>${object.estado}</b><br/>
          ${object.horas_maquina} h máquina · ${object.km_logistica} km (MP + entrega)<br/>
          Lead time: ${object.lead_time_dias} días`,
      }
    return null
  }

  // Click / toque: sobre un punto muestra su info (útil en celular); en el mapa ubica la empresa del simulador
  const alHacerClick = (info) => {
    const t = info.object ? tooltip(info) : null
    if (t) {
      setHover({ x: info.x, y: info.y, w: info.viewport?.width || 800, h: info.viewport?.height || 420, html: t.html })
      return
    }
    setHover(null)
    if (info.coordinate) setCliente(info.coordinate)
  }

  return (
    <div className="app">
      <header>
        <div>
          <h1>Fasón 360 · Capacidad ociosa industrial + logística integral</h1>
          <p className="sub">Máquinas con horas libres en el GBA. Retiramos la materia prima, se procesa en la planta más cercana y entregamos el producto terminado.</p>
        </div>
        {estado === 'demo' && <span className="badge demo">Modo demo: falta configurar Supabase</span>}
        <div className="badges">
          {visitas !== null && <span className="badge visitas">{visitas.toLocaleString('es-AR')} visitas</span>}
          {estado === 'ok' && <span className="badge ok">Datos desde Supabase</span>}
        </div>
      </header>

      {estado === 'error' && <div className="error">Error al consultar Supabase: {error}</div>}

      <section className="kpis">
        <div className="kpi"><span className="num">{kpi.maquinas}</span><span className="lbl">Máquinas con capacidad ociosa</span></div>
        <div className="kpi destacado"><span className="num">{fmt(kpi.horas)} h</span><span className="lbl">Horas-máquina libres esta semana</span></div>
        <div className="kpi"><span className="num">{kpi.activos}</span><span className="lbl">Pedidos en curso (de {pedidos.length})</span></div>
        <div className="kpi"><span className="num">{fmt(kpi.km)} km</span><span className="lbl">Logística gestionada (MP + entregas)</span></div>
      </section>

      <section className="controles">
        <div className="grupo">
          {['Todos', ...Object.keys(PROCESOS)].map((c) => (
            <button key={c} className={filtro === c ? 'activo' : ''} onClick={() => setFiltro(c)}>
              {c !== 'Todos' && <i className="dot" style={{ background: rgb(PROCESOS[c]) }} />}
              {c}
            </button>
          ))}
        </div>
        <label><input type="checkbox" checked={verPedidos} onChange={(e) => setVerPedidos(e.target.checked)} /> Pedidos y logística</label>
        <label><input type="checkbox" checked={verCalor} onChange={(e) => setVerCalor(e.target.checked)} /> Mapa de calor (horas libres)</label>
      </section>

      <div className="cuerpo">
        <div className="mapa">
          <DeckGL
            initialViewState={VISTA_INICIAL}
            controller={true}
            layers={capas}
            onHover={(info) => {
              const t = info.object ? tooltip(info) : null
              setHover(t ? { x: info.x, y: info.y, w: info.viewport?.width || 800, h: info.viewport?.height || 420, html: t.html } : null)
            }}
            getCursor={({ isHovering, isDragging }) => (isDragging ? 'grabbing' : isHovering ? 'pointer' : 'grab')}
            onClick={alHacerClick}
          >
            <Map mapStyle={MAP_STYLE} />
          </DeckGL>
          {hover && (
            <div
              className="tooltip"
              style={{
                left: hover.x + 12,
                top: hover.y + 12,
                transform: `translate(${hover.x > hover.w - 280 ? 'calc(-100% - 24px)' : '0'}, ${hover.y > hover.h - 140 ? 'calc(-100% - 24px)' : '0'})`,
              }}
              dangerouslySetInnerHTML={{ __html: hover.html }}
            />
          )}
          <div className="leyenda">
            <b>Estado del pedido</b>
            {Object.entries(ESTADOS).map(([k, c]) => (
              <div key={k}><i className="dot" style={{ background: rgb(c) }} /> {k}</div>
            ))}
            <small>Arco: cliente → planta · Tamaño del punto = horas libres</small>
          </div>
        </div>

        <aside className="panel">
          <h2>Simular un pedido</h2>
          <p className="ayuda">Hacé click en el mapa para ubicar tu empresa.</p>
          <label className="campo">Proceso
            <select value={procesoSim} onChange={(e) => setProcesoSim(e.target.value)}>
              {Object.keys(PROCESOS).map((p) => <option key={p}>{p}</option>)}
            </select>
          </label>
          <label className="campo">Horas de máquina necesarias
            <input type="number" min="1" max="60" value={horasSim} onChange={(e) => setHorasSim(Number(e.target.value) || 1)} />
          </label>
          <h3>Plantas sugeridas</h3>
          {sugeridas.length === 0 && <p className="ayuda">No hay máquinas con esas horas libres esta semana.</p>}
          {sugeridas.map((s, i) => (
            <div className="sug" key={s.id}>
              <div className="sug-top"><span className="rank">{i + 1}</span><b>{s.empresa}</b></div>
              <div>{s.nombre.split('– ')[1]} · {s.parque}</div>
              <div><b>{s.valor} h</b> libres · {fmt(Math.round(s.kmIda))} km · ~{s.minutos} min de traslado</div>
              <div className="log">Logística integral: {fmt(Math.round(s.kmTotal))} km (retiro de MP + entrega)</div>
            </div>
          ))}
        </aside>
      </div>
    </div>
  )
}
