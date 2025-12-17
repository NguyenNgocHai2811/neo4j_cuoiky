# HƯỚNG DẪN THỰC HÀNH (TIẾNG VIỆT)

Dự án này phân tích dữ liệu mạng lưới hàng không thế giới (OpenFlights) bằng Neo4j và Python, giải quyết 9 bài toán thực hành về đồ thị (Thống kê, Đường đi ngắn nhất, PageRank, Community Detection...).

## 1. Cấu trúc thư mục

*   `airlines.csv`, `airports.csv`, `routes.csv`: Dữ liệu gốc.
*   `import.cypher`: Script để nạp dữ liệu vào Neo4j.
*   `queries.cypher`: Các câu lệnh truy vấn Neo4j giải quyết 9 yêu cầu (Câu 2 - Câu 10).
*   `solve_analysis.py`: Script Python thực hiện toàn bộ phân tích và tính toán (dùng NetworkX).
*   `REPORT_VI.md`: Báo cáo chi tiết kết quả phân tích.

## 2. Hướng dẫn chạy

### Cách 1: Sử dụng Python (Phân tích độc lập)
Để xem kết quả phân tích ngay lập tức mà không cần cài Neo4j:
```bash
python3 solve_analysis.py
```
Kết quả sẽ được in ra màn hình console.

### Cách 2: Sử dụng Neo4j (Thực hành Database)
Yêu cầu: Đã cài đặt Neo4j Desktop hoặc Neo4j Server, và cài đặt plugin **Graph Data Science (GDS)** & **APOC**.

**Bước 1: Nạp dữ liệu**
1.  Copy 3 file csv vào thư mục `import` của Neo4j.
2.  Chạy nội dung file `import.cypher` trong Neo4j Browser.

**Bước 2: Chạy truy vấn**
1.  Mở file `queries.cypher`.
2.  Copy và chạy từng khối lệnh tương ứng với từng câu hỏi (Câu 2 đến Câu 10).

**Lưu ý:**
*   **Câu 5** yêu cầu tính toán khoảng cách, hãy chạy trước khi làm câu 7.
 *   **Câu 7, 8, 9, 10** yêu cầu thư viện GDS. Bạn cần tạo Graph Projection trước (bao gồm thuộc tính khoảng cách):
    ```cypher
     CALL gds.graph.project(
        'flightGraph',
        'Airport',
        'ROUTE',
        { relationshipProperties: 'distance' }
     );
    ```

## 3. Nội dung bài thực hành
*   **Câu 2-3:** Thống kê cơ bản (số lượng, tần suất).
*   **Câu 4:** Kiểm tra đường bay (HAN -> SGN).
*   **Câu 5:** Tính khoảng cách Haversine.
*   **Câu 6:** Tìm sân bay "nguồn" (chỉ đi, không đến).
*   **Câu 7:** Tìm đường đi ngắn nhất (Dijkstra).
*   **Câu 8:** Xếp hạng sân bay (PageRank).
*   **Câu 9:** Phân nhóm sân bay (Louvain).
*   **Câu 10:** Kiểm tra tính liên thông của đồ thị.
