# A01 · Tham số và cấu hình (Parameters)

---

## 1. Tham số thiết kế

| Tham số | Giá trị chốt | Có được đổi không | Ghi chú |
|---|---:|---|---|
| `WIDTH` (độ rộng toán hạng) | **8** | ❌ Không | Charter mục 4 chốt 8-bit. Số có dấu > 8 bit nằm **ngoài phạm vi** (Charter mục 3). |
| Số tầng full-adder | **8** | ❌ Không | Bằng `WIDTH`. Đây là đại lượng phải đếm được trên báo cáo STA (mục 9). |
| `carry_in` ban đầu | **`1'b0`** | ❌ Không | Đề là bộ **cộng**, không phải cộng/trừ (đó là A02). |
| Số cờ trạng thái | **4** (`C`,`Z`,`N`,`V`) | ❌ Không | Charter mục 4. |
| Thứ tự cờ trên `uio_out[3:0]` | `{V,N,Z,C}` | ❌ Không | Charter mục 4: `uio_out[0]=C`. |

> RTL nộp bài dùng **hằng số 8 viết thẳng**, không tham số hoá. Lý do: Charter chốt cứng
> 8-bit, và việc tham số hoá tạo cám dỗ đổi độ rộng — dễ vô tình bước ra ngoài phạm vi.
> Nếu muốn khảo sát ảnh hưởng của độ rộng lên độ trễ, hãy làm trong một bản sao **thực
> nghiệm** riêng và ghi rõ đó là mở rộng tự nguyện.

## 2. Tham số môi trường công cụ (đã dùng để sinh bằng chứng)

| Hạng mục | Giá trị | Nơi dùng |
|---|---|---|
| Mô phỏng | **Icarus Verilog 12.0 (stable)** | `05_VERIFICATION/` |
| Chuẩn ngôn ngữ | `-g2012` (SystemVerilog-2012) | biên dịch |
| Tổng hợp | **Yosys 0.33** (git sha1 `2584903a060`) | `06_GDSII/synthesis/` |
| Thư viện standard cell | `sky130_fd_sc_hd` | mapping |
| File Liberty | `sky130_fd_sc_hd__tt_025C_1v80.lib` | `abc -liberty`, `stat -liberty` |
| Góc PVT | **tt** (typical), **25 °C**, **1.80 V** | — |
| Nguồn Liberty | OpenROAD-flow-scripts · `flow/platforms/sky130hd/lib/` | — |
| PDK đích cho P&R | **sky130A** | `06_GDSII/` (chưa chạy) |
| Flow P&R đích | **LibreLane / OpenROAD** | `04_IMPLEMENTATION/scripts/run_librelane.sh` |

> ⚠️ Mọi con số diện tích/cell trong gói này gắn chặt với **đúng** tổ hợp
> (Yosys 0.33 + sky130_fd_sc_hd + tt_025C_1v80). Đổi bất kỳ thành phần nào thì con số đổi
> theo. Charter mục 6 yêu cầu nêu **điều kiện tạo ra bằng chứng** — bảng này chính là điều kiện đó.

## 3. Tham số phân tích STA (giả định, không phải yêu cầu chức năng)

| Tham số | Giá trị | Bản chất |
|---|---:|---|
| Chu kỳ clock ảo `vclk` | `10.0 ns` | **Giả định phân tích.** A01 không có clock. |
| `set_input_delay` | `0.0 ns` | Giả định lý tưởng |
| `set_output_delay` | `0.0 ns` | Giả định lý tưởng |
| Tải đầu ra | mặc định thư viện | Chưa mô hình tải thật của tầng ngoài |

Xem `02_SPECIFICATION/timing.md` §3 để biết vì sao các số này **không** được diễn giải
thành tần số hoạt động của A01.

## 4. File cấu hình máy đọc được

`04_IMPLEMENTATION/scripts/config.json`:

```json
{
  "project_id":     "A01",
  "title":          "Bộ cộng 8-bit nối tiếp carry (ripple-carry) có cờ trạng thái",
  "group":          "A · Số học tổ hợp",
  "circuit_type":   "combinational",
  "top_module":     "a01_ripple_adder",
  "width":          8,
  "carry_stages":   8,
  "flags":          ["C", "Z", "N", "V"],
  "flag_bus_order": "{V,N,Z,C}",
  "has_clock":      false,
  "has_reset":      false,
  "expected_ff":    0,
  "technology":     "sky130A",
  "std_cell_lib":   "sky130_fd_sc_hd",
  "liberty_corner": "tt_025C_1v80",
  "flow":           "LibreLane/OpenROAD",
  "pin_budget":     { "in": 16, "out": 12, "total": 28, "available": 24, "status": "OVER_BUDGET" },
  "open_issues":    ["AC-15: pin budget resolution requires instructor decision"]
}
```

## 5. Hằng số kiểm chứng

| Hằng số | Giá trị | Dùng ở đâu |
|---|---:|---|
| Số tổ hợp đầu vào | `65 536` | quét vét cạn |
| Số ca có tên | `10` (5 bắt buộc + 5 tự xây) | `test_matrix.csv` |
| Số flip-flop mong đợi sau tổng hợp | `0` | AC-9 |
| Số cell đo được | `48` | `06_GDSII/synthesis/synth_stat.txt` |
| Diện tích đo được | `285.2736 µm²` | như trên |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24.*
