# A01 · Phạm vi (Scope)

Trích và cấu trúc hoá từ **Project Charter — A01, mục 3**. Không thêm, không bớt nội dung.

---

## 1. TRONG PHẠM VI — tám thành phần bắt buộc của hồ sơ

| # | Thành phần | Nằm ở đâu trong cây thư mục này |
|---|---|---|
| 1 | Bối cảnh ứng dụng | `01_REQUIREMENT/application.md` §1 |
| 2 | Sơ đồ khối hệ thống | `01_REQUIREMENT/application.md` §2 · `03_ARCHITECTURE/system_diagram.md` |
| 3 | Phân loại analog / digital / mixed | `01_REQUIREMENT/application.md` §3 |
| 4 | Bảng giao diện **của chính khối này** | `02_SPECIFICATION/interface.md` §2 |
| 5 | Một artifact số **có chú thích** | `05_VERIFICATION/waveforms/` · `06_GDSII/synthesis/` |
| 6 | Sơ đồ vòng đời | `03_ARCHITECTURE/system_diagram.md` §4 |
| 7 | RTM-lite (yêu cầu → khối → bằng chứng → giới hạn) | `07_TRACEABILITY/RTM.csv` |
| 8 | Kết luận và giới hạn | `07_TRACEABILITY/limitations.md` |

## 2. MỞ RỘNG — tự nguyện, **không** phải điều kiện đạt

> Chạy chuỗi công cụ **LibreLane** với PDK **sky130A** trên bộ cài đặt đã xác minh, rồi
> **đọc báo cáo do chính lần chạy đó sinh ra**.

Trạng thái trong gói này: script đã chuẩn bị sẵn tại
`04_IMPLEMENTATION/scripts/run_librelane.sh` + `config_librelane.json`.
Kết quả thật **chưa chạy** — xem `06_GDSII/physical_report.md`.

## 3. NGOÀI PHẠM VI

### 3.1 Riêng cho A01

- Bộ cộng **nhìn trước carry (CLA)** — chỉ được **so sánh trên giấy** trong
  `03_ARCHITECTURE/tradeoff.md`, **không** được thay kiến trúc.
- Số **có dấu rộng hơn 8 bit**.
- **Tự tối ưu netlist bằng tay.**

### 3.2 Áp dụng cho mọi đề

- Thiết kế **analog mức transistor**.
- **Tự làm physical design** (nghĩa là: không tự ý dựng flow P&R riêng ngoài LibreLane đã duyệt).
- **ASIC sign-off.**
- **Tape-out.**
- **Chế tạo** và **kiểm tra sau chế tạo**.

> ❗ Hệ quả về cách viết kết luận: **không** được dùng các phát biểu vượt mức như
> "đã sign-off", "đã tape-out", "đã chế tạo", "đã kiểm tra trên silicon".
> Xem `07_TRACEABILITY/limitations.md`.

## 4. Ranh giới của khối A01 (design boundary)

| Thuộc A01 | Không thuộc A01 |
|---|---|
| 8 tầng full-adder ripple | Thanh ghi TỔNG (ô nhớ tích luỹ) |
| Logic sinh `C`, `Z`, `N`, `V` | Clock, reset, enable |
| Ánh xạ cổng `A`, `B`, `SUM`, cờ | Bộ phát hiện bước chân, ADC, cảm biến |
| — | Lớp vỏ vật lý xử lý 28-bit-trên-24-chân (**chưa chốt**, cần GV duyệt) |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Nguồn: Charter A01 mục 3.*
