# Hướng dẫn Import Dữ liệu và Chạy Truy vấn (Neo4j Desktop 5.x)

Tài liệu này hướng dẫn cách nạp dữ liệu vào Neo4j Desktop phiên bản hiện đại (5.x trở lên).

## 1. Chuẩn bị File CSV

Neo4j yêu cầu các file CSV phải nằm trong thư mục `import` của dự án database để đảm bảo bảo mật.

### Cách tìm thư mục Import trên Neo4j Desktop:
1.  Mở **Neo4j Desktop**.
2.  Di chuột vào Database bạn đang chạy (ví dụ "My Project").
3.  Bấm vào dấu ba chấm `...` (Manage).
4.  Chọn **Open folder** -> **Import**.
5.  Copy 3 file (`airlines.csv`, `airports.csv`, `routes.csv`) vào thư mục này.

## 2. Nạp Dữ liệu (Chạy `import.cypher`)

1.  Bấm **Start** để chạy Database.
2.  Bấm **Open** để mở **Neo4j Browser**.
3.  Copy toàn bộ nội dung file `import.cypher` và paste vào khung lệnh.
4.  **Quan trọng**: Bật tùy chọn "Enable multi-statement query editor" trong phần Settings (biểu tượng bánh răng) của Neo4j Browser để chạy nhiều lệnh cùng lúc.
5.  Bấm nút **Run** (Play).

*Nếu không bật multi-statement, hãy copy và chạy từng khối lệnh riêng lẻ (tách nhau bởi dấu chấm phẩy `;`).*

## 3. Chạy Truy vấn Phân tích (Chạy `queries.cypher`)

File `queries.cypher` chứa 20 câu lệnh tương ứng với 20 yêu cầu của bài thực hành.

1.  Mở file `queries.cypher` bằng Text Editor.
2.  Copy **từng câu lệnh riêng lẻ** và chạy trong Neo4j Browser.

### Lưu ý về Plugin GDS (Graph Data Science)
Câu hỏi số 18 sử dụng thư viện GDS để phân tích thành phần liên thông. Để chạy được câu lệnh `CALL gds.wcc.stream...`, bạn cần cài đặt plugin này:
1.  Trong Neo4j Desktop, bấm vào tên Database.
2.  Chọn tab **Plugins**.
3.  Tìm **Graph Data Science Library** và bấm **Install**.
4.  Khởi động lại Database.

Nếu không cài GDS, bạn vẫn có thể chạy các câu hỏi khác bình thường.
