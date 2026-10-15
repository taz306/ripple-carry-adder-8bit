# A01 · Phần điều khiển (Control)

---

## 1. Kết luận: **A01 không có phần điều khiển**

Đây là kết quả **hợp lệ và bắt buộc** của đề, không phải phần bị bỏ sót.

| Thành phần điều khiển thông thường | Có trong A01? | Vì sao |
|---|:-:|---|
| Máy trạng thái (FSM) | ❌ | Không có trạng thái để nhớ |
| Thanh ghi điều khiển | ❌ | Không có ô nhớ (REQ-A01-007) |
| Tín hiệu `enable` / `start` / `done` | ❌ | Không có giao thức bắt tay |
| Tín hiệu `valid` / `ready` | ❌ | Không có luồng dữ liệu theo nhịp |
| Bộ giải mã lệnh / chọn chế độ | ❌ | Chỉ có một phép toán duy nhất: cộng |
| Bộ đếm chu kỳ | ❌ | Tính xong trong một lần lan truyền |
| Clock, reset | ❌ | Mạch tổ hợp |

## 2. Vì sao mạch tổ hợp không cần điều khiển

Phần điều khiển tồn tại để trả lời câu hỏi **"bây giờ làm bước nào"**. Câu hỏi đó chỉ có
nghĩa khi phép tính được chia thành nhiều bước theo thời gian.

A01 tính **toàn bộ** kết quả trong **một** lần lan truyền tín hiệu:

```
   t = 0          đầu vào a, b thay đổi
   0 < t < T      tín hiệu lan qua 8 tầng carry (đầu ra có thể glitch)
   t ≥ T          mọi đầu ra ổn định và đúng
```

Không có "bước 1, bước 2". Vì vậy không có gì để điều khiển.

## 3. Điều khiển nằm ở đâu trong hệ thống

Điều khiển **có tồn tại**, nhưng ở tầng ngoài:

```
 ┌──────────────────────── TẦNG NGOÀI (không thuộc A01) ─────────────────────┐
 │                                                                           │
 │   clk ──────────┬──────────────────────────────────────────┐              │
 │   rst_n ────────┤                                          │              │
 │                 ▼                                          ▼              │
 │        ┌─────────────────┐                        ┌─────────────────┐     │
 │        │ Thanh ghi TỔNG  │                        │ Logic enable:   │     │
 │        │  (có clock)     │◀───────────────────────│ chỉ ghi khi có  │     │
 │        └────────┬────────┘        SUM[7:0]        │ bước mới hợp lệ │     │
 │                 │ A[7:0]                          └─────────────────┘     │
 │  ───────────────┼───────────────────────────────────────────────────────  │
 │                 ▼                                                         │
 │        ╔═════════════════════════════════════════╗                        │
 │        ║      A01 — thuần datapath, 0 điều khiển ║                        │
 │        ╚═════════════════════════════════════════╝                        │
 └───────────────────────────────────────────────────────────────────────────┘
```

Tầng ngoài chịu trách nhiệm:

1. Cấp clock và reset cho thanh ghi TỔNG.
2. Quyết định **khi nào** lấy mẫu `SUM` (phải sau khi A01 đã ổn định — số liệu từ STA).
3. Xử lý cờ `C` (mở rộng đa byte), `Z` (phát hiện reset ngày mới).

## 4. Nghĩa vụ hợp đồng của tầng ngoài

| Nghĩa vụ | Nguồn số liệu |
|---|---|
| Chu kỳ clock hệ thống ≥ `t_ckq + t_A01_max + t_setup + t_skew` | `t_A01_max` từ `06_GDSII/sta/` |
| Đầu vào `a`, `b` không chứa `X`/`Z` | Thiết kế tầng ngoài |
| Không lấy mẫu `SUM` trong cửa sổ glitch | `02_SPECIFICATION/timing.md` §5 |

## 5. Nếu chọn Phương án 1 của bài toán ngân sách chân

Trường hợp giảng viên duyệt **Phương án 1 (nạp hai nhịp)** ở
`02_SPECIFICATION/interface.md` §5, thì **một FSM 2 trạng thái sẽ xuất hiện** — nhưng trong
**lớp vỏ (wrapper)**, không phải trong lõi `a01_ripple_adder`:

```
        ┌──────────────┐  nhip_moi   ┌──────────────┐
   ────▶│ S0: NAP_B    │────────────▶│ S1: PHAT_CO  │──┐
        │ uio = input  │             │ uio = output │  │
        └──────────────┘◀────────────└──────────────┘◀─┘
```

Khi đó phải cập nhật lại toàn bộ tầng 02 và 03, vì loại mạch đổi từ **Tổ hợp** sang **Tuần tự**
— tức là đã lệch khỏi phân loại của Charter. Đó chính là lý do Charter bắt **hỏi giảng
viên trước**.

Hiện trạng: 🟡 **chưa chốt** (AC-15).

---

*Phiên bản: v1.0 · Ngày: 2026-09-24.*
