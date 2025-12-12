# Hướng dẫn Import Dữ liệu và Chạy Truy vấn Neo4j

Tài liệu này hướng dẫn chi tiết cách nạp bộ dữ liệu hàng không (`airlines.csv`, `airports.csv`, `routes.csv`) vào cơ sở dữ liệu Neo4j và thực hiện các truy vấn phân tích.

## 1. Chuẩn bị Môi trường

Bạn cần cài đặt **Neo4j Desktop** hoặc **Neo4j Server**.

### Vị trí thư mục `import`
Neo4j yêu cầu các file CSV phải nằm trong thư mục `import` của cơ sở dữ liệu để đảm bảo an toàn.

*   **Neo4j Desktop (Windows/Mac/Linux):**
    1.  Mở Neo4j Desktop.
    2.  Chọn Project và Database bạn đang dùng.
    3.  Bấm vào dấu `...` bên cạnh nút **Open**, chọn **Open folder** -> **Import**.
    4.  Cửa sổ thư mục sẽ hiện ra.

*   **Neo4j Server (Linux/Docker):**
    *   Thường nằm tại `/var/lib/neo4j/import` hoặc thư mục bạn đã mount vào `/import` trong Docker.

## 2. Copy Dữ liệu

Copy 3 file sau vào thư mục `import` vừa mở ở bước trên:
*   `airlines.csv`
*   `airports.csv`
*   `routes.csv`

## 3. Nạp Dữ liệu (Chạy `import.cypher`)

1.  Mở **Neo4j Browser** (bấm nút **Start** rồi **Open** trong Neo4j Desktop, hoặc truy cập `http://localhost:7474`).
2.  Mở file `import.cypher` đính kèm trong dự án này bằng trình soạn thảo văn bản (Notepad, VS Code...).
3.  **Lưu ý quan trọng**: File `import.cypher` chứa nhiều câu lệnh. Bạn nên chạy **TỪNG KHỐI LỆNH** (các khối cách nhau bởi dấu chấm phẩy `;`) để đảm bảo không bị lỗi bộ nhớ hoặc timeout, hoặc bật chế độ "Enable multi-statement query editor" trong Neo4j Browser.

    *   **Khối 1: Tạo Constraints (Ràng buộc)**
        Copy và chạy đoạn này trước để tạo chỉ mục (index) giúp import nhanh hơn:
        ```cypher
        CREATE CONSTRAINT ON (a:Airline) ASSERT a.airlineID IS UNIQUE;
        CREATE CONSTRAINT ON (p:Airport) ASSERT p.airportID IS UNIQUE;
        ```

    *   **Khối 2: Load Airlines**
        Copy đoạn `LOAD CSV ... MERGE (a:Airline)...` và chạy.

    *   **Khối 3: Load Airports**
        Copy đoạn `LOAD CSV ... MERGE (p:Airport)...` và chạy.

    *   **Khối 4: Load Routes**
        Copy đoạn `LOAD CSV ... MERGE (source)-[r:ROUTE]->(target)...` và chạy. Quá trình này có thể mất vài chục giây đến vài phút tùy cấu hình máy vì file `routes.csv` khá lớn.

## 4. Chạy Truy vấn Phân tích (Chạy `queries.cypher`)

Sau khi nạp dữ liệu thành công, bạn có thể trả lời các câu hỏi của bài thực hành.

1.  Mở file `queries.cypher`.
2.  File này chứa 20 câu truy vấn tương ứng với 20 câu hỏi.
3.  Copy **từng câu lệnh riêng lẻ** (từ `MATCH` đến dấu chấm phẩy `;`) và paste vào Neo4j Browser để chạy.

### Ví dụ:
Để tìm đường bay ngắn nhất từ Hà Nội đi Paris (Câu 1), bạn copy đoạn:
```cypher
MATCH p = shortestPath((start:Airport {iata: 'HAN'})-[*]-(end:Airport {iata: 'CDG'}))
RETURN p, length(p) AS hops, reduce(s = 0, r in relationships(p) | s + r.stops) AS total_stops
ORDER BY hops ASC, total_stops ASC
LIMIT 1;
```
Bấm nút Play (►) để xem kết quả dưới dạng đồ thị hoặc bảng.

## 5. Lưu ý bổ sung

*   **Plugin GDS (Graph Data Science)**: Một số truy vấn nâng cao (như Câu 18 về phân tích thành phần liên thông) sử dụng thư viện GDS (`CALL gds.wcc.stream...`). Hãy đảm bảo bạn đã cài đặt plugin này:
    *   Trong Neo4j Desktop: Chọn Database -> Plugins -> Cài đặt **Graph Data Science Library**.
*   **Haversine Distance**: Trong file `import.cypher` tôi đã tính sẵn khoảng cách (`r.distance`) khi tạo cạnh `ROUTE`. Nếu bạn dùng bộ dữ liệu mới, hãy đảm bảo công thức tính toán này được giữ nguyên.
