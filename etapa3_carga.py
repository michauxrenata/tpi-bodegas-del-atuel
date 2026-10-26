
import random
from datetime import datetime, date
from faker import Faker
import psycopg2
from psycopg2.extras import execute_values

# 1. Configuración de reproducibilidad (Semilla y fecha fija según H3)
SEED = 42
fake = Faker('es_AR')
Faker.seed(SEED)
random.seed(SEED)

FECHA_REFERENCIA_FIJA = date(2025, 1, 15)

# 2. Configuración de conexión a la base de datos
DB_CONFIG = {
    "dbname": "bodegas_del_atuel",
    "user": "postgres",
    "password": "1234",  # Pon tu contraseña real aquí
    "host": "localhost",
    "port": "5432",
    "client_encoding": "UTF8"
}

def generar_carga_nivel_0(cur):
    """Inserta los datos del Nivel 0 adaptados a las tablas de Santiago"""
    print("--- Cargando Nivel 0 ---")
    
    # 1. Localidades (codigo_postal PK, nombre, provincia, encargado_regional)
    localidades = [
        (fake.postcode()[:10], fake.city()[:100], fake.province()[:100], fake.name()[:150]) 
        for _ in range(50)
    ]
    execute_values(
        cur,
        "INSERT INTO localidad (codigo_postal, nombre, provincia, encargado_regional) VALUES %s ON CONFLICT DO NOTHING",
        localidades
    )
    print("✓ Localidades cargadas")
    
    # 2. Cepas (nombre, tipo) -> tipo_cepa es un enum o varchar según su esquema
    tipos_cepa = ['tinta', 'blanca']
    cepas_base = ['Malbec', 'Cabernet Sauvignon', 'Bonarda', 'Syrah', 'Chardonnay', 'Torrontés', 'Merlot', 'Tempranillo']
    cepas = [(c, random.choice(tipos_cepa)) for c in cepas_base]
    execute_values(
        cur, 
        "INSERT INTO cepa (nombre, tipo) VALUES %s ON CONFLICT DO NOTHING", 
        cepas
    )
    print("✓ Cepas cargadas")
    
    # 3. Bodegas (3 columnas exactas: cuit, razon_social, domicilio)
    bodegas = [
        (f"{random.choice([20, 23, 27, 30])}{random.randint(100000000, 999999999)}", fake.company()[:150], fake.address()[:200]) 
        for _ in range(10)
    ]
    execute_values(
        cur, 
        "INSERT INTO bodega (cuit, razon_social, domicilio) VALUES %s ON CONFLICT DO NOTHING", 
        bodegas
    )
    print("✓ Bodegas cargadas")
    
    # 4. Transportistas (5 columnas exactas: razon_social, cuit, email, telefono, domicilio)
    transportistas = [
        (fake.company()[:150], f"{random.choice([20, 23, 27, 30])}{random.randint(100000000, 999999999)}", fake.email(), fake.phone_number()[:30], fake.address()[:200]) 
        for _ in range(15)
    ]
    execute_values(
        cur, 
        "INSERT INTO transportista (razon_social, cuit, email, telefono, domicilio) VALUES %s ON CONFLICT DO NOTHING", 
        transportistas
    )
    print("✓ Transportistas cargados")
    # 5. Fincas (id_identity, nombre, ubicacion, cuit_bodega)
    fincas = [
        (fake.company()[:100] + " Finca", fake.address()[:200], random.choice(cuits_bodegas)) 
        for _ in range(8)
    ]

def generar_carga_nivel_1(cur):
    """Inserta los datos del Nivel 1 respetando claves foráneas y restricciones de negocio"""
    print("--- Cargando Nivel 1 ---")
    
    # Obtenemos claves foráneas existentes del Nivel 0 para mantener la integridad referencial
    cur.execute("SELECT codigo_postal FROM localidad;")
    codigos_postales = [row[0] for row in cur.fetchall()]
    
    cur.execute("SELECT id_finca FROM finca;")
    ids_fincas = [row[0] for row in cur.fetchall()]
    
    cur.execute("SELECT id_cepa FROM cepa;")
    ids_cepas = [row[0] for row in cur.fetchall()]
    
    cur.execute("SELECT cuit FROM bodega;")
    cuits_bodegas = [row[0] for row in cur.fetchall()]
    
    cur.execute("SELECT codigo_transportista FROM transportista;")
    codigos_transportistas = [row[0] for row in cur.fetchall()]

    cur.execute("SELECT id_cliente FROM cliente;")
    ids_clientes = [row[0] for row in cur.fetchall()]

    if not codigos_postales or not cuits_bodegas or not ids_fincas or not ids_cepas:
        print("❌ Error: Faltan datos en el Nivel 0 para vincular el Nivel 1.")
        return

    # 1. SALA_VENTA (id_identity, calle, numero, dia_cierre, codigo_postal)
    dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábados']
    salas = [
        (fake.street_name()[:100], str(random.randint(1, 4000)), random.choice(dias), random.choice(codigos_postales))
        for _ in range(15)
    ]
    execute_values(
        cur,
        "INSERT INTO sala_venta (calle, numero, dia_cierre, codigo_postal) VALUES %s ON CONFLICT DO NOTHING",
        salas
    )
    print("✓ Salas de venta cargadas")

    # 2. PARCELA (id_finca, nro_parcela PK compuesta, superficie_ha, anio_plantacion, id_cepa)
    parcelas = []
    for id_finca in ids_fincas:
        for nro in range(1, random.randint(2, 4)): # 2 o 3 parcelas por finca
            parcelas.append((
                id_finca, 
                nro, 
                round(random.uniform(1.0, 25.0), 2), 
                random.randint(1990, 2022), 
                random.choice(ids_cepas)
            ))
    execute_values(
        cur,
        "INSERT INTO parcela (id_finca, nro_parcela, superficie_ha, anio_plantacion, id_cepa) VALUES %s ON CONFLICT DO NOTHING",
        parcelas
    )
    print("✓ Parcelas cargadas")

    # 3. VINO (Respetando CHK de precio > 0, volumen > 0, graduación 0-100 y tipo por defecto 'tinto')
    tipos_vino = ['tinto', 'blanco', 'rosado', 'espumoso'] # Ajustar minúsculas según tu enum
    vinos = [
        (
            fake.word().capitalize() + " Reserva"[:100], 
            random.choice(tipos_vino), 
            random.randint(2018, 2024), 
            random.choice([375, 750, 1500]), # > 0 (volumen_ml)
            round(random.uniform(11.5, 14.5), 2), # Entre 0 y 100 (graduación)
            round(random.uniform(3500.0, 45000.0), 2), # > 0 (precio)
            random.choice(cuits_bodegas)
        )
        for _ in range(25)
    ]
    execute_values(
        cur,
        "INSERT INTO vino (nombre, tipo, anada, volumen_ml, graduacion, precio, cuit_bodega) VALUES %s ON CONFLICT DO NOTHING",
        vinos
    )
    print("✓ Vinos cargados")

    # 4. CLIENTES SUBTIPOS (cliente_socio, cliente_distribuidor, cliente_exportador)
    random.shuffle(ids_clientes)
    tercio = len(ids_clientes) // 3
    
    socios = [(cid,) for cid in ids_clientes[:tercio]]
    distribuidores = [(cid, fake.city()[:150] + " Zona", f"HAB-{random.randint(10000,99999)}") for cid in ids_clientes[tercio:2*tercio]]
    exportadores = [(cid, fake.country()[:100]) for cid in ids_clientes[2*tercio:]]

    if socios:
        execute_values(cur, "INSERT INTO cliente_socio (id_cliente) VALUES %s ON CONFLICT DO NOTHING", socios)
    if distribuidores:
        execute_values(cur, "INSERT INTO cliente_distribuidor (id_cliente, zona_cobertura, nro_habilitacion) VALUES %s ON CONFLICT DO NOTHING", distribuidores)
    if exportadores:
        execute_values(cur, "INSERT INTO cliente_exportador (id_cliente, pais_destino_principal) VALUES %s ON CONFLICT DO NOTHING", exportadores)
    print("✓ Subtipos de clientes cargados")

    # 5. TRANSPORTISTA_COBERTURA (codigo_transportista, codigo_postal PK compuesta)
    coberturas = set()
    for trans_id in codigos_transportistas:
        locs_asig = random.sample(codigos_postales, k=min(3, len(codigos_postales)))
        for cp in locs_asig:
            coberturas.add((trans_id, cp))
            
    execute_values(
        cur,
        "INSERT INTO transportista_cobertura (codigo_transportista, codigo_postal) VALUES %s ON CONFLICT DO NOTHING",
        list(coberturas)
    )
    print("✓ Coberturas de transportistas cargadas")

    # 6. INGRESO (codigo_ingreso identity, fecha, estado, codigo_transportista, cuit_bodega)
    estados_doc = ['en_confeccion', 'emitido', 'anulado']
    ingresos = [
        (fake.date_between(start_date='-1y', end_date='today'), random.choice(estados_doc), 
         random.choice(codigos_transportistas), random.choice(cuits_bodegas))
        for _ in range(20)
    ]
    execute_values(
        cur,
        "INSERT INTO ingreso (fecha, estado, codigo_transportista, cuit_bodega) VALUES %s ON CONFLICT DO NOTHING",
        ingresos
    )
    print("✓ Ingresos cargados")

def ejecutar_carga_masiva():
    print("Iniciando proceso de carga masiva...")
    try:
        with psycopg2.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cur:
                generar_carga_nivel_0(cur)
                generar_carga_nivel_1(cur)
                # Confirmar transacción
                conn.commit()
                print("\n¡Nivel 0 completado exitosamente y cambios guardados en la BD!")
                
    except Exception as e:
        print(f"\n❌ Error de conexión o durante la carga: {e}")
        print("💡 Consejo: Asegúrate de que PostgreSQL esté corriendo en tu PC y que el usuario/contraseña sean correctos.")

if __name__ == "__main__":
    ejecutar_carga_masiva()


