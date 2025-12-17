import pandas as pd
import networkx as nx
import math

def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # Earth radius in km
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)

    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2) * math.sin(dlambda/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def run_analysis():
    print("--- Loading Data ---")
    # Load Airports
    # No header, need to define names
    airport_cols = ['Airport ID', 'Name', 'City', 'Country', 'IATA', 'ICAO', 'Latitude', 'Longitude', 'Altitude', 'Timezone', 'DST', 'Tz', 'Type', 'Source']
    try:
        airports = pd.read_csv('airports.csv', header=None, names=airport_cols, na_values='\\N')
    except Exception as e:
        print(f"Error loading airports: {e}")
        return

    # Load Airlines
    # Has header
    try:
        airlines = pd.read_csv('airlines.csv', na_values='\\N')
    except Exception as e:
        print(f"Error loading airlines: {e}")
        return

    # Load Routes
    # Has header (with typo)
    try:
        routes = pd.read_csv('routes.csv', na_values='\\N')
        # Clean column names (remove spaces)
        routes.columns = routes.columns.str.strip()
    except Exception as e:
        print(f"Error loading routes: {e}")
        return

    # Clean IDs
    airports['Airport ID'] = pd.to_numeric(airports['Airport ID'], errors='coerce')
    # Use stripped names
    routes['source airport id'] = pd.to_numeric(routes['source airport id'], errors='coerce')
    routes['destination airport id'] = pd.to_numeric(routes['destination airport id'], errors='coerce')

    routes = routes.dropna(subset=['source airport id', 'destination airport id'])

    # ---------------------------------------------------------
    # Task 2: Stats
    print("\n--- Task 2: Statistics ---")
    print(f"Total Airports: {len(airports)}")
    print("First 5 Airports:")
    print(airports[['Name', 'Country']].head(5).to_string(index=False))

    print(f"\nTotal Airlines: {len(airlines)}")
    print("First 5 Airlines:")
    print(airlines[['Name', 'Country']].head(5).to_string(index=False))

    # ---------------------------------------------------------
    # Task 3: Frequency (Flights per airline)
    print("\n--- Task 3: Airline Frequency ---")
    # Count number of routes per airline
    airline_counts = routes['airline'].value_counts().head(5)
    print("Top 5 Airlines by number of routes:")
    print(airline_counts)

    # ---------------------------------------------------------
    # Build Graph
    print("\n--- Building Graph ---")
    G = nx.MultiDiGraph()

    # Add nodes
    for _, row in airports.iterrows():
        if pd.notna(row['Airport ID']):
            G.add_node(int(row['Airport ID']),
                       name=row['Name'],
                       city=row['City'],
                       country=row['Country'],
                       lat=row['Latitude'],
                       lon=row['Longitude'],
                       iata=row['IATA'])

    # Add edges
    edge_count = 0
    for _, row in routes.iterrows():
        src = int(row['source airport id'])
        dst = int(row['destination airport id'])

        if G.has_node(src) and G.has_node(dst):
            # Calculate distance immediately for Task 5
            lat1 = G.nodes[src]['lat']
            lon1 = G.nodes[src]['lon']
            lat2 = G.nodes[dst]['lat']
            lon2 = G.nodes[dst]['lon']
            dist = haversine(lat1, lon1, lat2, lon2)

            G.add_edge(src, dst,
                       airline=row['airline'],
                       distance=dist)
            edge_count += 1

    print(f"Graph built: {G.number_of_nodes()} nodes, {edge_count} edges.")

    # ---------------------------------------------------------
    # Task 4: Path HAN -> SGN
    print("\n--- Task 4: HAN -> SGN ---")
    # Find IDs for HAN and SGN
    han_node = airports[airports['IATA'] == 'HAN']['Airport ID'].values
    sgn_node = airports[airports['IATA'] == 'SGN']['Airport ID'].values

    if len(han_node) > 0 and len(sgn_node) > 0:
        han_id = int(han_node[0])
        sgn_id = int(sgn_node[0])
        print(f"HAN ID: {han_id}, SGN ID: {sgn_id}")

        if nx.has_path(G, han_id, sgn_id):
            print("Path exists!")
            # Find direct flights
            if G.has_edge(han_id, sgn_id):
                edges = G.get_edge_data(han_id, sgn_id)
                airlines_on_route = set([d['airline'] for d in edges.values()])
                print(f"Direct flights available by airlines: {airlines_on_route}")
            else:
                path = nx.shortest_path(G, han_id, sgn_id)
                print(f"Indirect path: {path}")
        else:
            print("No path found.")
    else:
        print("Could not resolve HAN or SGN IATA codes.")

    # ---------------------------------------------------------
    # Task 5: Distance (Already calculated in build step)
    print("\n--- Task 5: Distances ---")
    print("Sample distances (first 3 edges):")
    for i, (u, v, k, d) in enumerate(G.edges(keys=True, data=True)):
        if i >= 3: break
        print(f"{u} -> {v} ({d.get('airline')}): {d.get('distance'):.2f} km")

    # ---------------------------------------------------------
    # Task 6: Source Airports (One-way outbound for an airline)
    print("\n--- Task 6: One-way Source Airports ---")
    # We need to pick an airline or check generally.
    # Let's check generally for "Vietnam Airlines" (VN) if it exists, or a common one like 'AA'.
    # In 'airlines.csv', Vietnam Airlines might be IATA 'VN'.

    target_airline = 'VN'
    # Create subgraph for this airline
    vn_edges = [(u, v) for u, v, k, d in G.edges(keys=True, data=True) if d.get('airline') == target_airline]

    if not vn_edges:
        print(f"No routes found for airline {target_airline}. Trying 'AA' (American Airlines).")
        target_airline = 'AA'
        vn_edges = [(u, v) for u, v, k, d in G.edges(keys=True, data=True) if d.get('airline') == target_airline]

    if vn_edges:
        subG = nx.DiGraph()
        subG.add_edges_from(vn_edges)

        sources = []
        for n in subG.nodes():
            if subG.out_degree(n) > 0 and subG.in_degree(n) == 0:
                sources.append(n)

        print(f"Found {len(sources)} purely source airports for {target_airline}.")
        if len(sources) > 0:
            print("Examples:", sources[:5])
            names = [G.nodes[n]['name'] for n in sources[:5]]
            print("Names:", names)
        else:
            print(f"No source-only airports for {target_airline}. Searching all airlines for an example...")
            # Search for an airline that has source airports
            found_example = False
            for airline_code in routes['airline'].unique():
                if airline_code == target_airline: continue
                # Filter edges
                # This is slow if done iteratively on dataframe, faster on graph
                # But graph is MultiDiGraph.
                # Let's verify quickly.

                # Get all edges for this airline
                al_edges = [(u,v) for u,v,k,d in G.edges(keys=True, data=True) if d.get('airline') == airline_code]
                if not al_edges: continue

                subG_al = nx.DiGraph()
                subG_al.add_edges_from(al_edges)
                al_sources = [n for n in subG_al.nodes() if subG_al.out_degree(n) > 0 and subG_al.in_degree(n) == 0]

                if al_sources:
                    print(f"Airline '{airline_code}' has {len(al_sources)} source-only airports.")
                    print("Example Airports:", [G.nodes[n]['name'] for n in al_sources[:3]])
                    found_example = True
                    break
            if not found_example:
                print("No airline found with strictly source-only airports (rare in this dataset).")
    else:
        print("No routes found for AA either.")

    # ---------------------------------------------------------
    # Task 7: Shortest Path CDG -> HAN (by distance)
    print("\n--- Task 7: Shortest Path CDG -> HAN ---")
    cdg_node = airports[airports['IATA'] == 'CDG']['Airport ID'].values

    if len(cdg_node) > 0 and len(han_node) > 0:
        cdg_id = int(cdg_node[0])
        han_id = int(han_node[0])

        try:
            # Dijkstra using 'distance' weight
            # Note: G is MultiDiGraph. shortest_path works but we might want to simplify to DiGraph with min weight
            # actually nx.shortest_path works on MultiDiGraph by picking smallest weight edge if multiple exist?
            # Let's convert to DiGraph with min distance to be safe and clear

            G_simple = nx.DiGraph()
            for u, v, data in G.edges(data=True):
                w = data.get('distance', float('inf'))
                if G_simple.has_edge(u, v):
                    if w < G_simple[u][v]['weight']:
                        G_simple[u][v]['weight'] = w
                else:
                    G_simple.add_edge(u, v, weight=w)

            path = nx.shortest_path(G_simple, source=cdg_id, target=han_id, weight='weight')
            path_dist = nx.shortest_path_length(G_simple, source=cdg_id, target=han_id, weight='weight')

            print(f"Shortest path CDG -> HAN: {path_dist:.2f} km")
            path_names = [G.nodes[n]['name'] for n in path]
            print(" -> ".join(path_names))

        except nx.NetworkXNoPath:
            print("No path found between CDG and HAN.")
    else:
        print("CDG or HAN not found.")

    # ---------------------------------------------------------
    # Task 8: PageRank
    print("\n--- Task 8: PageRank ---")
    # Use flight count as weight.
    # We can count edges between nodes in MultiDiGraph
    G_weighted = nx.DiGraph()
    for u, v in G.edges():
        if G_weighted.has_edge(u, v):
            G_weighted[u][v]['weight'] += 1
        else:
            G_weighted.add_edge(u, v, weight=1)

    pr = nx.pagerank(G_weighted, weight='weight')
    sorted_pr = sorted(pr.items(), key=lambda x: x[1], reverse=True)

    print("Top 5 Airports by PageRank:")
    for i, (node_id, score) in enumerate(sorted_pr[:5]):
        print(f"{i+1}. {G.nodes[node_id]['name']} ({G.nodes[node_id]['iata']}): {score:.5f}")

    # ---------------------------------------------------------
    # Task 9: Community Detection
    print("\n--- Task 9: Community Detection ---")
    # NetworkX has 'louvain_communities' in recent versions (needs stats/scipy sometimes)
    # Fallback to simple connection based if fails
    try:
        # Convert to undirected for community usually
        G_undir = G_simple.to_undirected()
        communities = nx.community.louvain_communities(G_undir, weight='weight')
        print(f"Found {len(communities)} communities.")

        # Largest community
        largest_comm = max(communities, key=len)
        print(f"Largest community has {len(largest_comm)} airports.")
        print("First 5 airports in largest community:")
        for n in list(largest_comm)[:5]:
            print(f"- {G.nodes[n]['name']} ({G.nodes[n]['country']})")

    except Exception as e:
        print(f"Community detection failed (might need scipy/modules): {e}")

    # ---------------------------------------------------------
    # Task 10: Connectivity
    print("\n--- Task 10: Connectivity ---")
    is_weakly = nx.is_weakly_connected(G)
    is_strongly = nx.is_strongly_connected(G)
    print(f"Weakly Connected: {is_weakly}")
    print(f"Strongly Connected: {is_strongly}")

    if not is_strongly:
        comps = list(nx.strongly_connected_components(G))
        print(f"Number of strongly connected components: {len(comps)}")
        print(f"Size of largest component: {len(max(comps, key=len))}")

if __name__ == "__main__":
    run_analysis()
