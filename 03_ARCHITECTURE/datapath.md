# A01 · Đường dữ liệu (Datapath)

---

## 1. Toàn bộ khối A01 **là** datapath

A01 không có phần điều khiển. Mọi tín hiệu đều là dữ liệu chảy một chiều từ đầu vào ra đầu
ra, không có tín hiệu nào đóng vai trò lệnh, chọn chế độ, hay enable.

```
  a[7:0] ═══╗
            ╠══▶ ┌──────────────────────────────┐ ══▶ sum[7:0]   (dữ liệu chính)
  b[7:0] ═══╝    │  chuỗi 8 tầng ripple-carry   │ ──▶ c          (trạng thái)
                 │  + logic sinh cờ             │ ──▶ z          (trạng thái)
                 └──────────────────────────────┘ ──▶ n          (trạng thái)
                                                  ──▶ v          (trạng thái)
```

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `a[7:0]` | 8 | cổng vào | 8 tầng FA + logic `V` | Toán hạng |
| `b[7:0]` | 8 | cổng vào | 8 tầng FA + logic `V` | Toán hạng |
| `carry[8:0]` | 9 | nội bộ | nối tầng `i` → `i+1` | **Đường nối tiếp — nguồn gốc độ trễ** |
| `sum[7:0]` | 8 | 8 tầng FA | cổng ra + logic `Z` + logic `V` | Kết quả |
| `c` | 1 | `carry[8]` | cổng ra | Cờ |
| `z` | 1 | NOR(`sum`) | cổng ra | Cờ |
| `n` | 1 | `sum[7]` | cổng ra | Cờ (chỉ là dây) |
| `v` | 1 | logic từ `a[7]`,`b[7]`,`sum[7]` | cổng ra | Cờ |

## 3. Đồ thị phụ thuộc (dependency graph)

```
 mức 0   a[0] b[0]                                       ← sẵn sàng ngay
           │
 mức 1   carry[1] ───┬──▶ sum[1] (cùng a[1],b[1])
           │         │
 mức 2   carry[2] ───┼──▶ sum[2]
           │         │
 mức 3   carry[3] ───┼──▶ sum[3]
           │         │
 mức 4   carry[4] ───┼──▶ sum[4]
           │         │
 mức 5   carry[5] ───┼──▶ sum[5]
           │         │
 mức 6   carry[6] ───┼──▶ sum[6]
           │         │
 mức 7   carry[7] ───┴──▶ sum[7] ──┬──▶ n          (mức 8)
           │                       │
 mức 8   carry[8] ──▶ c            ├──▶ z  (qua cây NOR, +2..3 mức)
                                   └──▶ v  (qua 1 XOR + 1 AND, +2 mức)
```

**Độ sâu logic:**

| Đầu ra | Độ sâu tính từ đầu vào |
|---|---|
| `sum[0]` | 1 (chỉ 1 XOR) — **nông nhất** |
| `sum[i]` | ≈ `i` tầng carry + 1 XOR |
| `c` | **8 tầng carry** |
| `n` | 8 tầng carry (vì `n = sum[7]`) |
| `z` | 8 tầng carry + cây NOR — **có thể sâu nhất** |
| `v` | 8 tầng carry + 2 cổng |

> 🔎 **Dự đoán cần kiểm bằng STA:** endpoint tới hạn nhiều khả năng là `z` hoặc `v`, **không**
> phải `c`, vì `z` và `v` nằm **nối tiếp sau** `sum[7]` vốn đã ở cuối chuỗi carry.
> Đây là một dự đoán có thể sai — phải đối chiếu với `06_GDSII/sta/timing_report.txt`.
> Nếu STA cho kết quả khác, **tin STA**, và giải thích vì sao (ví dụ: tool đã tính `z` bằng
> cây cân bằng nên rẻ hơn dự đoán).

## 4. Vì sao không có thanh ghi trong datapath

| Câu hỏi | Trả lời |
|---|---|
| Dữ liệu có cần giữ qua chu kỳ không? | Không — A01 tính xong trong một lần lan truyền |
| Có pipeline không? | Không — Charter chốt loại mạch Tổ hợp |
| Tổng tích luỹ giữ ở đâu? | Ở thanh ghi TỔNG **bên ngoài** — xem `system_diagram.md` §1 |
| Nếu thêm thanh ghi thì sao? | Vi phạm REQ-A01-007 và mục 10 của Charter ("dấu hiệu làm đúng: 0 ô nhớ") |

## 5. Cơ hội pipeline (chỉ để thảo luận — **ngoài phạm vi**)

Nếu được phép thêm ô nhớ, có thể cắt chuỗi carry làm hai nửa 4-bit và chèn thanh ghi:

```
 [FA0..FA3] ──▶ REG ──▶ [FA4..FA7]
  độ trễ/tầng giảm ~1/2, thông lượng tăng ~2×, chi phí: +9 FF, +1 chu kỳ độ trễ
```

Phương án này **không được dùng** cho A01 (Charter mục 3: tự tối ưu netlist bằng tay và đổi
kiến trúc nằm ngoài phạm vi). Ghi ở đây chỉ để trả lời câu hỏi "có cách nào nhanh hơn không"
khi bảo vệ. Xem thêm `tradeoff.md`.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24.*
