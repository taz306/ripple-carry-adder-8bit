# A01 · Giao diện (Interface)

---

## 1. Ánh xạ chân theo Charter (mục 4)

```
ui_in[7:0]   = A            (8 bit vào)
uio_in[7:0]  = B            (8 bit vào)
uo_out[7:0]  = SUM          (8 bit ra)
uio_out[3:0] = {V, N, Z, C} (4 bit ra)
```

## 2. Bảng giao diện đã CHỐT — lõi logic `a01_ripple_adder`

| Tín hiệu | Chiều | Độ rộng | Mức tích cực | Ý nghĩa | Giả định |
|---|---|---:|---|---|---|
| `a[7:0]` | input | 8 | — | Tổng hiện tại / toán hạng A | Do thanh ghi TỔNG bên ngoài cấp; luôn hợp lệ (không X/Z) |
| `b[7:0]` | input | 8 | — | Số bước mới đo được / toán hạng B | Do bộ phát hiện bước chân cấp; luôn hợp lệ |
| `sum[7:0]` | output | 8 | — | 8 bit thấp của `A + B` | Chỉ hợp lệ sau khi carry lan hết chuỗi |
| `c` | output | 1 | active-high | Tràn **không dấu** (`A+B ≥ 256`) | — |
| `z` | output | 1 | active-high | `SUM == 0` | — |
| `n` | output | 1 | active-high | Bit dấu `SUM[7]` (diễn giải bù 2) | — |
| `v` | output | 1 | active-high | Tràn **có dấu** (bù 2) | — |

**Thứ tự cờ trên bus:** `uio_out[3:0] = {V, N, Z, C}` ⟹ `uio_out[0]=C`, `[1]=Z`, `[2]=N`, `[3]=V`.

**Không có** clock, reset, enable, valid/ready hay bất kỳ tín hiệu điều khiển nào.
A01 là lõi **tổ hợp thuần** (REQ-A01-007).

Khai báo module tương ứng (đã chốt, không được đổi):

```systemverilog
module a01_ripple_adder (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] sum,
    output logic       c,
    output logic       z,
    output logic       n,
    output logic       v
);
```

## 3. Ngân sách chân

| Hạng mục | Số bit |
|---|---:|
| Vào: `A` + `B` | 8 + 8 = **16** |
| Ra: `SUM` + 4 cờ | 8 + 4 = **12** |
| **Tổng logic cần** | **28** |
| Ô Tiny Tapeout có | **24** |
| **Chênh lệch** | **+4 (VƯỢT)** |

Nhắc lại cấu trúc chân Tiny Tapeout (Charter mục 4):

> Một ô Tiny Tapeout có đúng 24 chân: `ui_in` 8 chỉ vào, `uo_out` 8 chỉ ra, `uio` 8 chọn
> chiều từng chân. **`uio_in` và `uio_out` là cùng một bộ chân vật lý.**

Đây chính là nguồn gốc xung đột: đề cần `uio` **vừa** nhận `B[7:0]` (8 bit vào) **vừa**
phát 4 cờ ra — trên cùng 8 chân vật lý, tại cùng một thời điểm. Không thể.

## 4. Trạng thái CHỐT / CHƯA CHỐT

| Lớp | Trạng thái | Ghi chú |
|---|---|---|
| **Lõi logic** `a01_ripple_adder` (16 vào / 12 ra) | ✅ **ĐÃ CHỐT** | Đã kiểm chứng vét cạn, đã tổng hợp |
| **Lớp vỏ vật lý** (wrapper 24 chân) | 🟡 **CHƯA CHỐT** | Cần giảng viên quyết định |

> Charter mục 4 nói nguyên văn: *"Vượt ngân sách chân: thiết kế cần 28 bit trong khi ô chỉ
> có 24 chân. Khối này là mạch tổ hợp nên nạp hai nhịp sẽ thêm ô nhớ; **phải hỏi giảng viên
> trước khi chọn cách xử lý**."*

Gói này **cố ý không** tự bịa ra một wrapper. Mọi bằng chứng ở tầng 05 và 06 đều thuộc về
lõi logic đã chốt.

## 5. Ba phương án xử lý vượt ngân sách chân

### Phương án 1 — Nạp hai nhịp (time-multiplex đầu vào)

```
Nhịp 1: uio_in ← B[7:0], chốt vào thanh ghi B_reg
Nhịp 2: uio chuyển sang chiều ra, phát {V,N,Z,C}
```

| Ưu | Nhược |
|---|---|
| Giữ đủ 8 bit của `B` | **Thêm thanh ghi B_reg + FSM 2 trạng thái ⟹ vi phạm REQ-A01-007 (0 ô nhớ)** |
| Đúng với kiến trúc Tiny Tapeout thông dụng | Đổi loại mạch từ Tổ hợp sang Tuần tự — khác Charter |

### Phương án 2 — Thu hẹp toán hạng B xuống 4 bit

```
uio_in[3:0]  = B[3:0]   (số bước mới ≤ 15 mỗi chu kỳ — hợp lý về vật lý)
uio_out[7:4] = {V,N,Z,C}
```

| Ưu | Nhược |
|---|---|
| **Giữ 0 ô nhớ** — đúng REQ-A01-007 | Đổi đặc tả: không còn là "cộng 8-bit + 8-bit" |
| Vừa khít 24 chân, không cần FSM | Chuỗi carry vẫn 8 tầng, nhưng 4 tầng trên chỉ lan carry |

### Phương án 3 — Chỉ phát một cờ tổng hợp

```
uio_in[7:0]  = B[7:0]
uo_out[7:0]  = SUM[7:0]
... còn thiếu chân cho cờ → phải hy sinh 4 cờ, chỉ giữ 1 chân báo "có bất thường"
```

| Ưu | Nhược |
|---|---|
| Giữ nguyên phép cộng 8+8 | **Mất thông tin cờ ⟹ vi phạm REQ-A01-002…005** |

### Khuyến nghị để giảng viên duyệt

**Phương án 2** là phương án duy nhất giữ được **cả** tính tổ hợp (0 ô nhớ — dấu hiệu làm
đúng theo Charter mục 10) **và** đủ 4 cờ. Chi phí là thu hẹp `B`, điều này hợp lý về mặt
ứng dụng: số bước mới đo được trong một chu kỳ lấy mẫu hiếm khi vượt 15.

**Phương án 1** đúng về chức năng nhưng biến A01 thành mạch tuần tự — nên để dành cho
nhóm đề C/D/E, không phải nhóm A.

> ☐ **Ô chờ quyết định của giảng viên:** Phương án được chọn: ______  · Ngày: ____________

## 6. Điều kiện hợp lệ của đầu vào

| Điều kiện | Ai bảo đảm |
|---|---|
| `a`, `b` không chứa `X`/`Z` | Tầng ngoài (thanh ghi TỔNG, bộ phát hiện bước) |
| Đầu ra được lấy mẫu **sau** khi carry lan hết chuỗi | Tầng ngoài, theo số liệu STA ở `06_GDSII/sta/` |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-A01-010…013, AC-1, AC-15.*
