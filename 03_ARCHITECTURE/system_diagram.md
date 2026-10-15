# A01 · Sơ đồ hệ thống (System Diagram)

---

## 1. Sơ đồ khối hệ thống — vòng đeo tay đếm bước chân

```
                     ┌──────────── MIỀN ANALOG / MIXED ────────────┐
                     │                                             │
   chuyển động ─────▶│  ┌───────────┐      ┌──────────────┐        │
   của cổ tay        │  │  Cảm biến │ V(t) │     ADC      │ 12 bit │
                     │  │  gia tốc  │─────▶│  (mixed-sig) │───────┐│
                     │  │  (analog) │      │              │       ││
                     │  └───────────┘      └──────────────┘       ││
                     └─────────────────────────────────────────┬──┘│
                                                               │   │
                     ┌──────────────── MIỀN SỐ ────────────────┼───┼──────────────┐
                     │                                         ▼   ▼              │
                     │   ┌────────────────────┐    B[7:0]  ┌──────────────┐       │
                     │   │ Bộ phát hiện bước  │───────────▶│              │       │
                     │   │ chân (lọc + ngưỡng)│  bước mới  │              │       │
                     │   └────────────────────┘            │              │       │
                     │                                     │  ►► A01 ◄◄   │       │
                     │   ┌────────────────────┐    A[7:0]  │              │       │
                     │   │   Thanh ghi TỔNG   │───────────▶│ Bộ cộng      │       │
                     │   │  (8-bit, có clock) │  tổng cũ   │ ripple-carry │       │
                     │   │  ◀── ô nhớ duy nhất│            │ 8-bit + 4 cờ │       │
                     │   └─────────▲──────────┘            │ (TỔ HỢP)     │       │
                     │             │                       └──────┬───────┘       │
                     │             │  SUM[7:0]  (tổng mới)        │               │
                     │             └──────────────────────────────┤               │
                     │                                            │ {V,N,Z,C}     │
                     │                                            ▼               │
                     │                                   ┌──────────────────┐     │
                     │                                   │ Firmware / MCU   │     │
                     │                                   │ · C=1 → +1 byte  │     │
                     │                                   │   cao (đa byte)  │     │
                     │                                   │ · Z=1 → đã reset │     │
                     │                                   └────────┬─────────┘     │
                     │                                            ▼               │
                     │                                   ┌──────────────────┐     │
                     │                                   │  Hiển thị / BLE  │     │
                     │                                   └──────────────────┘     │
                     └──────────────────────────────────────────────────────────┘
```

**Điểm cốt lõi của sơ đồ:** ô nhớ duy nhất trong vòng lặp tích luỹ là **thanh ghi TỔNG**,
và nó nằm **ngoài** khối A01. A01 chỉ là hàm tổ hợp `f(A, B) → (SUM, C, Z, N, V)`.

## 2. Ranh giới khối A01

```
                 ╔═══════════════════════════════════════════════╗
    a[7:0] ─────▶║                                               ║─────▶ sum[7:0]
                 ║        a01_ripple_adder                       ║─────▶ c
    b[7:0] ─────▶║        (tổ hợp thuần, 0 flip-flop)            ║─────▶ z
                 ║                                               ║─────▶ n
   (không clock) ║                                               ║─────▶ v
   (không reset) ╚═══════════════════════════════════════════════╝
                      16 bit vào                    12 bit ra
                              └──── 28 bit trên ô 24 chân → xem interface.md §3 ────┘
```

## 3. Phân rã một tầng xuống dưới

```
 a01_ripple_adder
 ├── GEN_FA[0] … GEN_FA[7]        ← 8 tầng full-adder (chuỗi ripple)
 │     ├── sum[i]     = a[i] ⊕ b[i] ⊕ carry[i]
 │     └── carry[i+1] = majority(a[i], b[i], carry[i])
 ├── logic cờ C       = carry[8]                      ← lấy thẳng từ chuỗi
 ├── logic cờ Z       = NOR8(sum[7:0])                ← thêm, không nằm trên chuỗi carry
 ├── logic cờ N       = sum[7]                        ← chỉ là dây nối
 └── logic cờ V       = ¬(a[7]⊕b[7]) ∧ (sum[7]⊕a[7])  ← thêm, 2 tầng cổng
```

## 4. Sơ đồ vòng đời (Lifecycle) — RTL đến GDSII

Đây là thành phần bắt buộc số 6 của hồ sơ (Charter mục 3).

```
 ┌─────────────┐   ┌─────────────┐   ┌──────────────┐   ┌────────────┐
 │ 01 YÊU CẦU  │──▶│ 02 ĐẶC TẢ   │──▶│03 KIẾN TRÚC  │──▶│04 HIỆN THỰC│
 │  Charter    │   │ hành vi +   │   │ chuỗi 8 tầng │   │  RTL .sv   │
 │             │   │ giao diện   │   │ carry        │   │            │
 └─────────────┘   └─────────────┘   └──────────────┘   └─────┬──────┘
                                                              │
        ┌─────────────────────────────────────────────────────┘
        ▼
 ┌──────────────┐        ✅ ĐÃ CHẠY: 65 536/65 536 khớp, 0 lỗi
 │05 KIỂM CHỨNG │        Icarus Verilog 12.0
 │ sim + golden │
 └──────┬───────┘
        ▼
 ┌──────────────┐        ✅ ĐÃ CHẠY: Yosys 0.33 + sky130_fd_sc_hd
 │ TỔNG HỢP     │        48 cell · 0 FF · 285.27 µm²
 │ (06/synth)   │
 └──────┬───────┘
        ▼
 ┌──────────────┐        ⬜ CHƯA CHẠY — cần OpenSTA + SDC đã duyệt
 │ STA          │        → đây là nơi trả lời câu phân tích riêng (mục 9)
 │ (06/sta)     │
 └──────┬───────┘
        ▼
 ┌──────────────┬──────────────┬──────────────┬──────────────┐
 │ FLOORPLAN    │  PLACEMENT   │ CTS (n/a)    │  ROUTING     │  ⬜ CHƯA CHẠY
 └──────────────┴──────────────┴──────┬───────┴──────────────┘
                                      ▼
                           ┌──────────────────┐
                           │  DRC · LVS · GDS │                  ⬜ CHƯA CHẠY
                           └────────┬─────────┘
                                    ▼
                           ┌──────────────────┐
                           │ 07 TRUY VẾT +    │
                           │ KẾT LUẬN/GIỚI HẠN│
                           └──────────────────┘

        ─────── NGOÀI PHẠM VI (Charter mục 3) ───────
        sign-off · tape-out · chế tạo · kiểm tra sau chế tạo
```

> **CTS ghi (n/a)** vì A01 không có clock — không có cây clock để dựng. Đây là một kết quả
> hợp lệ của tầng đó, không phải bước bị bỏ sót. Xem `06_GDSII/cts/README.md`.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Thành phần hồ sơ bắt buộc #2 và #6.*
