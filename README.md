# A01 — Bộ cộng 8-bit nối tiếp carry (ripple-carry) có cờ trạng thái

| | |
|---|---|
| **Mã đề** | A01 |
| **Nhóm** | A · Số học tổ hợp |
| **Độ khó** | Trung bình (nhẹ) |
| **Loại mạch** | Tổ hợp |
| **Chân (Charter)** | Vượt — 28 bit trên 24 chân |
| **Template kiến trúc** | COMB_ARITH |
| **Phiên bản hồ sơ** | v1.0 · 2026-09-24 |

---

## 1. Tóm tắt kết quả

| Tầng | Trạng thái | Kết quả chính |
|---|---|---|
| 01 Yêu cầu | ✅ | 24 yêu cầu truy vết từ Charter |
| 02 Đặc tả | ✅ | Lõi logic **đã chốt**; wrapper 24 chân 🟡 **chưa chốt** |
| 03 Kiến trúc | ✅ | Chuỗi 8 tầng ripple, không FSM, không điều khiển |
| 04 Hiện thực | ✅ | RTL + SDC + 5 script chạy được |
| 05 Kiểm chứng | ✅ | **65 536/65 536 vector khớp, 0 lỗi, 0 vi phạm assertion** |
| 06 GDSII | 🟡 một phần | Synthesis ✅ · STA ✅ · Power ✅ · P&R⬜ · DRC/LVS/GDS ⬜ |
| 07 Truy vết | ✅ | RTM 24 dòng, 16 file bằng chứng do tool sinh |

### Số liệu đo được (không phải ước lượng)

| Chỉ số | Giá trị | Công cụ |
|---|---:|---|
| Vector kiểm chứng | 65 536 / 65 536 khớp | Icarus Verilog 12.0 |
| Số cell | **48** | Yosys 0.33 · sky130_fd_sc_hd |
| **Flip-flop** | **0** ✅ | như trên |
| Diện tích | **285,2736 µm²** | như trên |
| Đường tới hạn | `b[0] → v` | OpenSTA 3.1.0 |
| **Độ trễ tổ hợp** | **1,34 ns** | như trên |
| Đường nhanh nhất | `b[0] → sum[0]` = **0,03 ns** | như trên |
| Công suất ước lượng | 12,1 µW (100 % tổ hợp) | như trên |
| Chi phí 4 cờ | **+46,2 % diện tích · +11,7 % độ trễ** | Yosys + OpenSTA |

## 2. Ba kết quả đáng chú ý nhất

**① Chuỗi carry chậm hơn XOR gấp ~45 lần.** Trên cùng một netlist, đường `b[0] → sum[0]`
(thuần XOR, không chờ carry) mất **0,03 ns**, còn đường `b[0] → v` (qua 7 tầng carry) mất
**1,34 ns**. Đây là bằng chứng định lượng trả lời Charter mục 9.

**② Đường tới hạn kết thúc ở `v`, không phải ở `c`.** Trái với trực giác "carry-out là chậm
nhất": cả hai đường cùng đến mốc 1,17 ns, nhưng cell tính `V` (`and3b_1`, 0,17 ns) chậm hơn
cell tính `C` (`a21oi_1`, 0,03 ns). Bốn cờ không chỉ tốn diện tích mà còn **kéo dài đường
tới hạn**.

**③ "8 cell trên đường" không đồng nghĩa "8 tầng carry".** Số cell đúng bằng 8, khớp dự
đoán từ RTL — nhưng `abc` đã gộp bit 0 và bit 1 vào một cell `a22oi_1`. Kết luận về số tầng
phải đến từ việc **đọc kết nối netlist**, không từ việc đếm cell.

## 3. Cây thư mục

```
A01_Bo_cong_8bit_ripple_carry_co_co_trang_thai/
│
├── 01_REQUIREMENT/          Yêu cầu suy từ Project Charter
│   ├── application.md           bối cảnh ứng dụng + sơ đồ hệ thống + phân loại
│   ├── requirements.md          24 yêu cầu REQ-A01-xxx
│   ├── scope.md                 trong/ngoài phạm vi
│   └── acceptance_criteria.md   15 tiêu chí AC-xx + trạng thái
│
├── 02_SPECIFICATION/        Đặc tả hành vi và giao diện
│   ├── functional_spec.md       phương trình, bảng hành vi, bất biến
│   ├── interface.md             bảng giao diện + BÀI TOÁN NGÂN SÁCH CHÂN
│   ├── timing.md                phương pháp clock ảo
│   ├── corner_cases.md          10 ca + số tầng carry lan thật của từng ca
│   └── parameters.md            tham số + môi trường công cụ
│
├── 03_ARCHITECTURE/         Kiến trúc
│   ├── system_diagram.md        sơ đồ hệ thống + sơ đồ vòng đời
│   ├── block_diagram.md         chuỗi 8 full-adder
│   ├── datapath.md              đồ thị phụ thuộc, độ sâu logic
│   ├── control.md               KHÔNG có điều khiển — có lý giải
│   ├── fsm.md                   KHÔNG có FSM — có lý giải
│   ├── timing_diagram.md        giản đồ lan truyền carry
│   └── tradeoff.md              ripple vs CLA vs carry-select
│
├── 04_IMPLEMENTATION/       Hiện thực
│   ├── rtl/a01_ripple_adder.sv
│   ├── constraints/a01_virtual_clock.sdc
│   ├── scripts/                 01_run_sim · 02_run_synth · 03_run_sta
│   │                            04_run_librelane · compare_flags_area · config
│   └── README.md
│
├── 05_VERIFICATION/         Kiểm chứng ✅ PASS
│   ├── golden_model/            a01_reference.sv · reference_model.py
│   ├── testbench/a01_tb.sv
│   ├── assertions/a01_sva.sv
│   ├── waveforms/a01_waves.vcd
│   ├── testplan.md · test_matrix.csv
│   ├── simulation.log · tc_results.csv · python_reference_run.log
│   └── verification_report.md
│
├── 06_GDSII/                Vật lý — một phần ✅
│   ├── synthesis/ ✅            synth_stat.txt · a01_netlist.v · yosys.log
│   ├── sta/       ✅            critical_path_analysis.md ← TRẢ LỜI MỤC 9
│   ├── power/     ✅            power_report.txt
│   ├── floorplan/ placement/ routing/ drc/ lvs/ gds/  ⬜ README hướng dẫn chạy
│   ├── cts/       ⬛            KHÔNG ÁP DỤNG (mạch không có clock)
│   ├── physical_report.md
│   └── physical_report_flag_area.md
│
└── 07_TRACEABILITY/         Truy vết
    ├── RTM.csv                  24 dòng: yêu cầu → phần cứng → bằng chứng → giới hạn
    ├── evidence_index.md        16 file bằng chứng + lệnh tái lập
    └── limitations.md           ĐÃ / CHƯA chứng minh được gì
```

## 4. Đọc theo thứ tự nào

| Bạn là | Đọc theo thứ tự |
|---|---|
| **Giảng viên chấm bài** | `07_TRACEABILITY/limitations.md` → `RTM.csv` → `06_GDSII/sta/critical_path_analysis.md` |
| **Sinh viên nhận đề** | `01_REQUIREMENT/application.md` → `02_SPECIFICATION/` → `03_ARCHITECTURE/` → `04_IMPLEMENTATION/README.md` |
| **Người muốn chạy lại** | `07_TRACEABILITY/evidence_index.md` §6 |
| **Người cần quyết định** | `02_SPECIFICATION/interface.md` §5 (bài toán ngân sách chân) |

## 5. Chạy lại toàn bộ

```bash
python3 05_VERIFICATION/golden_model/reference_model.py
bash    04_IMPLEMENTATION/scripts/01_run_sim.sh
bash    04_IMPLEMENTATION/scripts/02_run_synth.sh
bash    04_IMPLEMENTATION/scripts/compare_flags_area.sh
sta -no_splash -exit 04_IMPLEMENTATION/scripts/03_run_sta.tcl
bash    04_IMPLEMENTATION/scripts/04_run_librelane.sh     # cần PDK sky130A
```

Yêu cầu công cụ và cách cài: `04_IMPLEMENTATION/README.md` §5.

## 6. 🟡 Việc cần giảng viên quyết định

**Ngân sách chân: thiết kế cần 28 bit, ô Tiny Tapeout chỉ có 24 chân.**

Charter mục 4 yêu cầu **hỏi giảng viên trước khi chọn cách xử lý**. Gói này trình bày ba
phương án kèm phân tích đánh đổi tại `02_SPECIFICATION/interface.md` §5, và **cố ý không**
tự chọn thay. Cho đến khi chốt, lớp vỏ vật lý chưa được hiện thực và flow P&R chỉ chạy được
cho **lõi logic**.

---

*Nguồn chuẩn: `Project_Charter_80_De.docx` — mục A01.*
*Hồ sơ này không đưa ra bất kỳ khẳng định nào về sign-off, tape-out, chế tạo hay kiểm tra
sau chế tạo — những mục nằm ngoài phạm vi đề tài theo Charter mục 3.*
