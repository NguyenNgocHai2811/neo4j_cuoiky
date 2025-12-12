// 1. Đường bay ngắn nhất theo số chặng (Hops)
MATCH p = shortestPath((start:Airport {iata: 'HAN'})-[*]-(end:Airport {iata: 'CDG'}))
RETURN [n in nodes(p) | n.name] AS Path, length(p) AS Hops, reduce(s = 0, r in relationships(p) | s + r.stops) AS TotalStops;

// 2. Đường bay ngắn nhất theo khoảng cách thực tế (Haversine)
// Vì Neo4j 2.0 chưa có hàm distance(), ta phải tính thủ công.
MATCH p = (start:Airport {iata: 'NRT'})-[*..3]->(end:Airport {iata: 'LHR'})
WITH p, relationships(p) AS rels, nodes(p) AS nds
// Tính tổng khoảng cách từng chặng
// Công thức: 2 * 6371 * asin(sqrt( sin((lat2-lat1)/2)^2 + cos(lat1)*cos(lat2)*sin((lon2-lon1)/2)^2 ))
// Lưu ý: Cypher 2.0 có sin, cos, radians, sqrt, asin.
RETURN [n in nds | n.name] AS Path,
       reduce(dist = 0.0, idx in range(0, length(p)-1) |
         dist + (
           2 * 6371 * asin(sqrt(
             sin(radians(nds[idx+1].latitude - nds[idx].latitude)/2)^2 +
             cos(radians(nds[idx].latitude)) * cos(radians(nds[idx+1].latitude)) *
             sin(radians(nds[idx+1].longitude - nds[idx].longitude)/2)^2
           ))
         )
       ) AS TotalDistanceKM
ORDER BY TotalDistanceKM ASC
LIMIT 1;

// 3. Top 10 Sân bay có Bậc vào (In-Degree) cao nhất
MATCH ()-[r:ROUTE]->(a:Airport)
RETURN a.name, count(DISTINCT startNode(r)) AS InDegree
ORDER BY InDegree DESC
LIMIT 10;

// 4. Sân bay trung chuyển tại Đức
MATCH (a:Airport {country: 'Germany'})
OPTIONAL MATCH (a)-[out:ROUTE]->()
OPTIONAL MATCH ()-[in:ROUTE]->(a)
RETURN a.name, count(DISTINCT out) + count(DISTINCT in) AS Degree
ORDER BY Degree DESC
LIMIT 5;

// 5. Hãng hàng không phủ sóng lớn nhất
MATCH (a:Airline)
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE r.airlineID = a.airlineID
WITH a, collect(DISTINCT s) + collect(DISTINCT d) AS nodes
UNWIND nodes AS n
RETURN a.name, count(DISTINCT n) AS Count
ORDER BY Count DESC
LIMIT 5;

// 6. Hãng hàng không độc quyền (Vietnam)
MATCH (s:Airport {country:'Vietnam'})-[r:ROUTE]->(d:Airport {country:'Vietnam'})
WITH s, d, collect(DISTINCT r.airlineID) AS aids
WHERE size(aids) = 1
MATCH (a:Airline {airlineID: aids[0]})
RETURN a.name, s.city, d.city;

// 7. Cặp quốc gia kết nối nhiều nhất
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE s.country <> d.country AND r.stops = 0
WITH s.country AS c1, d.country AS c2, count(r) AS cnt
RETURN c1, c2, cnt
ORDER BY cnt DESC
LIMIT 5;

// 8. Cổng Đông Nam Á đi Châu Âu
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE s.country IN ['Vietnam', 'Thailand', 'Singapore', 'Malaysia', 'Indonesia', 'Philippines']
  AND d.country IN ['France', 'Germany', 'United Kingdom', 'Italy', 'Spain']
RETURN s.name, count(r) AS Routes
ORDER BY Routes DESC
LIMIT 1;

// 9. Đa dạng thiết bị bay
MATCH (a:Airport)-[r:ROUTE]-()
RETURN a.name, count(DISTINCT r.equipment) AS Types
ORDER BY Types DESC
LIMIT 5;

// 10. Tam giác đường bay (Tính tổng khoảng cách thủ công)
MATCH (a:Airport)-[r1:ROUTE]->(b:Airport)-[r2:ROUTE]->(c:Airport)-[r3:ROUTE]->(a)
WHERE a <> b AND b <> c AND a <> c
// Tính dist r1
WITH a, b, c,
     (2 * 6371 * asin(sqrt(sin(radians(b.latitude - a.latitude)/2)^2 + cos(radians(a.latitude)) * cos(radians(b.latitude)) * sin(radians(b.longitude - a.longitude)/2)^2))) AS d1
// Tính dist r2
WITH a, b, c, d1,
     (2 * 6371 * asin(sqrt(sin(radians(c.latitude - b.latitude)/2)^2 + cos(radians(b.latitude)) * cos(radians(c.latitude)) * sin(radians(c.longitude - b.longitude)/2)^2))) AS d2
// Tính dist r3
WITH a, b, c, d1, d2,
     (2 * 6371 * asin(sqrt(sin(radians(a.latitude - c.latitude)/2)^2 + cos(radians(c.latitude)) * cos(radians(a.latitude)) * sin(radians(a.longitude - c.longitude)/2)^2))) AS d3
RETURN a.name, b.name, c.name, (d1+d2+d3) AS TotalDist
ORDER BY TotalDist ASC
LIMIT 5;

// 11. Từ Phu Cat (6193) bay đến đâu ở VN?
MATCH (s:Airport {airportID: '6193'})-[r:ROUTE]->(d:Airport {country: 'Vietnam'})
RETURN d.name;

// 12. Phu Cat -> Pleiku
MATCH p = shortestPath((s:Airport {airportID: '6193'})-[*]->(d:Airport {airportID: '6194'}))
RETURN extract(n in nodes(p) | n.name) AS Path;

// 13. Danang -> New York
MATCH (dad:Airport {city: 'Danang'}), (jfk:Airport {airportID: '3797'})
MATCH p = shortestPath((dad)-[*]->(jfk))
RETURN extract(n in nodes(p) | n.name) AS Path;

// 14. Noi Bai -> TSN Direct
MATCH (s:Airport {airportID: '3199'})-[r:ROUTE]->(d:Airport {airportID: '3205'})
MATCH (a:Airline {airlineID: r.airlineID})
RETURN count(r), collect(a.name);

// 15. VN -> Singapore
MATCH (s:Airport {country: 'Vietnam'})-[r:ROUTE]->(d:Airport {country: 'Singapore'})
RETURN s.name, d.name;

// 16. Phu Cat -> JFK (Top 5 shortest path - Approximate using cypher limitation)
// Neo4j 2.0 doesn't have k-shortest paths built-in easily.
// Use simple path matching with limit
MATCH p = (s:Airport {airportID: '6193'})-[*..6]->(d:Airport {airportID: '3797'})
RETURN extract(n in nodes(p) | n.name) AS Path, length(p) AS Len
ORDER BY Len ASC
LIMIT 5;

// 17. Random paths
MATCH p = (s:Airport {airportID: '6193'})-[*4]->(d:Airport)
RETURN extract(n in nodes(p) | n.name) AS Path
LIMIT 10;

// 18. Liên thông (Simple reachability check)
MATCH (a:Airport {country: 'Vietnam'})
OPTIONAL MATCH (a)-[:ROUTE*]->(b:Airport {country: 'Vietnam'})
RETURN a.name, count(DISTINCT b) AS ReachableVNCount;

// 19. VN -> Iceland
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'Iceland'})
MATCH p = shortestPath((s)-[*]->(d))
RETURN extract(n in nodes(p) | n.name) AS Path
LIMIT 1;

// 20. VN -> US by VN Airlines (Legacy Syntax)
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'United States'})
MATCH p = shortestPath((s)-[:ROUTE*..6]->(d))
WHERE ALL(x IN relationships(p) WHERE x.airlineID = '5309')
RETURN p IS NOT NULL AS Possible
LIMIT 1;
