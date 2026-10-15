# A01 · Tiêu chí đạt (Acceptance Criteria)

Nguồn: **Charter A01 mục 6**, cộng với các tiêu chí kiểm chứng suy ra từ mục 8 và 9.
Mỗi tiêu chí có **cách kiểm** cụ thể và **trạng thái hiện tại** của gói này.

Trạng thái: ✅ ĐẠT (có bằng chứng do tool sinh) · 🟡 MỞ (chờ quyết định) · ⬜ CHƯA CHẠY.

---

## 1. Bốn tiêu chí gốc của Charter

| # | Tiêu chí (nguyên văn Charter mục 6) | Cách kiểm | Bằng chứng | Trạng thái |
|---|---|---|---|---|
| AC-1 | Bảng giao diện đầy đủ, nhất quán với đặc tả; tín hiệu nào cũng có chiều và độ rộng. | Rà bảng trong `02_SPECIFICATION/interface.md` §2 với cổng module trong RTL. | `interface.md` §2 ↔ `04_IMPLEMENTATION/rtl/a01_ripple_adder.sv` | ✅ |
| AC-2 | Mỗi khẳng định đi kèm bằng chứng và điều kiện tạo ra bằng chứng đó. | Mỗi dòng RTM phải trỏ tới một file bằng chứng có ghi tool + phiên bản + lệnh chạy. | `07_TRACEABILITY/RTM.csv`, `07_TRACEABILITY/evidence_index.md` | ✅ (phần đã chạy) |
| AC-3 | Trả lời câu phân tích riêng bằng dữ liệu của chính mình. | Câu hỏi mục 9: đường tới hạn đi qua bao nhiêu tầng carry, đo bằng STA. | `06_GDSII/sta/` | ⬜ chờ STA |
| AC-4 | Nêu giới hạn trung thực; không dùng phát biểu vượt mức như "đã sign-off". | Quét `07_TRACEABILITY/limitations.md` và mọi kết luận. | `07_TRACEABILITY/limitations.md` | ✅ |

## 2. Tiêu chí chức năng (suy từ mục 8)

| # | Tiêu chí | Ngưỡng đạt | Bằng chứng | Trạng thái |
|---|---|---|---|---|
| AC-5 | 5 ca bắt buộc của Charter đều PASS | 5/5 | `05_VERIFICATION/test_matrix.csv` TC-001…TC-005 | ✅ 5/5 |
| AC-6 | ≥ 2 ca tự xây dựng, có ≥ 1 ca biên | ≥ 2 | TC-006…TC-010 (5 ca, trong đó 2 ca biên) | ✅ 5 ca |
| AC-7 | DUT khớp golden reference trên **toàn bộ** không gian đầu vào | 65 536/65 536 | `05_VERIFICATION/verification_report.md` §3 | ✅ 0 lỗi |
| AC-8 | Có waveform làm artifact số, có chú thích | ≥ 1 file | `05_VERIFICATION/waveforms/` | ✅ |

## 3. Tiêu chí cấu trúc phần cứng (suy từ mục 10)

| # | Tiêu chí | Ngưỡng đạt | Bằng chứng | Trạng thái |
|---|---|---|---|---|
| AC-9 | **0 flip-flop** sau tổng hợp | đúng 0 | `06_GDSII/synthesis/synth_stat.txt` | ✅ 0 FF |
| AC-10 | Quy mô cell nằm trong khoảng hợp lý cho 1×1 tile | < 1 000 cell | 48 cell, 285.27 µm² | ✅ |
| AC-11 | RTL mô tả **tường minh** chuỗi 8 tầng carry (không dùng toán tử `+`) | có `generate` 8 tầng | `04_IMPLEMENTATION/rtl/a01_ripple_adder.sv` | ✅ |

## 4. Tiêu chí timing (suy từ mục 9) — chưa chạy

| # | Tiêu chí | Ngưỡng đạt | Bằng chứng | Trạng thái |
|---|---|---|---|---|
| AC-12 | Có báo cáo STA do chính sinh viên sinh | 1 báo cáo | `06_GDSII/sta/timing_report.txt` | ⬜ |
| AC-13 | Đếm được số tầng carry trên đường tới hạn | nêu con số cụ thể | `06_GDSII/sta/critical_path_analysis.md` | ⬜ |
| AC-14 | Nêu rõ giả định timing (virtual clock, IO delay) khi báo WNS | có nêu | `02_SPECIFICATION/timing.md` §3 | ✅ (đã nêu giả định) |

## 5. Điểm MỞ phải giải quyết trước khi làm physical design

| # | Vấn đề | Trạng thái |
|---|---|---|
| AC-15 | Ngân sách chân 28 bit > 24 chân Tiny Tapeout. Charter yêu cầu **hỏi giảng viên** trước khi chọn cách xử lý. | 🟡 **MỞ — chờ quyết định của giảng viên** |

> Vì AC-15 chưa chốt, gói này **cố ý không** bịa ra một lớp vỏ vật lý. Lõi logic
> 16-vào/12-ra đã chốt và đã kiểm chứng đầy đủ. Xem `02_SPECIFICATION/interface.md` §5.

---

## 6. Bảng tổng kết trạng thái

| Nhóm | Đạt | Mở | Chưa chạy |
|---|---:|---:|---:|
| Charter gốc (AC-1…4) | 3 | 0 | 1 |
| Chức năng (AC-5…8) | 4 | 0 | 0 |
| Cấu trúc (AC-9…11) | 3 | 0 | 0 |
| Timing (AC-12…14) | 1 | 0 | 2 |
| Điểm mở (AC-15) | 0 | 1 | 0 |
| **Tổng** | **11** | **1** | **3** |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24.*
