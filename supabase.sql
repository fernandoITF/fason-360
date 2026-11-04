-- TP PoC Datos Georreferenciados - Fasón 360
-- Capacidad ociosa industrial + logística integral
-- Pegar completo en Supabase > SQL Editor > Run

drop table if exists public.pedidos;
drop table if exists public.puntos;

-- Tabla principal (la que pide la consigna): máquinas con capacidad ociosa
create table public.puntos (
  id integer primary key,
  nombre text not null,              -- empresa + máquina
  empresa text,
  categoria text not null,           -- proceso: Inyección, Extrusión, Torno CNC, etc.
  latitud double precision not null,
  longitud double precision not null,
  valor integer not null,            -- horas-máquina libres en la semana
  ocupacion_pct integer,             -- ocupación actual de la máquina
  parque text,
  partido text,
  fecha date,                        -- semana publicada
  descripcion text
);

-- Pedidos con gestión integral: retiro de MP en cliente -> fasón en planta -> entrega
create table public.pedidos (
  id integer primary key,
  codigo text,
  cliente text,
  proceso text,
  cliente_lat double precision,
  cliente_lng double precision,
  maquina_id integer references public.puntos(id),
  planta text,
  planta_lat double precision,
  planta_lng double precision,
  estado text,                       -- Retiro de materia prima / En proceso / Entrega en camino / Entregado
  horas_maquina integer,
  km_logistica integer,              -- km ida (MP) + vuelta (producto terminado)
  lead_time_dias integer,
  fecha date
);

alter table public.puntos enable row level security;
alter table public.pedidos enable row level security;
create policy "lectura publica puntos" on public.puntos for select to anon using (true);
create policy "lectura publica pedidos" on public.pedidos for select to anon using (true);

insert into public.puntos (id,nombre,empresa,categoria,latitud,longitud,valor,ocupacion_pct,parque,partido,fecha,descripcion) values
  (1,'Plásticos Litoral SAS – Inyectora 120 t','Plásticos Litoral SAS','Inyección',-34.70122,-58.58144,36,50,'Zona Ind. La Matanza','La Matanza','2026-10-26','36 h libres esta semana · ocupación 50%'),
  (2,'Plásticos Norte SA – Inyectora 180 t','Plásticos Norte SA','Inyección',-34.46271,-58.75058,12,88,'PI Tortuguitas','Malvinas Argentinas','2026-10-26','12 h libres esta semana · ocupación 88%'),
  (3,'Plásticos Pampa SA – Inyectora 250 t','Plásticos Pampa SA','Inyección',-34.47982,-58.74257,6,95,'PI Tortuguitas','Malvinas Argentinas','2026-10-26','6 h libres esta semana · ocupación 95%'),
  (4,'Plásticos Litoral SRL – Inyectora 80 t','Plásticos Litoral SRL','Inyección',-34.84927,-58.5114,6,94,'PI Ezeiza','Ezeiza','2026-10-26','6 h libres esta semana · ocupación 94%'),
  (5,'Plásticos Oeste SA – Inyectora 350 t','Plásticos Oeste SA','Inyección',-34.43744,-58.87619,22,8,'PI Pilar','Pilar','2026-10-26','22 h libres esta semana · ocupación 8%'),
  (6,'Plásticos del Sur SAS – Inyectora 80 t','Plásticos del Sur SAS','Inyección',-34.17731,-58.97639,36,25,'PI Campana','Campana','2026-10-26','36 h libres esta semana · ocupación 25%'),
  (7,'Plásticos Express SA – Inyectora 180 t','Plásticos Express SA','Inyección',-34.70628,-58.59224,8,92,'Zona Ind. La Matanza','La Matanza','2026-10-26','8 h libres esta semana · ocupación 92%'),
  (8,'Plásticos Norte SA – Inyectora 80 t','Plásticos Norte SA','Inyección',-34.78649,-58.18506,22,8,'PI Plátanos','Berazategui','2026-10-26','22 h libres esta semana · ocupación 8%'),
  (9,'Plásticos Industrial SRL – Inyectora 80 t','Plásticos Industrial SRL','Inyección',-34.17502,-58.9804,6,75,'PI Campana','Campana','2026-10-26','6 h libres esta semana · ocupación 75%'),
  (10,'Plásticos Pampa SAS – Inyectora 120 t','Plásticos Pampa SAS','Inyección',-34.71299,-58.58499,8,89,'Zona Ind. La Matanza','La Matanza','2026-10-26','8 h libres esta semana · ocupación 89%'),
  (11,'Extrusiones del Sur SA – Extrusora monohusillo Ø45 mm','Extrusiones del Sur SA','Extrusión',-34.7758,-58.18391,24,50,'PI Plátanos','Berazategui','2026-10-26','24 h libres esta semana · ocupación 50%'),
  (12,'Extrusiones Patagonia SRL – Extrusora monohusillo Ø60 mm','Extrusiones Patagonia SRL','Extrusión',-34.47609,-58.75957,22,8,'PI Tortuguitas','Malvinas Argentinas','2026-10-26','22 h libres esta semana · ocupación 8%'),
  (13,'Extrusiones Andina SA – Extrusora monohusillo Ø45 mm','Extrusiones Andina SA','Extrusión',-34.70979,-58.57835,30,25,'Zona Ind. La Matanza','La Matanza','2026-10-26','30 h libres esta semana · ocupación 25%'),
  (14,'Extrusiones Delta SRL – Extrusora monohusillo Ø60 mm','Extrusiones Delta SRL','Extrusión',-34.6169,-58.95189,46,4,'PI General Rodríguez','General Rodríguez','2026-10-26','46 h libres esta semana · ocupación 4%'),
  (15,'Extrusiones Norte SRL – Extrusora monohusillo Ø60 mm','Extrusiones Norte SRL','Extrusión',-34.47254,-58.74149,48,60,'PI Tortuguitas','Malvinas Argentinas','2026-10-26','48 h libres esta semana · ocupación 60%'),
  (16,'Extrusiones Delta SA – Extrusora monohusillo Ø45 mm','Extrusiones Delta SA','Extrusión',-34.4644,-58.66777,24,75,'PI Tigre (El Talar)','Tigre','2026-10-26','24 h libres esta semana · ocupación 75%'),
  (17,'Mecanizados Pampa SA – Torno CNC Ø400 mm de volteo','Mecanizados Pampa SA','Torno CNC',-34.42784,-58.74601,6,85,'PI OKS Garín','Escobar','2026-10-26','6 h libres esta semana · ocupación 85%'),
  (18,'Mecanizados Precisión SA – Torno CNC Ø320 mm de volteo','Mecanizados Precisión SA','Torno CNC',-34.83112,-58.38898,48,33,'PI Burzaco','Almirante Brown','2026-10-26','48 h libres esta semana · ocupación 33%'),
  (19,'Mecanizados Express SRL – Torno CNC Ø320 mm de volteo','Mecanizados Express SRL','Torno CNC',-34.8633,-58.5052,16,83,'PI Ezeiza','Ezeiza','2026-10-26','16 h libres esta semana · ocupación 83%'),
  (20,'Mecanizados Patagonia SAS – Torno CNC Ø250 mm de volteo','Mecanizados Patagonia SAS','Torno CNC',-34.8219,-58.25871,30,75,'PI Florencio Varela','Florencio Varela','2026-10-26','30 h libres esta semana · ocupación 75%'),
  (21,'Mecanizados Industrial SAS – Torno CNC Ø500 mm de volteo','Mecanizados Industrial SAS','Torno CNC',-34.62586,-58.95438,20,79,'PI General Rodríguez','General Rodríguez','2026-10-26','20 h libres esta semana · ocupación 79%'),
  (22,'Mecanizados Litoral SRL – Torno CNC Ø250 mm de volteo','Mecanizados Litoral SRL','Torno CNC',-34.5719,-58.53028,20,72,'Zona Ind. San Martín','San Martín','2026-10-26','20 h libres esta semana · ocupación 72%'),
  (23,'Mecanizados Norte SA – Torno CNC Ø320 mm de volteo','Mecanizados Norte SA','Torno CNC',-34.47652,-58.74858,48,50,'PI Tortuguitas','Malvinas Argentinas','2026-10-26','48 h libres esta semana · ocupación 50%'),
  (24,'Mecanizados Industrial SRL – Torno CNC Ø250 mm de volteo','Mecanizados Industrial SRL','Torno CNC',-34.45702,-58.66634,36,50,'PI Tigre (El Talar)','Tigre','2026-10-26','36 h libres esta semana · ocupación 50%'),
  (25,'Mecanizados Oeste SRL – Torno CNC Ø500 mm de volteo','Mecanizados Oeste SRL','Torno CNC',-34.47523,-58.74926,8,80,'PI Tortuguitas','Malvinas Argentinas','2026-10-26','8 h libres esta semana · ocupación 80%'),
  (26,'Matricería Pampa SRL – Centro de mecanizado 600 mm en X','Matricería Pampa SRL','Centro de mecanizado',-34.62623,-58.78541,12,88,'PI Moreno','Moreno','2026-10-26','12 h libres esta semana · ocupación 88%'),
  (27,'Matricería Pampa SAS – Centro de mecanizado 600 mm en X','Matricería Pampa SAS','Centro de mecanizado',-34.70015,-58.58518,6,75,'Zona Ind. La Matanza','La Matanza','2026-10-26','6 h libres esta semana · ocupación 75%'),
  (28,'Matricería Norte SA – Centro de mecanizado 1000 mm en X','Matricería Norte SA','Centro de mecanizado',-34.72039,-58.59453,8,80,'Zona Ind. La Matanza','La Matanza','2026-10-26','8 h libres esta semana · ocupación 80%'),
  (29,'Matricería Oeste SA – Centro de mecanizado 600 mm en X','Matricería Oeste SA','Centro de mecanizado',-34.83593,-58.24953,12,90,'PI Florencio Varela','Florencio Varela','2026-10-26','12 h libres esta semana · ocupación 90%'),
  (30,'Matricería Patagonia SAS – Centro de mecanizado 600 mm en X','Matricería Patagonia SAS','Centro de mecanizado',-34.85564,-58.52514,6,92,'PI Ezeiza','Ezeiza','2026-10-26','6 h libres esta semana · ocupación 92%'),
  (31,'Matricería Norte SRL – Centro de mecanizado 600 mm en X','Matricería Norte SRL','Centro de mecanizado',-34.82611,-58.4029,22,8,'PI Burzaco','Almirante Brown','2026-10-26','22 h libres esta semana · ocupación 8%'),
  (32,'Matricería Integral SAS – Centro de mecanizado 1300 mm en X','Matricería Integral SAS','Centro de mecanizado',-34.86423,-58.52083,24,67,'PI Ezeiza','Ezeiza','2026-10-26','24 h libres esta semana · ocupación 67%'),
  (33,'Carpintería del Sur SA – Router CNC mesa 2100x3100','Carpintería del Sur SA','Router CNC madera',-34.7109,-58.58901,40,58,'Zona Ind. La Matanza','La Matanza','2026-10-26','40 h libres esta semana · ocupación 58%'),
  (34,'Carpintería Patagonia SAS – Router CNC mesa 2100x3100','Carpintería Patagonia SAS','Router CNC madera',-34.41846,-58.75447,8,93,'PI OKS Garín','Escobar','2026-10-26','8 h libres esta semana · ocupación 93%'),
  (35,'Carpintería Andina SAS – Router CNC mesa 1300x2500','Carpintería Andina SAS','Router CNC madera',-34.71586,-58.60173,12,75,'Zona Ind. La Matanza','La Matanza','2026-10-26','12 h libres esta semana · ocupación 75%'),
  (36,'Carpintería Patagonia SRL – Router CNC mesa 1500x3000','Carpintería Patagonia SRL','Router CNC madera',-34.68293,-58.35026,36,70,'Zona Ind. Avellaneda','Avellaneda','2026-10-26','36 h libres esta semana · ocupación 70%'),
  (37,'Carpintería Industrial SA – Router CNC mesa 1300x2500','Carpintería Industrial SA','Router CNC madera',-34.61102,-58.95224,16,78,'PI General Rodríguez','General Rodríguez','2026-10-26','16 h libres esta semana · ocupación 78%'),
  (38,'Carpintería Oeste SRL – Router CNC mesa 2100x3100','Carpintería Oeste SRL','Router CNC madera',-34.8199,-58.40696,36,10,'PI Burzaco','Almirante Brown','2026-10-26','36 h libres esta semana · ocupación 10%'),
  (39,'Carpintería Patagonia SA – Router CNC mesa 1500x3000','Carpintería Patagonia SA','Router CNC madera',-34.4072,-58.75336,8,80,'PI OKS Garín','Escobar','2026-10-26','8 h libres esta semana · ocupación 80%'),
  (40,'Metalúrgica Andina SA – Láser fibra 12 kW','Metalúrgica Andina SA','Corte láser',-34.45506,-58.65882,36,62,'PI Tigre (El Talar)','Tigre','2026-10-26','36 h libres esta semana · ocupación 62%'),
  (41,'Metalúrgica Andina SAS – Láser fibra 6 kW','Metalúrgica Andina SAS','Corte láser',-34.64021,-58.80124,6,94,'PI Moreno','Moreno','2026-10-26','6 h libres esta semana · ocupación 94%'),
  (42,'Metalúrgica Andina SRL – Láser fibra 12 kW','Metalúrgica Andina SRL','Corte láser',-34.8335,-58.39642,6,94,'PI Burzaco','Almirante Brown','2026-10-26','6 h libres esta semana · ocupación 94%'),
  (43,'Metalúrgica Precisión SRL – Láser fibra 1.5 kW','Metalúrgica Precisión SRL','Corte láser',-34.71744,-58.58354,16,67,'Zona Ind. La Matanza','La Matanza','2026-10-26','16 h libres esta semana · ocupación 67%'),
  (44,'Metalúrgica Norte SAS – Láser fibra 3 kW','Metalúrgica Norte SAS','Corte láser',-34.71938,-58.58915,24,80,'Zona Ind. La Matanza','La Matanza','2026-10-26','24 h libres esta semana · ocupación 80%'),
  (45,'Metalúrgica Patagonia SAS – Láser fibra 1.5 kW','Metalúrgica Patagonia SAS','Corte láser',-34.45523,-58.66185,6,95,'PI Tigre (El Talar)','Tigre','2026-10-26','6 h libres esta semana · ocupación 95%');

insert into public.pedidos (id,codigo,cliente,proceso,cliente_lat,cliente_lng,maquina_id,planta,planta_lat,planta_lng,estado,horas_maquina,km_logistica,lead_time_dias,fecha) values
  (1,'PED-1001','Muebles Nuevo Hogar','Router CNC madera',-34.6037,-58.43,36,'Carpintería Patagonia SRL',-34.68293,-58.35026,'En proceso',12,30,4,'2026-10-16'),
  (2,'PED-1002','Envases Riachuelo','Inyección',-34.645,-58.402,1,'Plásticos Litoral SAS',-34.70122,-58.58144,'Entrega en camino',8,46,6,'2026-10-17'),
  (3,'PED-1003','Startup Biotec Saavedra','Centro de mecanizado',-34.553,-58.49,28,'Matricería Norte SA',-34.72039,-58.59453,'Entregado',6,54,6,'2026-10-18'),
  (4,'PED-1004','Electro Quilmes','Inyección',-34.724,-58.254,8,'Plásticos Norte SA',-34.78649,-58.18506,'Retiro de materia prima',16,24,6,'2026-10-19'),
  (5,'PED-1005','Riego Agro Luján','Extrusión',-34.57,-59.105,14,'Extrusiones Delta SRL',-34.6169,-58.95189,'En proceso',6,38,7,'2026-10-20'),
  (6,'PED-1006','Bicis Urbanas Palermo','Corte láser',-34.58,-58.425,43,'Metalúrgica Precisión SRL',-34.71744,-58.58354,'Entrega en camino',12,54,6,'2026-10-21'),
  (7,'PED-1007','Repuestos Morón','Torno CNC',-34.653,-58.62,22,'Mecanizados Litoral SRL',-34.5719,-58.53028,'Entregado',16,32,5,'2026-10-22'),
  (8,'PED-1008','Stand Ferias Belgrano','Router CNC madera',-34.562,-58.456,36,'Carpintería Patagonia SRL',-34.68293,-58.35026,'Retiro de materia prima',16,44,5,'2026-10-23'),
  (9,'PED-1009','Cosmética Caseros','Inyección',-34.605,-58.565,1,'Plásticos Litoral SAS',-34.70122,-58.58144,'En proceso',16,28,3,'2026-10-24'),
  (10,'PED-1010','Talleres Lanús','Corte láser',-34.707,-58.392,42,'Metalúrgica Andina SRL',-34.8335,-58.39642,'Entrega en camino',12,36,5,'2026-10-15'),
  (11,'PED-1011','Prototipos UTN Pacheco','Centro de mecanizado',-34.456,-58.625,26,'Matricería Pampa SRL',-34.62623,-58.78541,'Entregado',4,62,4,'2026-10-16'),
  (12,'PED-1012','Cables Merlo','Extrusión',-34.665,-58.728,13,'Extrusiones Andina SA',-34.70979,-58.57835,'Retiro de materia prima',6,38,4,'2026-10-17'),
  (13,'PED-1013','Agro Partes Cañuelas','Torno CNC',-35.052,-58.76,19,'Mecanizados Express SRL',-34.8633,-58.5052,'En proceso',6,82,7,'2026-10-18'),
  (14,'PED-1014','Juguetes San Justo','Inyección',-34.68,-58.56,10,'Plásticos Pampa SAS',-34.71299,-58.58499,'Entrega en camino',16,12,7,'2026-10-19'),
  (15,'PED-1015','Señalética La Plata','Corte láser',-34.921,-57.955,42,'Metalúrgica Andina SRL',-34.8335,-58.39642,'Entregado',16,108,5,'2026-10-20'),
  (16,'PED-1016','Hidráulica Escobar','Torno CNC',-34.348,-58.795,17,'Mecanizados Pampa SA',-34.42784,-58.74601,'Retiro de materia prima',12,26,6,'2026-10-21');

-- Contador de visitas (pedido del profesor)
create table if not exists public.visitas (
  id integer primary key default 1 check (id = 1),
  total bigint not null default 0
);
insert into public.visitas (id, total) values (1, 0) on conflict (id) do nothing;
alter table public.visitas enable row level security;
drop policy if exists "lectura publica visitas" on public.visitas;
create policy "lectura publica visitas" on public.visitas for select to anon using (true);

-- Suma 1 visita y devuelve el total (la app la llama al abrirse)
create or replace function public.registrar_visita()
returns bigint
language sql
security definer
set search_path = public
as $$
  update public.visitas set total = total + 1 where id = 1 returning total;
$$;
grant execute on function public.registrar_visita() to anon;

-- Tarifas: precio de referencia por hora-máquina en ARS (valores simulados para la PoC)
alter table public.puntos add column if not exists tarifa_hora integer;
update public.puntos as p set tarifa_hora = t.tarifa from (values
  (1,35000),
  (2,38000),
  (3,41000),
  (4,32500),
  (5,43500),
  (6,32500),
  (7,38000),
  (8,32500),
  (9,32500),
  (10,35000),
  (11,27000),
  (12,37000),
  (13,27000),
  (14,37000),
  (15,37000),
  (16,27000),
  (17,31500),
  (18,28500),
  (19,28500),
  (20,25500),
  (21,34500),
  (22,25500),
  (23,28500),
  (24,25500),
  (25,34500),
  (26,38000),
  (27,38000),
  (28,45000),
  (29,38000),
  (30,38000),
  (31,38000),
  (32,51500),
  (33,25500),
  (34,25500),
  (35,18500),
  (36,22000),
  (37,18500),
  (38,25500),
  (39,22000),
  (40,46000),
  (41,42000),
  (42,46000),
  (43,34000),
  (44,38000),
  (45,34000)
) as t(id, tarifa) where p.id = t.id;

-- Control: debe devolver 45 y 16
select (select count(*) from public.puntos) as maquinas, (select count(*) from public.pedidos) as pedidos, (select total from public.visitas) as visitas, (select count(tarifa_hora) from public.puntos) as con_tarifa;
