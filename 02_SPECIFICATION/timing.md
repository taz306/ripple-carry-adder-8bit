# A01 · Đặc tả thời gian (Timing)

---

## 1. A01 không có clock — và đó là đúng đặc tả

A01 là mạch **tổ hợp thuần**. Không có clock, không có setup/hold, không có chu kỳ.
Đại lượng thời gian duy nhất có ý nghĩa là:

> **Độ trễ lan truyền từ đầu vào đến đầu ra ổn định** (input-to-output propagation delay).

Vì vậy, các khái niệm sau **không áp dụng** cho lõi A01:

| Khái niệm | Áp dụng? | Lý do |
|---|:-:|---|
| Chu kỳ clock | ❌ | Không có clock |
| Setup / hold time | ❌ | Không có flip-flop trong khối |
| Clock skew, CTS | ❌ | Không có cây clock |
| WNS / TNS | ⚠️ | Chỉ có nghĩa **nếu** ta áp một clock ảo làm chuẩn phân tích |
| Độ trễ đường tổ hợp | ✅ | Đây là đại lượng cần đo |

## 2. Đường dài nhất về mặt logic — chuỗi carry

Phụ thuộc dữ liệu trong RTL:

```
a[0],b[0] ──▶ carry[1] ──▶ carry[2] ──▶ … ──▶ carry[7] ──▶ carry[8] ═▶ C
                  │            │                   │
                  ▼            ▼                   ▼
               sum[1]       sum[2]              sum[7] ═▶ N
                                                   │
                                                   └──▶ Z (qua NOR 8 ngõ)
                                                   └──▶ V
```

Đường **dài nhất về mặt cấu trúc** là `a[0]/b[0] → carry[1] → … → carry[8] → C`,
đi qua **8 tầng sinh carry**.

Đường tính `SUM[i]` chỉ là **một phép XOR** sau khi `carry[i]` đã ổn định. Vì vậy:

> **XOR không phải là nút thắt. Chuỗi carry mới là nút thắt.**
> Mỗi `SUM[i]` chỉ tốn 1 tầng XOR **sau** khi `carry[i]` tới; còn `carry[i]` phải chờ
> `carry[i−1]`, tạo ra phụ thuộc **nối tiếp** 8 tầng.

Xấp xỉ bậc nhất:

```
t_tong_hop  ≈  t_carry_stage × 8  +  t_XOR
```

Tăng độ rộng từ 8 lên 16 bit thì độ trễ **tăng gần gấp đôi**, trong khi diện tích cũng chỉ
tăng gấp đôi — đây chính là đặc trưng "nhỏ nhưng chậm" mà Charter mục 10 cảnh báo.

> ⚠️ **Cảnh báo phương pháp luận:** Tôpô RTL **không phải** bằng chứng về đường tới hạn ở
> mức standard cell. Công cụ tổng hợp có thể gộp, tách, remap logic. Con số cuối cùng
> **bắt buộc** phải lấy từ báo cáo STA do chính sinh viên sinh ra (Charter mục 9).

## 3. Phương pháp phân tích bằng clock ảo (virtual clock)

Để dùng được công cụ STA trên một khối tổ hợp, ta dựng một **clock ảo** làm mốc quy chiếu:

```tcl
create_clock -name vclk -period 10.0
set_input_delay  0.0 -clock vclk [get_ports {a[*] b[*]}]
set_output_delay 0.0 -clock vclk [get_ports {sum[*] c z n v}]
```

### Ba giả định phải nêu rõ mỗi khi báo số

| # | Giả định | Giá trị dùng trong gói này |
|---|---|---|
| G-1 | Chu kỳ clock ảo | `10.0 ns` — **chỉ là mốc quy chiếu**, không phải yêu cầu chức năng của A01 |
| G-2 | Input delay / output delay | `0.0 ns` — giả định lý tưởng, không mô hình tầng ngoài |
| G-3 | Thư viện + điều kiện PVT | `sky130_fd_sc_hd__tt_025C_1v80` (typical, 25 °C, 1.80 V) |

> ❗ **Không được** diễn giải "period 10 ns" thành "A01 chạy được ở 100 MHz". Con số 10 ns
> chỉ để STA có mốc tính slack. Kết quả **có ý nghĩa** là `data arrival time` của đường
> `a/b → C`, tức độ trễ tổ hợp thật.

### Đại lượng cần trích từ báo cáo STA

| Đại lượng | Ý nghĩa với A01 |
|---|---|
| `startpoint` | Mong đợi: một trong `a[0]`, `b[0]` |
| `endpoint` | Mong đợi: `c` (hoặc `sum[7]`, `v`) |
| `data arrival time` | **Độ trễ tổ hợp thật** — con số quan trọng nhất |
| Số cell trên đường | Dùng để **đếm số tầng carry** (REQ-A01-031) |
| `slack (WNS)` | Chỉ có nghĩa kèm G-1, G-2, G-3 |

## 4. Trạng thái số liệu thời gian trong gói này

| Hạng mục | Trạng thái |
|---|---|
| Phân tích tôpô RTL (8 tầng carry) | ✅ đã lập luận, xem §2 |
| Tổng hợp thật ra standard cell sky130 | ✅ đã chạy — `06_GDSII/synthesis/synth_stat.txt` |
| **Báo cáo STA thật** | ⬜ xem `06_GDSII/sta/README.md` |
| Độ trễ sau routing (post-route) | ⬜ cần chạy P&R |

Script sẵn sàng: `04_IMPLEMENTATION/scripts/run_sta.tcl`.

## 5. Yêu cầu lấy mẫu của tầng ngoài

Vì A01 sinh glitch trong lúc carry lan truyền, tầng ngoài (thanh ghi TỔNG) phải:

```
t_clk_period_he_thong  ≥  t_ckq(thanh ghi)  +  t_A01_max  +  t_setup(thanh ghi)  +  t_skew
```

`t_A01_max` lấy từ `data arrival time` trong báo cáo STA ở §3.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-A01-030…032, AC-12…14.*
