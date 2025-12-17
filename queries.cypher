// ============================================================================
// FILE TRUY VẤN NEO4J (Tasks 2 - 10)
// ============================================================================

// ============================================================================
// CÂU 2: THÔNG TIN THỐNG KÊ CƠ BẢN
// ============================================================================
// 1. Tổng số sân bay và 5 sân bay đầu tiên
MATCH (a:Airport)
RETURN count(a) AS TotalAirports;

MATCH (a:Airport)
RETURN a.airportID, a.name, a.country
ORDER BY a.airportID
LIMIT 5;

// 2. Tổng số hãng hàng không và danh sách
MATCH (l:Airline)
RETURN count(l) AS TotalAirlines;

MATCH (l:Airline)
RETURN l.airlineID, l.name, l.country
LIMIT 5;


// ============================================================================
// CÂU 3: THỐNG KÊ TẦN SUẤT HOẠT ĐỘNG
// ============================================================================
// Số lượng tuyến bay mỗi hãng sở hữu
MATCH ()-[r:ROUTE]->()
RETURN r.airline AS AirlineCode, count(r) AS NumberOfRoutes
ORDER BY NumberOfRoutes DESC
LIMIT 10;


// ============================================================================
// CÂU 4: KIỂM TRA ĐƯỜNG BAY HAN -> SGN
// ============================================================================
// Kiểm tra bay từ Nội Bài (HAN) đến Tân Sơn Nhất (SGN)
MATCH (src:Airport {iata: 'HAN'}), (dest:Airport {iata: 'SGN'})
OPTIONAL MATCH p = shortestPath((src)-[:ROUTE*..2]->(dest))
RETURN p;


// ============================================================================
// CÂU 5: TÍNH KHOẢNG CÁCH (HAVERSINE)
// ============================================================================
// Tính và cập nhật thuộc tính distance cho quan hệ ROUTE
MATCH (a:Airport)-[r:ROUTE]->(b:Airport)
WHERE a.latitude IS NOT NULL AND b.latitude IS NOT NULL
WITH a, b, r,
     point({latitude: toFloat(a.latitude), longitude: toFloat(a.longitude)}) AS p1,
     point({latitude: toFloat(b.latitude), longitude: toFloat(b.longitude)}) AS p2
SET r.distance = point.distance(p1, p2) / 1000
RETURN count(r) AS UpdatedRoutes;


// ============================================================================
// CÂU 6: TÌM SÂN BAY "NGUỒN" (SOURCE-ONLY)
// ============================================================================
// Tìm sân bay chỉ xuất phát đi mà không có chiều về (cho một hãng cụ thể, ví dụ '2G')
MATCH (a:Airport)-[out:ROUTE]->()
WHERE out.airline = '2G'
AND NOT EXISTS {
    MATCH ()-[in:ROUTE]->(a) WHERE in.airline = '2G'
}
RETURN DISTINCT a.name AS SourceOnlyAirport;


// ============================================================================
// CÂU 7: HÀNH TRÌNH NGẮN NHẤT CDG -> HAN
// ============================================================================
// Tìm đường đi ngắn nhất theo khoảng cách (yêu cầu đã chạy Câu 5 để có distance)
// Lưu ý: Cần sử dụng thư viện GDS.
// Bước 1: Tạo Graph Projection có thuộc tính khoảng cách (nếu chưa tạo)
// CALL gds.graph.project(
//    'flightGraph',
//    'Airport',
//    'ROUTE',
//    { relationshipProperties: 'distance' }
// );

// Bước 2: Chạy thuật toán Dijkstra
MATCH (source:Airport {iata: 'CDG'}), (target:Airport {iata: 'HAN'})
CALL gds.shortestPath.dijkstra.stream('flightGraph', {
    sourceNode: source,
    targetNode: target,
    relationshipWeightProperty: 'distance'
})
YIELD index, totalCost, nodeIds, costs
RETURN
    totalCost AS TotalDistanceKM,
    [nodeId IN nodeIds | gds.util.asNode(nodeId).name] AS PathNames;


// ============================================================================
// CÂU 8: PAGERANK (ĐỘ QUAN TRỌNG)
// ============================================================================
// Yêu cầu: Cần thư viện GDS.
// 1. Tạo Graph Projection (lưu ý nếu dùng chung projection thì cần tạo 1 lần thôi)
// CALL gds.graph.project('flightGraph', 'Airport', 'ROUTE', { relationshipProperties: 'distance' });

// 2. Chạy PageRank
CALL gds.pageRank.stream('flightGraph')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS Airport, score
ORDER BY score DESC
LIMIT 10;


// ============================================================================
// CÂU 9: COMMUNITY DETECTION (PHÂN NHÓM)
// ============================================================================
// Yêu cầu: Cần thư viện GDS và Graph Projection 'flightGraph'.
CALL gds.louvain.stream('flightGraph')
YIELD nodeId, communityId
RETURN communityId, count(nodeId) AS Size, collect(gds.util.asNode(nodeId).name)[0..5] AS Examples
ORDER BY Size DESC
LIMIT 5;


// ============================================================================
// CÂU 10: TÍNH LIÊN THÔNG
// ============================================================================
// Kiểm tra Strong Connected Components (SCC)
CALL gds.scc.stats('flightGraph')
YIELD componentCount, maxComponentSize;
