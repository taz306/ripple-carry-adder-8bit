# A01 · Đặc tả chức năng (Functional Specification)

Tài liệu này định nghĩa **hành vi đúng** của khối A01, độc lập với cách hiện thực.
Đây là văn bản chuẩn mà golden model và testbench đều phải tuân theo.

---

## 1. Phương trình hành vi

Gọi `A`, `B` ∈ [0, 255] là hai toán hạng 8-bit không dấu (bit-pattern), và

```
T = A + B            (tổng 9-bit, không cắt)
```

thì:

| Đầu ra | Định nghĩa |
|---|---|
| `SUM[7:0]` | `T mod 256`  — tức `T[7:0]` |
| `C` | `T[8]`  ⟺  `A + B ≥ 256`  (tràn **không dấu**) |
| `Z` | `1` ⟺ `SUM == 0x00` |
| `N` | `SUM[7]` |
| `V` | `¬(A[7] ⊕ B[7]) ∧ (SUM[7] ⊕ A[7])`  (tràn **có dấu**, bù 2) |

Dạng SystemVerilog tương đương (dùng trong golden model):

```systemverilog
tmp = {1'b0, a} + {1'b0, b};
sum = tmp[7:0];
c   = tmp[8];
z   = (tmp[7:0] == 8'h00);
n   = tmp[7];
v   = ~(a[7] ^ b[7]) & (tmp[7] ^ a[7]);
```

## 2. Đặc tả cấu trúc bắt buộc — chuỗi ripple-carry

Charter đặt tên đề là **ripple-carry**, và mục 9 yêu cầu đếm số tầng carry trên đường tới
hạn. Vì vậy hành vi ở §1 **chưa đủ**: cách hiện thực cũng bị ràng buộc.

```
carry[0]   = 0
với i = 0..7:
    SUM[i]     = A[i] ⊕ B[i] ⊕ carry[i]
    carry[i+1] = (A[i] ∧ B[i]) ∨ (A[i] ∧ carry[i]) ∨ (B[i] ∧ carry[i])
C = carry[8]
```

> ❗ **Không** được viết `assign sum = a + b;` trong RTL nộp bài. Toán tử `+` cho phép công
> cụ tổng hợp tự chọn kiến trúc (thường là carry-lookahead hoặc carry-select), làm mất đúng
> thứ Charter yêu cầu quan sát. Toán tử `+` **chỉ** được dùng trong golden model
> (`05_VERIFICATION/golden_model/`), nơi nó đóng vai trò chuẩn so sánh độc lập.

## 3. Bảng hành vi — 5 ca bắt buộc của Charter

| # | A | B | SUM | C | Z | N | V | Diễn giải |
|---|---:|---:|---:|:-:|:-:|:-:|:-:|---|
| 1 | 0 | 0 | 0 | 0 | **1** | 0 | 0 | Trường hợp tầm thường, kiểm `Z` |
| 2 | 255 | 0 | 255 | 0 | 0 | **1** | 0 | Cộng 0, kiểm `N` (bù 2: −1 + 0 = −1) |
| 3 | 255 | 1 | 0 | **1** | **1** | 0 | 0 | Tràn **không dấu**: `C`=1 nhưng `V`=0 (bù 2: −1 + 1 = 0, đúng) |
| 4 | 127 | 1 | 128 | 0 | 0 | **1** | **1** | Tràn **có dấu**: `V`=1 nhưng `C`=0 (bù 2: 127 + 1 = −128, sai) |
| 5 | 200 | 100 | 44 | **1** | 0 | 0 | 0 | Tràn không dấu thông thường |

Ca 3 và ca 4 chính là **cặp phản chứng** chứng minh `C` và `V` là hai khái niệm khác nhau.

## 4. Vì sao `C` ≠ `V` — điểm dễ sai nhất của đề này

Cùng một mạch cộng 8-bit, hai cách **diễn giải** bit-pattern:

| | Không dấu (unsigned) | Có dấu, bù 2 (signed) |
|---|---|---|
| Dải biểu diễn | 0 … 255 | −128 … +127 |
| Cờ báo sai | `C` | `V` |
| Quy tắc | kết quả > 255 | hai số cùng dấu ra kết quả khác dấu |

Bốn tổ hợp đều xảy ra được:

| A | B | C | V | Giải thích |
|---:|---:|:-:|:-:|---|
| 1 | 1 | 0 | 0 | Đúng ở cả hai cách hiểu |
| 200 | 100 | **1** | 0 | Tràn unsigned; signed: −56 + 100 = 44 — đúng |
| 127 | 1 | 0 | **1** | Không tràn unsigned; signed: 127 + 1 = −128 — sai |
| 128 | 128 | **1** | **1** | Tràn cả hai: 256→0; signed −128 + −128 = 0 — sai |

Bốn tổ hợp này đều có trong `05_VERIFICATION/test_matrix.csv` (TC-005, TC-004, TC-006).

## 5. Tính chất bất biến (invariants) — dùng làm assertion

| ID | Bất biến | Vị trí kiểm |
|---|---|---|
| INV-1 | `{C, SUM} == A + B` (ghép 9 bit) | assertion + golden model |
| INV-2 | `Z == (SUM == 0)` | assertion |
| INV-3 | `N == SUM[7]` | assertion |
| INV-4 | `A[7] != B[7]` ⟹ `V == 0` (khác dấu thì không bao giờ tràn có dấu) | assertion |
| INV-5 | `A + B` giao hoán: kết quả với `(A,B)` = kết quả với `(B,A)` | quét vét cạn |
| INV-6 | Không có tín hiệu nào phụ thuộc thời gian / trạng thái trước | 0 FF sau tổng hợp |

File assertion: `05_VERIFICATION/assertions/a01_sva.sv`.

## 6. Điều kiện biên và hành vi không xác định

| Tình huống | Hành vi quy định |
|---|---|
| `A` hoặc `B` có bit `X`/`Z` | **Không** đặc tả. A01 là lõi tổ hợp; tầng ngoài phải bảo đảm đầu vào hợp lệ. |
| Không có clock | Đúng như thiết kế. Không được thêm. |
| Không có reset | Đúng như thiết kế. Mạch tổ hợp không có trạng thái để reset. |
| Đầu vào đổi giá trị | Đầu ra có thể sinh **glitch** trong thời gian lan truyền carry trước khi ổn định. Đây là hành vi bình thường của mạch tổ hợp; tầng ngoài phải lấy mẫu sau khi đã ổn định. |

## 7. Không gian đầu vào

`2^8 × 2^8 = 65 536` tổ hợp — đủ nhỏ để **quét vét cạn**. Vì vậy A01 không cần kiểm thử
ngẫu nhiên có ràng buộc: kiểm chứng vét cạn là **chứng minh hoàn chỉnh** ở mức hành vi
đối với mô hình chuẩn.

Kết quả thật: **65 536/65 536 khớp, 0 lỗi** — xem `05_VERIFICATION/verification_report.md`.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-A01-001…007.*
