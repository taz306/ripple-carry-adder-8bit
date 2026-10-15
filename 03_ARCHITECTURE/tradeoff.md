# A01 · Đánh đổi kiến trúc (Trade-off Analysis)

---

## 1. Câu hỏi trung tâm của đề

> Charter mục 10 — **Chỗ hay tắc:** "Nhầm *diện tích lớn* với *chậm*. Bộ cộng ripple
> **NHỎ** nhưng **CHẬM** vì chuỗi carry 8 tầng."

Toàn bộ tài liệu này phục vụ việc chứng minh và giải thích câu đó bằng số liệu.

## 2. Bằng chứng: ripple-carry **nhỏ**

Kết quả tổng hợp thật (Yosys 0.33 + `sky130_fd_sc_hd`, góc `tt_025C_1v80`):

| Chỉ số | Giá trị đo được |
|---|---:|
| Tổng số cell | **48** |
| Flip-flop | **0** |
| Diện tích | **285.2736 µm²** |
| Ước lượng Charter | ~120–180 cell · 1×1 tile |

Kết quả thật **nhỏ hơn** ước lượng của Charter (48 < 120). Điều này hợp lý: ước lượng của
Charter mang tính dự phòng, và `abc` đã gộp nhiều cổng vào các cell phức hợp
(`a21oi`, `o21ai`, `a22oi`, `nor4bb`, …) thay vì dùng cổng cơ bản rời rạc.

Nguồn: `06_GDSII/synthesis/synth_stat.txt`.

## 3. Bằng chứng: ripple-carry **chậm** — độ trễ tỉ lệ tuyến tính với độ rộng

| Độ rộng `N` | Số cell (≈) | Độ trễ (≈) |
|---:|---|---|
| 4 | `N` × hằng số | `4` tầng carry |
| **8 (A01)** | **48 cell đo được** | **8 tầng carry** |
| 16 | ≈ gấp đôi | `16` tầng carry — **gấp đôi** |
| 32 | ≈ gấp bốn | `32` tầng carry — **gấp bốn** |

```
  Diện tích:  O(N)        ← tuyến tính, rẻ
  Độ trễ:     O(N)        ← tuyến tính, ĐẮT khi N lớn
```

Trong khi đó, các kiến trúc khác đánh đổi ngược lại.

## 4. So bốn kiến trúc cộng (chỉ để thảo luận — CLA nằm **ngoài phạm vi** A01)

| Kiến trúc | Độ trễ | Diện tích | Độ phức tạp thiết kế | Dùng khi |
|---|---|---|---|---|
| **Ripple-carry** (A01) | `O(N)` | `O(N)` — **nhỏ nhất** | Rất đơn giản | `N` nhỏ, ưu tiên diện tích/công suất, tần số thấp |
| Carry-lookahead (CLA) | `O(log N)` | `O(N log N)` | Trung bình | Cần nhanh, chịu được diện tích lớn hơn |
| Carry-select | `O(√N)` | `≈ 2×` ripple | Trung bình | Cân bằng, dễ chia khối |
| Carry-save | `O(1)` cho tổng nhiều số | Lớn | Cao | Cộng ≥ 3 toán hạng (bộ nhân) |

> ⚠️ **Ràng buộc phạm vi:** Charter mục 3 ghi rõ CLA nằm **ngoài phạm vi** A01. Bảng này
> chỉ để **so sánh trên giấy** khi bảo vệ. **Không** được thay kiến trúc trong RTL nộp bài.

### Vì sao ripple vẫn là lựa chọn đúng cho vòng đeo tay

| Tiêu chí của ứng dụng | Ripple-carry đáp ứng? |
|---|---|
| Tần số lấy mẫu bước chân: ~50 Hz | ✅ Dư sức — độ trễ tổ hợp cỡ ns, chu kỳ cỡ 20 ms |
| Ngân sách pin cực nhỏ | ✅ Ít cell nhất ⟹ ít rò và ít chuyển mạch nhất |
| Diện tích silicon 1×1 tile | ✅ 285 µm² rất thoải mái |
| Cần tần số cao | ❌ không cần |

**Kết luận:** với A01, "chậm" **không phải là nhược điểm**, vì yêu cầu tần số của ứng dụng
thấp hơn nhiều bậc so với khả năng của mạch. Chọn CLA ở đây sẽ là **tối ưu sai chỗ**: trả
thêm diện tích và công suất để mua tốc độ mà ứng dụng không dùng đến.

## 5. Đánh đổi của bốn cờ trạng thái

Trả lời câu hỏi kỹ thuật #3 của Charter ("bốn cờ tốn thêm bao nhiêu phần diện tích").

| Cờ | Logic thêm | Ảnh hưởng độ trễ |
|---|---|---|
| `C` | **0 cổng** — lấy thẳng `carry[8]` | Không thêm |
| `N` | **0 cổng** — chỉ là dây từ `sum[7]` | Không thêm |
| `Z` | Cây NOR 8 ngõ | **Thêm**, nối tiếp sau `sum` |
| `V` | 2 XOR + 1 INV + 1 AND | **Thêm**, nối tiếp sau `sum[7]` |

Cách đo chính xác phần diện tích này: tổng hợp một phiên bản **chỉ tính SUM** rồi lấy hiệu.
Script so sánh: `04_IMPLEMENTATION/scripts/compare_flags_area.sh`.
Kết quả: `06_GDSII/physical_report.md` §4.

## 6. Đánh đổi đã chọn cho bài toán ngân sách chân

| Phương án | Giữ 0 ô nhớ? | Giữ đủ 4 cờ? | Giữ cộng 8+8? |
|---|:-:|:-:|:-:|
| 1 · Nạp hai nhịp | ❌ | ✅ | ✅ |
| 2 · Thu `B` xuống 4 bit | ✅ | ✅ | ❌ |
| 3 · Bỏ bớt cờ | ✅ | ❌ | ✅ |

Không có phương án nào giữ được cả ba. Đây là lý do Charter yêu cầu **hỏi giảng viên**.
Khuyến nghị và lập luận đầy đủ: `02_SPECIFICATION/interface.md` §5.

## 7. Những đánh đổi **không** được phép trong đề này

| Cám dỗ | Vì sao không được |
|---|---|
| Viết `assign sum = a + b;` cho gọn | Mất kiến trúc ripple tường minh — không đếm được tầng carry (mục 9) |
| Thêm thanh ghi để "chạy nhanh hơn" | Vi phạm REQ-A01-007, đổi loại mạch |
| Đổi sang CLA vì "tốt hơn" | Ngoài phạm vi (mục 3) |
| Sửa netlist bằng tay | Ngoài phạm vi (mục 3) |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-A01-033, Charter mục 2 câu 3, mục 10.*
