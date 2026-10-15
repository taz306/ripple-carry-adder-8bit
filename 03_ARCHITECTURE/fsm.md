# A01 · Máy trạng thái (FSM)

---

## 1. Kết luận: **A01 KHÔNG có FSM** — và đây là câu trả lời đúng

> Một mạch tổ hợp không có trạng thái. Không có trạng thái thì không có máy trạng thái.

Tài liệu này tồn tại trong form chuẩn để giữ cấu trúc thống nhất cho cả 80 đề. Với A01,
nội dung đúng là **giải thích vì sao không có**, chứ không phải vẽ một sơ đồ trạng thái giả.

## 2. Ba bằng chứng A01 không có trạng thái

| # | Bằng chứng | Nơi kiểm |
|---|---|---|
| 1 | RTL **không có** `always_ff`, không có `posedge`, không có toán tử `<=` phi khối | `04_IMPLEMENTATION/rtl/a01_ripple_adder.sv` |
| 2 | Tổng hợp cho **0 flip-flop** — không có `sky130_fd_sc_hd__dfxtp` nào trong bảng cell | `06_GDSII/synthesis/synth_stat.txt` |
| 3 | Module **không có cổng** `clk` hay `rst` | `02_SPECIFICATION/interface.md` §2 |

Trích bảng cell thật sau tổng hợp (Yosys 0.33 + sky130_fd_sc_hd): toàn bộ 48 cell đều là
cổng tổ hợp (`nand2`, `nor2`, `xor2`, `xnor2`, `a21oi`, `o21ai`, …). **Không có một cell
tuần tự nào.**

## 3. So sánh: khi nào một đề trong bộ 80 mới có FSM

| Nhóm đề | Có FSM? | Ví dụ |
|---|:-:|---|
| **A · Số học tổ hợp** (A01 thuộc nhóm này) | ❌ | A01 cộng ripple, A05 nhân mảng |
| **B · Mã hoá / giải mã tổ hợp** | ❌ | B01 BCD→7 đoạn |
| **C · Giám sát / cảnh báo** | ⚠️ một phần | C04 hysteresis có trạng thái |
| **D · Bộ đếm** | ✅ trạng thái là giá trị đếm | D01 đếm 8-bit |
| **E · Thanh ghi dịch** | ✅ | E05 CRC-8 nối tiếp |
| **F · FSM** | ✅ trọng tâm | F05 điều khiển thang máy |

## 4. Nếu buộc phải mô tả A01 bằng ngôn ngữ FSM

Có thể viết A01 như một FSM **một trạng thái duy nhất**, không có chuyển trạng thái:

```
        ┌──────────────────────────────────┐
        │                                  │
        │   S0: TINH_TO_HOP                │
   ────▶│   sum,c,z,n,v = f(a,b)           │
        │                                  │
        └──────────────────────────────────┘
              (không có cạnh chuyển)
```

Cách mô tả này **đúng về mặt hình thức nhưng vô ích**: nó không thêm thông tin nào. Sinh
viên **không nên** nộp sơ đồ này như "artifact số có chú thích" — artifact hợp lệ cho A01 là
**sơ đồ khối chuỗi carry** (`block_diagram.md`) và **waveform** (`05_VERIFICATION/waveforms/`).

## 5. Trường hợp FSM sẽ xuất hiện

Chỉ khi giảng viên duyệt **Phương án 1** cho bài toán ngân sách chân
(`02_SPECIFICATION/interface.md` §5). Khi đó FSM 2 trạng thái nằm trong **wrapper**, không
phải trong lõi — chi tiết ở `03_ARCHITECTURE/control.md` §5.

Trạng thái hiện tại: 🟡 chưa chốt (AC-15). Gói này **không** hiện thực wrapper đó.

## 6. Câu hỏi bảo vệ liên quan

> **Hỏi:** Mạch không có clock, vậy tại sao carry lại "đi tuần tự" qua 8 tầng?
>
> **Đáp:** "Tuần tự" ở đây là **phụ thuộc dữ liệu**, không phải **phụ thuộc chu kỳ**.
> `carry[i+1]` cần `carry[i]` đã ổn định về mặt **vật lý** (điện áp đã xác lập), chứ không
> phải đợi một cạnh clock. Đó là độ trễ lan truyền, không phải trạng thái. Mạch vẫn là tổ hợp
> vì đầu ra chỉ là hàm của đầu vào hiện tại, không phụ thuộc lịch sử đầu vào.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Trạng thái: KHÔNG ÁP DỤNG (có lý giải).*
