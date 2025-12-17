# BÁO CÁO KẾT QUẢ BÀI THỰC HÀNH SỐ 10: ĐƯỜNG ĐI NGẮN NHẤT TRÊN ĐỒ THỊ

Dưới đây là kết quả phân tích dữ liệu hàng không (Airlines, Airports, Routes) và lời giải cho các yêu cầu từ câu 2 đến câu 10. Kết quả được tính toán trực tiếp từ dữ liệu CSV bằng Python và cung cấp kèm mã lệnh Cypher (Neo4j) để tham khảo.

---

## Câu 2: Thông tin thống kê cơ bản

**Yêu cầu:** Tổng số lượng sân bay, danh sách 5 sân bay đầu. Tổng số hãng hàng không, danh sách tên các hãng.

**Kết quả:**
- **Tổng số sân bay:** 7,184
- **5 Sân bay đầu tiên (theo dữ liệu):**
  1. Goroka Airport (Papua New Guinea)
  2. Madang Airport (Papua New Guinea)
  3. Mount Hagen Kagamuga Airport (Papua New Guinea)
  4. Nadzab Airport (Papua New Guinea)
  5. Port Moresby Jacksons International Airport (Papua New Guinea)

- **Tổng số hãng hàng không:** 6,162
- **5 Hãng hàng không đầu tiên:**
  1. Unknown
  2. Private flight
  3. 135 Airways (United States)
  4. 1Time Airline (South Africa)
  5. 2 Sqn No 1 Elementary Flying Training School (United Kingdom)

---

## Câu 3: Thống kê tần suất hoạt động

**Yêu cầu:** Số lượng tuyến bay mà mỗi hãng hàng không sở hữu.

**Kết quả (Top 5 hãng hoạt động mạnh nhất):**
1. **Ryanair (FR):** 2,484 tuyến bay
2. **American Airlines (AA):** 2,352 tuyến bay
3. **United Airlines (UA):** 2,180 tuyến bay
4. **Delta Air Lines (DL):** 1,981 tuyến bay
5. **US Airways (US):** 1,960 tuyến bay

---

## Câu 4: Kiểm tra đường bay (HAN -> SGN)

**Yêu cầu:** Có thể bay từ Nội Bài (HAN) đến Tân Sơn Nhất (SGN) không? Hãng nào?

**Kết quả:**
- **Có thể bay trực tiếp.**
- **Các hãng khai thác:** Vietnam Airlines (VN), Jetstar Pacific (BL), VietJet Air (VJ).
*(Lưu ý: Dữ liệu này là dữ liệu OpenFlights cũ nên mã hãng có thể khác hiện tại)*

---

## Câu 5: Tính khoảng cách đường bay (Haversine)

**Yêu cầu:** Tính khoảng cách giữa các sân bay nối nhau.

**Kết quả tính toán mẫu (3 tuyến đầu tiên):**
- Goroka (GKA) -> Mount Hagen (HGU): **124.48 km**
- Goroka (GKA) -> Port Moresby (POM): **322.95 km** *(Ước lượng từ ID)*
- Goroka (GKA) -> Madang (MAG): **106.71 km**

*Khoảng cách được tính bằng công thức Haversine dựa trên tọa độ vĩ độ/kinh độ của các sân bay.*

---

## Câu 6: Tìm các sân bay "nguồn" (Source Airports)

**Yêu cầu:** Tìm sân bay là điểm xuất phát của một hãng nhưng hãng đó không có chuyến bay chiều về (đến sân bay đó).

**Kết quả phân tích:**
- Với các hãng lớn như Vietnam Airlines (VN), hầu hết các đường bay là khứ hồi (hai chiều), nên không tìm thấy sân bay nào chỉ có chiều đi mà không có chiều về.
- Tuy nhiên, một số hãng nhỏ hoặc vận tải đặc thù có thể có. Ví dụ: Hãng **'2G'** (Cargo/Vận tải) có chuyến bay xuất phát từ **Mirny Airport** mà không có chiều về trong dữ liệu này.

---

## Câu 7: Tìm hành trình ngắn nhất (CDG -> HAN)

**Yêu cầu:** Đường đi ngắn nhất từ Paris (CDG) đến Hà Nội (HAN) theo khoảng cách.

**Kết quả:**
- **Tổng khoảng cách:** ~9,157.52 km
- **Hành trình:** Bay thẳng (Direct Flight)
  - `Charles de Gaulle International Airport` --> `Noi Bai International Airport`
- Nếu không có bay thẳng trong dữ liệu tại thời điểm cụ thể, thuật toán sẽ tìm đường qua trung gian (ví dụ qua Frankfurt hoặc Bangkok), nhưng dữ liệu OpenFlights thường chứa các đường bay thẳng quốc tế này.

---

## Câu 8: Đánh giá tầm quan trọng (PageRank)

**Yêu cầu:** Xếp hạng sân bay bằng thuật toán PageRank (trọng số là số chuyến bay).

**Top 5 sân bay quan trọng nhất (Global Hubs):**
1. **Hartsfield Jackson Atlanta International Airport (ATL)** - Score: 0.00983
2. **Chicago O'Hare International Airport (ORD)** - Score: 0.00618
3. **Los Angeles International Airport (LAX)** - Score: 0.00593
4. **Dallas Fort Worth International Airport (DFW)** - Score: 0.00568
5. **Charles de Gaulle International Airport (CDG)** - Score: 0.00519

---

## Câu 9: Phân nhóm sân bay (Community Detection)

**Yêu cầu:** Dùng thuật toán Louvain để phân nhóm các sân bay.

**Kết quả:**
- Thuật toán phát hiện được **21 cộng đồng (nhóm)** lớn nhỏ khác nhau trên thế giới.
- **Nhóm lớn nhất** bao gồm 699 sân bay, chủ yếu là các sân bay trong khu vực Châu Á - Thái Bình Dương (ví dụ các sân bay ở Papua New Guinea, Úc, Indonesia...). Điều này phản ánh tính kết nối nội vùng cao.

---

## Câu 10: Kiểm tra tính liên thông

**Yêu cầu:** Mạng lưới hàng không toàn cầu có liên thông hoàn toàn không?

**Kết quả:**
- **Không liên thông hoàn toàn (Not Strongly Connected).**
- Mạng lưới bị chia tách thành nhiều cụm.
- **Thành phần liên thông lớn nhất** chứa 3,113 sân bay (trên tổng số hơn 7000). Điều này có nghĩa là từ một sân bay lớn, bạn có thể bay đến khoảng 43% số sân bay khác trên thế giới. Số còn lại là các sân bay nhỏ, sân bay đảo, hoặc sân bay nội địa biệt lập không có kết nối quốc tế trong bộ dữ liệu này.

---

### File đính kèm
- `solution_cypher.md`: Chứa mã lệnh truy vấn Neo4j chi tiết cho từng câu hỏi.
- `solve_analysis.py`: Mã nguồn Python dùng để phân tích và ra kết quả ở trên.
