# A01 · Sơ đồ khối (Block Diagram)

---

## 1. Chuỗi 8 tầng full-adder

```
 carry[0]=0
     │
     ▼
  ┌──────┐   c1   ┌──────┐   c2   ┌──────┐   c3   ┌──────┐
  │ FA 0 │───────▶│ FA 1 │───────▶│ FA 2 │───────▶│ FA 3 │──▶ c4 ─┐
  └──┬───┘        └──┬───┘        └──┬───┘        └──┬───┘        │
  a0,b0            a1,b1           a2,b2           a3,b3          │
     │ s0             │ s1            │ s2            │ s3        │
     ▼                ▼               ▼               ▼           │
   sum[0]           sum[1]          sum[2]          sum[3]        │
                                                                  │
  ┌───────────────────────────────────────────────────────────────┘
  │
  ▼  c4
  ┌──────┐   c5   ┌──────┐   c6   ┌──────┐   c7   ┌──────┐   c8
  │ FA 4 │───────▶│ FA 5 │───────▶│ FA 6 │───────▶│ FA 7 │───────▶ C
  └──┬───┘        └──┬───┘        └──┬───┘        └──┬───┘
  a4,b4            a5,b5           a6,b6           a7,b7
     │ s4             │ s5            │ s6            │ s7
     ▼                ▼               ▼               ▼
   sum[4]           sum[5]          sum[6]          sum[7]──┬──▶ N
                                                            │
        sum[7:0] ──▶ [ NOR 8 ngõ ] ──▶ Z                    │
                                                            │
        a[7], b[7], sum[7] ──▶ [ logic V ] ──▶ V ◀──────────┘
```

## 2. Bên trong một tầng full-adder

```
                a[i] ──┬──────────────┐
                       │              │
                b[i] ──┼──┬───────────┼────┐
                       │  │           │    │
                       ▼  ▼           ▼    ▼
                    ┌───────┐      ┌────┐ ┌────┐
                    │ XOR   │      │AND │ │AND │
                    │ a^b   │      │a&b │ │a&ci│
                    └───┬───┘      └─┬──┘ └─┬──┘
                        │            │      │      ┌────┐
        carry[i] ───┬───┼────────────┼──────┼─────▶│AND │ b&ci
                    │   ▼            │      │      └─┬──┘
                    │ ┌───────┐      │      │        │
                    └▶│ XOR   │      ▼      ▼        ▼
                      │  ^ci  │    ┌──────────────────┐
                      └───┬───┘    │   OR 3 ngõ       │
                          │        └────────┬─────────┘
                          ▼                 ▼
                       sum[i]           carry[i+1]
```

Công thức tương ứng trong RTL:

```systemverilog
assign sum[i]     = a[i] ^ b[i] ^ carry[i];
assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
```

`carry[i+1]` chính là hàm **đa số (majority)** của ba bit `a[i]`, `b[i]`, `carry[i]`.

## 3. Điểm mấu chốt về đường tới hạn

```
   ĐƯỜNG NGẮN (không tới hạn)        ĐƯỜNG DÀI (tới hạn)
   ────────────────────────          ───────────────────────────────────

   a[i] ─┐                           a[0] ─┐
         ├─XOR─ 1 tầng ─▶ sum[i]           ├─▶c1─▶c2─▶c3─▶c4─▶c5─▶c6─▶c7─▶c8
   b[i] ─┘   (sau khi carry[i] tới)  b[0] ─┘
                                            └──── 8 tầng nối tiếp ────┘
```

* `sum[i]` = **1 tầng XOR** tính từ lúc `carry[i]` đã ổn định.
* `carry[8]` = **8 tầng sinh carry** nối tiếp, không thể song song hoá trong kiến trúc này.

Do đó **chuỗi carry, không phải XOR, quyết định tần số tối đa** (trả lời Charter mục 9).

## 4. Khối sinh cờ — nằm ngoài chuỗi carry

```
 ┌────────────────────────────────────────────────────────────┐
 │ C  ← carry[8]                     (0 cổng thêm — lấy thẳng)│
 │ N  ← sum[7]                       (0 cổng thêm — chỉ dây)  │
 │ Z  ← NOR( sum[0] … sum[7] )       (cây NOR ~3 cổng)        │
 │ V  ← ¬(a[7] ⊕ b[7]) ∧ (sum[7] ⊕ a[7])   (2 XOR + 1 INV + 1 AND) │
 └────────────────────────────────────────────────────────────┘
```

Quan sát quan trọng cho câu hỏi kỹ thuật #3 của Charter ("bốn cờ tốn thêm bao nhiêu diện tích"):

* `C` và `N` **không tốn cổng nào** — chúng là tín hiệu đã có sẵn, chỉ đưa ra ngoài.
* Chỉ `Z` và `V` cần logic thêm.
* Cả `Z` lẫn `V` đều **nhánh ra từ** `sum`, tức chúng **nối tiếp sau** chuỗi carry → có thể
  kéo dài đường tới hạn thêm vài tầng cổng. Báo cáo STA sẽ cho biết endpoint thật là `c`,
  `z` hay `v`.

Số liệu đo được: xem `06_GDSII/physical_report.md` §4.

## 5. Ánh xạ RTL → phần cứng

| Cấu trúc RTL | Phần cứng sinh ra | Ghi chú |
|---|---|---|
| `generate for (i=0..7)` | 8 bản sao của logic full-adder | **Không** phải vòng lặp thời gian — là nhân bản không gian |
| `assign` | logic tổ hợp | Không sinh flip-flop |
| `carry[i+1]` phụ thuộc `carry[i]` | dây nối nối tiếp giữa các tầng | Nguồn gốc của độ trễ |
| `assign z = (sum == 8'h00)` | cây NOR/NAND so sánh | Tool tự chọn cấu trúc cây |
| Không có `always_ff` | **0 flip-flop** | Đã xác nhận: `06_GDSII/synthesis/synth_stat.txt` |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Thành phần hồ sơ bắt buộc #5 (artifact số có chú thích).*
