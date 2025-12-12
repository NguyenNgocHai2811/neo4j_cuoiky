# Báo cáo Bài thực hành số 10: Đường đi ngắn nhất trên đồ thị (Neo4j 2.0.3 Legacy)

Dưới đây là các câu lệnh Cypher tương thích với Neo4j 2.0.3.

## 1. Thiết lập Cơ sở dữ liệu

Do phiên bản 2.0.3 không hỗ trợ `LOAD CSV`, vui lòng sử dụng script `neo4j_importer_legacy.py` để nạp dữ liệu.

## 2. Giải quyết các yêu cầu

### 1. Đường bay ngắn nhất (ít chặng nhất) từ Hà Nội (HAN) đến Paris (CDG)
**Câu lệnh Cypher:**
```cypher
MATCH p = shortestPath((start:Airport {iata: 'HAN'})-[*]-(end:Airport {iata: 'CDG'}))
RETURN extract(n in nodes(p) | n.name) AS Path, length(p) AS Hops, reduce(s = 0, r in relationships(p) | s + r.stops) AS TotalStops;
```

### 2. Đường bay ngắn nhất theo khoảng cách thực tế (haversine)
**Lưu ý:** Neo4j 2.0 không có hàm `distance()`. Sử dụng công thức Haversine thủ công.
**Câu lệnh Cypher:**
```cypher
MATCH p = (start:Airport {iata: 'NRT'})-[*..3]->(end:Airport {iata: 'LHR'})
WITH p, relationships(p) AS rels, nodes(p) AS nds
RETURN extract(n in nds | n.name) AS Path,
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
```

### 3. Sân bay có "Bậc vào" (In-Degree) cao nhất (Top 10)
**Câu lệnh Cypher:**
```cypher
MATCH ()-[r:ROUTE]->(a:Airport)
RETURN a.name AS Airport, count(DISTINCT startNode(r)) AS InDegree
ORDER BY InDegree DESC
LIMIT 10;
```

### 4. Sân bay trung chuyển quan trọng cục bộ (Local Hubs) tại Đức
**Câu lệnh Cypher:**
```cypher
MATCH (a:Airport {country: 'Germany'})
OPTIONAL MATCH (a)-[out:ROUTE]->()
OPTIONAL MATCH ()-[in:ROUTE]->(a)
RETURN a.name, count(DISTINCT out) + count(DISTINCT in) AS TotalDegree
ORDER BY TotalDegree DESC
LIMIT 5;
```

### 5. Hãng hàng không có mạng lưới phủ sóng lớn nhất
**Câu lệnh Cypher:**
```cypher
MATCH (a:Airline)
MATCH (start:Airport)-[r:ROUTE]->(end:Airport)
WHERE r.airlineID = a.airlineID
WITH a, collect(DISTINCT start) + collect(DISTINCT end) AS nodes
UNWIND nodes AS n
RETURN a.name, count(DISTINCT n) AS AirportCount
ORDER BY AirportCount DESC
LIMIT 5;
```

### 6. Hãng hàng không độc quyền đường bay trực tiếp giữa hai thành phố Việt Nam
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {country:'Vietnam'})-[r:ROUTE]->(d:Airport {country:'Vietnam'})
WITH s, d, collect(DISTINCT r.airlineID) AS airlines
WHERE size(airlines) = 1
MATCH (a:Airline {airlineID: airlines[0]})
RETURN a.name AS ExclusiveAirline, s.city AS From, d.city AS To;
```

### 7. Cặp quốc gia có mức độ kết nối trực tiếp cao nhất
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE s.country <> d.country AND r.stops = 0
WITH s.country AS c1, d.country AS c2, count(r) AS Flights
RETURN c1, c2, Flights
ORDER BY Flights DESC
LIMIT 5;
```

### 8. Tìm "cổng" khu vực Đông Nam Á đi Châu Âu
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE s.country IN ['Vietnam', 'Thailand', 'Singapore', 'Malaysia', 'Indonesia', 'Philippines']
  AND d.country IN ['France', 'Germany', 'United Kingdom', 'Italy', 'Spain']
RETURN s.name, count(r) AS RoutesToEurope
ORDER BY RoutesToEurope DESC
LIMIT 1;
```

### 9. Sân bay có độ đa dạng thiết bị bay cao nhất
**Câu lệnh Cypher:**
```cypher
MATCH (a:Airport)-[r:ROUTE]-()
RETURN a.name, count(DISTINCT r.equipment) AS EquipmentTypes
ORDER BY EquipmentTypes DESC
LIMIT 5;
```

### 10. Tìm các "Tam giác" đường bay (3 chặng A->B->C->A) ngắn nhất
**Câu lệnh Cypher:**
```cypher
MATCH (a:Airport)-[r1:ROUTE]->(b:Airport)-[r2:ROUTE]->(c:Airport)-[r3:ROUTE]->(a)
WHERE a <> b AND b <> c AND a <> c
// Tính toán thủ công do không có thuộc tính distance sẵn có từ import cũ
WITH a, b, c,
     (2 * 6371 * asin(sqrt(sin(radians(b.latitude - a.latitude)/2)^2 + cos(radians(a.latitude)) * cos(radians(b.latitude)) * sin(radians(b.longitude - a.longitude)/2)^2))) AS d1
WITH a, b, c, d1,
     (2 * 6371 * asin(sqrt(sin(radians(c.latitude - b.latitude)/2)^2 + cos(radians(b.latitude)) * cos(radians(c.latitude)) * sin(radians(c.longitude - b.longitude)/2)^2))) AS d2
WITH a, b, c, d1, d2,
     (2 * 6371 * asin(sqrt(sin(radians(a.latitude - c.latitude)/2)^2 + cos(radians(c.latitude)) * cos(radians(a.latitude)) * sin(radians(a.longitude - c.longitude)/2)^2))) AS d3
RETURN a.name, b.name, c.name, (d1+d2+d3) AS TotalDist
ORDER BY TotalDist ASC
LIMIT 5;
```

### 11. Từ sân bay Phu cat (6193) bay đến đâu ở Việt Nam?
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {airportID: '6193'})-[r:ROUTE]->(d:Airport {country: 'Vietnam'})
RETURN d.name;
```

### 12. Đường bay ngắn nhất từ Phu cat đến Pleiku
**Câu lệnh Cypher:**
```cypher
MATCH p = shortestPath((s:Airport {airportID: '6193'})-[*]->(d:Airport {airportID: '6194'}))
RETURN extract(n in nodes(p) | n.name) AS Path;
```

### 13. Đường bay ngắn nhất từ Danang đến New York
**Câu lệnh Cypher:**
```cypher
MATCH (dad:Airport {city: 'Danang'}), (jfk:Airport {airportID: '3797'})
MATCH p = shortestPath((dad)-[*]->(jfk))
RETURN extract(n in nodes(p) | n.name) AS Path;
```

### 14. Chuyến bay trực tiếp từ Noi Bai (3199) đến Tan Son Nhat (3205)
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {airportID: '3199'})-[r:ROUTE]->(d:Airport {airportID: '3205'})
MATCH (a:Airline {airlineID: r.airlineID})
RETURN count(r) AS FlightCount, collect(a.name) AS Airlines;
```

### 15. Đường bay thẳng Vietnam -> Singapore
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {country: 'Vietnam'})-[r:ROUTE]->(d:Airport {country: 'Singapore'})
RETURN s.name AS From, d.name AS To;
```

### 16. 5 đường bay ngắn nhất từ Phu Cat đến JFK
**Câu lệnh Cypher:**
```cypher
MATCH p = (s:Airport {airportID: '6193'})-[*..6]->(d:Airport {airportID: '3797'})
RETURN extract(n in nodes(p) | n.name) AS Path, length(p) AS Len
ORDER BY Len ASC
LIMIT 5;
```

### 17. 10 đường bay ngẫu nhiên từ Phu cat qua đúng 3 sân bay trung chuyển
**Câu lệnh Cypher:**
```cypher
MATCH p = (s:Airport {airportID: '6193'})-[*4]->(d:Airport)
RETURN extract(n in nodes(p) | n.name) AS Path
LIMIT 10;
```

### 18. Phương án mở ít nhất các đường bay ở Vietnam
*Do Neo4j 2.0 chưa hỗ trợ thư viện Graph Data Science (GDS), ta kiểm tra tính liên thông bằng truy vấn:*
**Câu lệnh Cypher:**
```cypher
MATCH (a:Airport {country: 'Vietnam'})
OPTIONAL MATCH (a)-[:ROUTE*]->(b:Airport {country: 'Vietnam'})
RETURN a.name, count(DISTINCT b) AS ReachableVNCount;
```
*Nếu số lượng sân bay đến được < Tổng số sân bay VN, đồ thị không liên thông.*

### 19. Đường bay ngắn nhất Vietnam -> Iceland
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'Iceland'})
MATCH p = shortestPath((s)-[*]->(d))
RETURN extract(n in nodes(p) | n.name) AS Path
LIMIT 1;
```

### 20. Bay từ Vietnam sang US bằng Vietnam Airlines (5309)
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'United States'})
MATCH p = shortestPath((s)-[:ROUTE*..6]->(d))
WHERE ALL(x IN relationships(p) WHERE x.airlineID = '5309')
RETURN p IS NOT NULL AS Possible
LIMIT 1;
```
