# Hướng dẫn Import Dữ liệu (Neo4j 2.0.3 Legacy)

Do phiên bản Neo4j 2.0.3 (ra mắt ~2014) rất cũ và chưa hỗ trợ lệnh `LOAD CSV` tiêu chuẩn, bạn cần sử dụng một script Python để nạp dữ liệu thông qua giao thức HTTP (REST API).

## 1. Chuẩn bị

1.  Đảm bảo Neo4j 2.0.3 đang chạy tại `http://localhost:7474`.
2.  Cài đặt Python (nếu chưa có).
3.  Cài thư viện `requests` cho Python:
    ```bash
    pip install requests
    ```
4.  Đặt 3 file dữ liệu (`airlines.csv`, `airports.csv`, `routes.csv`) cùng thư mục với file `neo4j_importer_legacy.py`.

## 2. Nạp Dữ liệu

Chạy lệnh sau trong terminal/cmd:

```bash
python neo4j_importer_legacy.py
```

Script sẽ tự động:
1.  Tạo Constraints (Ràng buộc duy nhất).
2.  Đọc file CSV và gửi lệnh `CREATE/MERGE` đến Neo4j theo từng lô (batch) để tránh treo máy.
3.  Quá trình nạp `routes.csv` (67k dòng) có thể mất vài phút.

## 3. Chạy Truy vấn (Queries)

Sử dụng file `queries_legacy.cypher` đính kèm.

*   Mở **Neo4j Browser** (`http://localhost:7474`).
*   Copy từng câu lệnh trong file `queries_legacy.cypher` và chạy.
*   **Lưu ý**: Các câu lệnh đã được tối ưu cho Neo4j 2.0 (không dùng hàm `distance()`, `point()`, `GDS` mà dùng công thức toán học cổ điển).

## 4. Giải thích thay đổi cho bản 2.0.3

*   **Import**: Thay vì `LOAD CSV` (không có), dùng Python script bắn API.
*   **Khoảng cách**: Thay vì `distance()`, dùng công thức Haversine (`2 * 6371 * asin(...)`) trực tiếp trong Cypher.
*   **Phân tích đồ thị**: Thay vì thư viện GDS (Graph Data Science), dùng các truy vấn Cypher thuần túy để kiểm tra tính liên thông cơ bản.
