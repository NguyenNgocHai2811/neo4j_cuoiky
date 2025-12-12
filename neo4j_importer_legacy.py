import csv
import json
import requests
import time

# --- Cấu hình ---
NEO4J_URL = "http://localhost:7474/db/data/transaction/commit"
# Nếu bạn có user/pass (Neo4j 2.0 thường mặc định không có hoặc là neo4j/neo4j)
# AUTH = ('neo4j', 'neo4j')
AUTH = None

BATCH_SIZE = 1000

def run_cypher(statements):
    payload = {
        "statements": [{"statement": stmt, "parameters": params} for stmt, params in statements]
    }
    try:
        response = requests.post(NEO4J_URL, json=payload, auth=AUTH)
        response.raise_for_status()
        res_json = response.json()
        if res_json.get('errors'):
            print("Errors:", res_json['errors'])
    except Exception as e:
        print(f"Error sending batch: {e}")

def load_data():
    # 1. Constraints
    print("Creating constraints...")
    constraints = [
        ("CREATE CONSTRAINT ON (a:Airline) ASSERT a.airlineID IS UNIQUE", {}),
        ("CREATE CONSTRAINT ON (p:Airport) ASSERT p.airportID IS UNIQUE", {})
    ]
    # Note: Neo4j 2.0.3 might support transactional constraints differently,
    # but run one by one is safer.
    for stmt, _ in constraints:
        try:
            requests.post(NEO4J_URL, json={"statements": [{"statement": stmt}]}, auth=AUTH)
        except:
            pass # Ignore if exists

    # 2. Airlines
    print("Loading Airlines...")
    stmts = []
    with open('airlines.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            aid = row.get('Airline ID')
            if aid and aid != '\\N':
                query = """
                MERGE (a:Airline {airlineID: {aid}})
                SET a.name = {name}, a.country = {country}
                """
                params = {
                    'aid': aid,
                    'name': row.get('Name', ''),
                    'country': row.get('Country', '')
                }
                stmts.append((query, params))
                if len(stmts) >= BATCH_SIZE:
                    run_cypher(stmts)
                    stmts = []
    if stmts: run_cypher(stmts)

    # 3. Airports
    print("Loading Airports...")
    stmts = []
    with open('airports.csv', 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        for row in reader:
            if not row: continue
            try:
                # 0: ID, 1: Name, 2: City, 3: Country, 4: IATA, 6: Lat, 7: Lon
                aid = row[0]
                lat = float(row[6])
                lon = float(row[7])
                query = """
                MERGE (p:Airport {airportID: {aid}})
                SET p.name = {name}, p.city = {city}, p.country = {country},
                    p.iata = {iata}, p.latitude = {lat}, p.longitude = {lon}
                """
                params = {
                    'aid': aid,
                    'name': row[1],
                    'city': row[2],
                    'country': row[3],
                    'iata': row[4],
                    'lat': lat,
                    'lon': lon
                }
                stmts.append((query, params))
                if len(stmts) >= BATCH_SIZE:
                    run_cypher(stmts)
                    stmts = []
            except Exception as e:
                continue
    if stmts: run_cypher(stmts)

    # 4. Routes
    print("Loading Routes...")
    stmts = []
    count = 0
    with open('routes.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            src_id = row.get(' source airport id', '').strip()
            dst_id = row.get(' destination airport id', '').strip()
            if src_id and dst_id and src_id != '\\N' and dst_id != '\\N':
                # Neo4j 2.0 MERGE can be slow on relationships if not indexed.
                # Since we created constraints/indexes on airportID, it should be okay.
                query = """
                MATCH (s:Airport {airportID: {src_id}})
                MATCH (d:Airport {airportID: {dst_id}})
                CREATE (s)-[r:ROUTE {
                    airlineID: {airline_id},
                    stops: {stops},
                    equipment: {equipment}
                }]->(d)
                """
                # Note: Using CREATE for routes because parallel edges are allowed/common (different airlines)
                # and MERGE on rels with properties is expensive.

                params = {
                    'src_id': src_id,
                    'dst_id': dst_id,
                    'airline_id': row.get('airline ID', '').strip(),
                    'stops': int(row.get(' stops', '0').strip()) if row.get(' stops', '0').strip().isdigit() else 0,
                    'equipment': row.get(' equipment', '').strip()
                }
                stmts.append((query, params))
                count += 1
                if len(stmts) >= BATCH_SIZE:
                    run_cypher(stmts)
                    print(f"Imported {count} routes...")
                    stmts = []
    if stmts: run_cypher(stmts)
    print("Done!")

if __name__ == "__main__":
    load_data()
