# A01 · Giản đồ thời gian (Timing Diagram)

A01 không có clock, nên giản đồ ở đây là **giản đồ lan truyền tín hiệu**, không phải giản
đồ chu kỳ.

---

## 1. Lan truyền carry — ca xấu nhất `A=255, B=1` (TC-003)

Đây là ca ép carry lan qua **cả 8 tầng**: `0xFF + 0x01 = 0x00` với `C=1`.

```
             t0        t1     t2     t3     t4     t5     t6     t7     t8
             │         │      │      │      │      │      │      │      │
 a,b  ───────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
             │ đổi giá trị (255, 1)
             │
 carry[1] ───┴──▁▁▁▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
                 │ ổn định
 carry[2] ───────┴──▁▁▁▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
                        │
 carry[3] ──────────────┴──▁▁▁▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
                               │
 carry[4] ─────────────────────┴──▁▁▁▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
                                      │
 carry[5] ────────────────────────────┴──▁▁▁▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
                                             │
 carry[6] ───────────────────────────────────┴──▁▁▁▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
                                                    │
 carry[7] ──────────────────────────────────────────┴──▁▁▁▔▔▔▔▔▔▔▔▔▔▔▔▔
                                                           │
 carry[8]=C ───────────────────────────────────────────────┴──▁▁▁▔▔▔▔▔▔
                                                                  │ C=1 ỔN ĐỊNH
                                                                  │
 sum[7:0] ───┤XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX├─── 0x00
             │◀────────── VÙNG GLITCH — KHÔNG ĐƯỢC LẤY MẪU ────▶│
             │                                                  │
             │◀────────────────── t_A01_max ───────────────────▶│
```

**Đọc giản đồ:**

* Mỗi mũi tên `carry[i] → carry[i+1]` là **một tầng trễ**. Có đúng **8** tầng.
* `sum[7:0]` **không** ổn định ngay: trong lúc carry lan, các bit `sum` lần lượt đổi giá trị
  → sinh **glitch**.
* Tầng ngoài chỉ được lấy mẫu **sau** `t_A01_max`.

## 2. Ca tốt nhất — `A=0xAA, B=0x55` (TC-010)

Không tầng nào sinh carry (`a[i] & b[i] = 0` với mọi `i`, và `carry[i] = 0`):

```
 a,b  ───┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
         │ đổi (0xAA, 0x55)
 carry[*]─┴──── giữ nguyên 0 ──────────────────
         │
 sum[7:0]┤▒▒├───────── 0xFF ───────────────────
         │◀▶│
         │ chỉ 1 tầng XOR
         │◀─ t_min ─▶│
```

`t_min ≈ 1 tầng XOR` — nhanh hơn ca xấu nhất khoảng **8 lần**. Chênh lệch này chính là
bằng chứng trực quan rằng **chuỗi carry, không phải XOR, là nút thắt**.

## 3. So sánh hai ca

| | TC-010 (`0xAA+0x55`) | TC-003 (`0xFF+0x01`) |
|---|---|---|
| Số tầng carry phải lan | 0 | **8** |
| Độ trễ tương đối | `≈ 1 tầng XOR` | `≈ 8 tầng carry + 1 XOR` |
| Có glitch trên `sum`? | Rất ít | Nhiều |
| Vai trò | ca nhanh nhất | **ca xác định `t_A01_max`** |

> 👉 Khi chạy STA hoặc mô phỏng gate-level có SDF, **TC-003 là vector kích hoạt đường tới hạn**.

## 4. Vì sao `Z` và `V` ổn định **sau** `SUM`

```
 sum[7:0] ─────────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  ổn định tại t8
                   │
 n = sum[7] ───────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  cùng lúc (chỉ là dây)
                   │
 z = NOR(sum) ─────┼──┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  trễ thêm cây NOR
                   │  │
 v = f(a7,b7,sum7)─┼──┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  trễ thêm 2 cổng
                   │  │
                   │◀▶│ phần trễ cộng thêm của cờ
```

Hệ quả: endpoint tới hạn thật có thể là `z` hoặc `v` chứ không phải `c`.
**Phải đọc báo cáo STA để biết chắc** — xem `06_GDSII/sta/`.

## 5. Waveform thật đã thu được

File: `05_VERIFICATION/waveforms/a01_waves.vcd`
Công cụ tạo: Icarus Verilog 12.0, lệnh `vvp a01_sim`
Nội dung: 10 ca có tên (TC-001 … TC-010), mỗi ca cách nhau 1 ns

Mở bằng:

```bash
gtkwave 05_VERIFICATION/waveforms/a01_waves.vcd
```

> Lưu ý: waveform này là **mô phỏng RTL** (behavioral), nên **không có độ trễ cổng** —
> mọi tín hiệu đổi tức thời tại mốc `#1`. Vì vậy waveform này **không** chứng minh được
> các giản đồ ở §1–§4. Để thấy độ trễ thật phải mô phỏng gate-level có back-annotate SDF,
> hoặc đọc số từ báo cáo STA. Xem `07_TRACEABILITY/limitations.md` §3.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-A01-030…032.*
