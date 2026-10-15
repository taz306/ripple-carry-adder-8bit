# A01 · Tầng 04 — Hiện thực (Implementation)

---

## 1. Nội dung thư mục

```
04_IMPLEMENTATION/
├── rtl/
│   └── a01_ripple_adder.sv          ← RTL nộp bài (lõi tổ hợp, 8 tầng carry tường minh)
├── constraints/
│   └── a01_virtual_clock.sdc        ← SDC clock ảo cho phân tích STA
├── scripts/
│   ├── 01_run_sim.sh                ← mô phỏng chức năng (Icarus Verilog)
│   ├── 02_run_synth.sh              ← tổng hợp (Yosys → sky130_fd_sc_hd)
│   ├── 03_run_sta.tcl               ← STA (OpenSTA)
│   ├── 04_run_librelane.sh          ← RTL→GDSII (LibreLane) — mở rộng tự nguyện
│   ├── compare_flags_area.sh        ← đo diện tích tăng thêm do 4 cờ
│   ├── config_librelane.json        ← cấu hình flow vật lý
│   └── config.json                  ← siêu dữ liệu đề (máy đọc được)
└── README.md                        ← file này
```

## 2. Thứ tự chạy

```bash
# từ thư mục gốc của dự án
bash 04_IMPLEMENTATION/scripts/01_run_sim.sh            # ✅ đã chạy — PASS
bash 04_IMPLEMENTATION/scripts/02_run_synth.sh          # ✅ đã chạy — 48 cell, 0 FF
bash 04_IMPLEMENTATION/scripts/compare_flags_area.sh    # ✅ đã chạy — +46.2% diện tích
sta -no_splash -exit 04_IMPLEMENTATION/scripts/03_run_sta.tcl   # ⬜ cần OpenSTA
bash 04_IMPLEMENTATION/scripts/04_run_librelane.sh      # ⬜ mở rộng tự nguyện
```

Mỗi script đều **tự kiểm tra công cụ** và dừng có thông báo rõ ràng nếu thiếu, thay vì tạo
ra kết quả giả.

## 3. Quy tắc viết RTL cho đề này

| Quy tắc | Vì sao |
|---|---|
| ❌ **Không** dùng `assign sum = a + b;` | Mất kiến trúc ripple tường minh; Charter mục 9 yêu cầu đếm tầng carry |
| ❌ **Không** có `always_ff`, `posedge`, `<=` | A01 là tổ hợp thuần; phải giữ 0 flip-flop |
| ❌ **Không** thêm cổng `clk`/`rst` | Giao diện đã chốt ở `02_SPECIFICATION/interface.md` §2 |
| ✅ Dùng `generate for` 8 vòng | Nhân bản không gian, thể hiện đúng 8 tầng phần cứng |
| ✅ Mọi tín hiệu nội bộ dùng `logic` | Chuẩn SystemVerilog-2012 (`-g2012`) |

Script `02_run_synth.sh` **tự động kiểm** quy tắc "0 flip-flop" và trả mã lỗi nếu phát hiện
cell tuần tự trong netlist.

## 4. Môi trường đã dùng để sinh bằng chứng

| Công cụ | Phiên bản |
|---|---|
| Icarus Verilog | 12.0 (stable) |
| Yosys | 0.33 (git sha1 `2584903a060`) |
| Liberty | `sky130_fd_sc_hd__tt_025C_1v80.lib` (OpenROAD-flow-scripts) |
| OpenSTA | ⬜ chưa chạy |
| LibreLane + sky130A | ⬜ chưa chạy |

Chi tiết và cảnh báo về tính so sánh được của số liệu: `02_SPECIFICATION/parameters.md` §2.

## 5. Cài đặt công cụ trên WSL Ubuntu

```bash
# mô phỏng + tổng hợp
sudo apt update
sudo apt install -y iverilog yosys gtkwave

# STA (OpenSTA) — cần CUDD
sudo apt install -y cmake swig tcl-dev flex bison libeigen3-dev zlib1g-dev libgtest-dev
# build CUDD 3.0.0 trước, rồi:
#   cmake .. -DCUDD_DIR=/usr/local && make -j$(nproc)

# PDK + flow vật lý
pip install librelane volare
volare enable --pdk sky130 <commit>
export PDK_ROOT=$HOME/.volare
```

Thay vì cài lẻ, có thể dùng **OSS CAD Suite** (một gói có sẵn iverilog, yosys, OpenSTA,
OpenROAD, KLayout, Magic, Netgen):

```bash
source <oss-cad-suite>/environment
```

## 6. Phần chưa hiện thực — và lý do

| Hạng mục | Trạng thái | Lý do |
|---|---|---|
| Wrapper 24 chân Tiny Tapeout | ❌ chưa làm | Ngân sách chân vượt 28/24; Charter yêu cầu **hỏi giảng viên trước**. Xem `02_SPECIFICATION/interface.md` §5. |
| Mô phỏng gate-level | ⬜ chưa chạy | Netlist đã có tại `06_GDSII/synthesis/a01_netlist.v`; cần thêm thư viện mô phỏng sky130 |
| Back-annotate SDF | ⬜ chưa chạy | Cần hoàn thành P&R trước |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24.*
