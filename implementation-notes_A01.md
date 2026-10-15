# A01 — Bộ cộng 8-bit nối tiếp carry (ripple-carry) có cờ trạng thái · Ghi chú thực hiện

---

## 1. Bài toán này thực chất là gì

Bề mặt: "cộng hai số 8 bit và sinh bốn cờ". Nghe như bài tập tuần đầu.

Thực chất, Charter chọn A01 làm đề mở đầu vì nó là **ví dụ sạch nhất** để dạy một điều rất
khó dạy: **diện tích và tốc độ là hai trục độc lập, và tối ưu sai trục là lãng phí**.

Charter mục 10 nói thẳng chỗ hay tắc: *"Nhầm 'diện tích lớn' với 'chậm'. Bộ cộng ripple
NHỎ nhưng CHẬM vì chuỗi carry 8 tầng."* Toàn bộ hồ sơ này tồn tại để biến câu đó từ một
lời khẳng định thành một **số đo**.

Bối cảnh ứng dụng — vòng đeo tay đếm bước chân — không phải trang trí. Nó quyết định câu
trả lời cuối cùng: với tần số lấy mẫu ~50 Hz, "chậm" của ripple-carry **không phải nhược
điểm**, và chọn carry-lookahead ở đây là tối ưu sai chỗ.

## 2. Bản chất kỹ thuật — cơ chế hoạt động

Hai phép cộng một bit trông giống nhau nhưng có bản chất thời gian khác hẳn:

```
sum[i]     = a[i] ⊕ b[i] ⊕ carry[i]              ← chờ carry[i], rồi 1 tầng XOR
carry[i+1] = (a[i]&b[i]) | (a[i]&carry[i]) | (b[i]&carry[i])   ← chờ carry[i], rồi sinh carry[i+1]
```

Cả hai đều chờ `carry[i]`. Khác biệt nằm ở **cái gì phụ thuộc vào cái gì tiếp theo**:

* Tám phép tính `sum[i]` **song song** với nhau. Không `sum` nào cần `sum` khác.
* Tám phép tính `carry[i+1]` **nối tiếp**. Mắt xích `i+1` không thể bắt đầu trước khi mắt
  xích `i` xong.

Đây là điểm mấu chốt và cũng là chỗ sinh viên hay hiểu nhầm:

> **"Nối tiếp" ở đây là phụ thuộc DỮ LIỆU, không phải phụ thuộc CHU KỲ.**
> Không có clock nào cả. `carry[i+1]` phải đợi điện áp trên dây `carry[i]` xác lập — đó là
> vật lý, không phải giao thức. Mạch vẫn là **tổ hợp thuần**: đầu ra chỉ là hàm của đầu vào
> hiện tại, không phụ thuộc lịch sử.

Hệ quả định lượng:

```
t_A01  ≈  8 × t_carry_stage  +  t_XOR
          └── áp đảo ──┘        └ không đáng kể ┘
```

Độ rộng `N` gấp đôi ⟹ độ trễ gấp đôi (`O(N)`), diện tích cũng gấp đôi (`O(N)`). Ripple là
kiến trúc **rẻ nhất về diện tích** và **đắt nhất về độ trễ** trong họ bộ cộng.

### Bốn cờ — vì sao `C` và `V` không thay thế nhau

Cùng một mẫu bit 8 bit, hai cách **diễn giải**:

| | Không dấu | Có dấu (bù 2) |
|---|---|---|
| Dải | 0 … 255 | −128 … +127 |
| Cờ báo sai | `C` | `V` |
| Quy tắc | kết quả > 255 | hai toán hạng cùng dấu ra kết quả khác dấu |

Bốn tổ hợp `(C,V)` đều xảy ra được, và cả bốn đều có trong testbench:

| A + B | C | V | Đọc thế nào |
|---|:-:|:-:|---|
| `1 + 1` | 0 | 0 | Đúng ở cả hai cách hiểu |
| `200 + 100` | **1** | 0 | Tràn unsigned; signed −56 + 100 = 44 — đúng |
| `127 + 1` | 0 | **1** | Không tràn unsigned; signed 127 + 1 = −128 — sai |
| `128 + 128` | **1** | **1** | Tràn cả hai |

## 3. Đọc mã nguồn: RTL làm gì

Toàn bộ kiến trúc nằm trong 8 dòng:

```systemverilog
logic [8:0] carry;
assign carry[0] = 1'b0;

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : GEN_FA
        assign sum[i]     = a[i] ^ b[i] ^ carry[i];
        assign carry[i+1] = (a[i] & b[i])
                          | (a[i] & carry[i])
                          | (b[i] & carry[i]);
    end
endgenerate
```

Ba điểm cần giảng kỹ:

1. **`generate for` là nhân bản KHÔNG GIAN, không phải vòng lặp thời gian.** Nó tạo ra 8
   bản sao phần cứng tồn tại đồng thời, không phải 8 lần chạy tuần tự. Sinh viên quen lập
   trình phần mềm gần như luôn hiểu nhầm chỗ này.
2. **`carry[i+1]` là hàm đa số (majority)** của ba bit `a[i]`, `b[i]`, `carry[i]`. Nhận ra
   điều này giải thích vì sao `abc` map nó thành các cell `maj3`, `a22oi`, `o21ai` — đó
   đều là các dạng hiện thực của majority.
3. **Mảng `carry` khai báo 9 bit cho 8 tầng.** `carry[0]` là carry vào (bằng 0 vì đây là bộ
   **cộng**, không phải cộng/trừ — đó là A02), `carry[8]` là carry ra, chính là cờ `C`.

Bốn cờ:

```systemverilog
assign c = carry[8];                            // 0 cổng thêm — đã có sẵn
assign z = (sum == 8'h00);                      // cây NOR 8 ngõ
assign n = sum[7];                              // 0 cổng thêm — chỉ là dây
assign v = ~(a[7] ^ b[7]) & (sum[7] ^ a[7]);    // 2 XOR + 1 INV + 1 AND
```

Netlist sau tổng hợp xác nhận `n` không tốn gì: nó chứa `assign sum[7] = n;` — hai tên gọi
của **cùng một net**.

### Điều tuyệt đối không được viết

```systemverilog
assign sum = a + b;   // ❌ CẤM trong RTL nộp bài
```

Toán tử `+` cho phép công cụ tự chọn kiến trúc — thường là carry-lookahead hoặc
carry-select. Làm vậy là **xoá mất chính thứ Charter mục 9 yêu cầu quan sát**. Toán tử `+`
chỉ được dùng trong golden model (`05_VERIFICATION/golden_model/a01_reference.sv`), nơi nó
đóng vai trò chuẩn so sánh độc lập.

## 4. Vì sao chọn kiến trúc này

Không phải vì ripple "tốt", mà vì **ứng dụng không cần nhanh**:

| Tiêu chí của vòng đeo tay | Ripple-carry đáp ứng? |
|---|---|
| Tần số lấy mẫu ~50 Hz (chu kỳ ~20 ms) | ✅ Dư sức — độ trễ đo được 1,34 ns |
| Ngân sách pin cực nhỏ | ✅ Ít cell nhất ⟹ ít rò và ít chuyển mạch nhất |
| Diện tích 1×1 tile | ✅ 285,27 µm², rất thoải mái |
| Cần tần số cao | ❌ Không cần |

Biên an toàn: `20 ms / 1,34 ns ≈ 15 triệu lần`. Chọn CLA ở đây là trả thêm diện tích và
công suất để mua tốc độ mà ứng dụng **không bao giờ dùng đến**.

So sánh đầy đủ bốn kiến trúc ở `03_ARCHITECTURE/tradeoff.md` §4 — lưu ý CLA nằm **ngoài
phạm vi** theo Charter mục 3, chỉ được so trên giấy.

## 5. Cách thực hiện — lộ trình 8 bước

| # | Bước | Công cụ | Bằng chứng sinh ra | Trạng thái |
|---|---|---|---|---|
| 1 | Suy bảng hành vi từ Charter mục 1 và mục 8 | — | `02_SPECIFICATION/functional_spec.md` | ✅ |
| 2 | Viết mô hình chuẩn Python độc lập | CPython 3 | `python_reference_run.log` | ✅ PASS |
| 3 | Viết RTL với chuỗi ripple **tường minh** | — | `04_IMPLEMENTATION/rtl/` | ✅ |
| 4 | Viết testbench tự kiểm + assertion bất biến | Icarus Verilog 12.0 | `simulation.log` | ✅ 65 546/0 lỗi |
| 5 | Tổng hợp lên sky130, **kiểm 0 flip-flop** | Yosys 0.33 | `synth_stat.txt` | ✅ 48 cell, 0 FF |
| 6 | Đo diện tích tăng thêm do 4 cờ (tổng hợp 2 bản) | Yosys 0.33 | `physical_report_flag_area.md` | ✅ +46,2 % |
| 7 | STA với clock ảo, **đếm tầng carry** | OpenSTA 3.1.0 | `sta/critical_path_analysis.md` | ✅ 1,34 ns |
| 8 | Physical design RTL→GDSII | LibreLane + sky130A | `06_GDSII/` | ⬜ chưa chạy |

Chạy lại toàn bộ: `07_TRACEABILITY/evidence_index.md` §6.

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | Công cụ |
|---|---:|---|
| Vector kiểm chứng | 65 536/65 536 khớp, 0 lỗi | Icarus Verilog 12.0 |
| Vi phạm bất biến | 0 / 65 546 | như trên |
| Số cell | **48** | Yosys 0.33 + sky130_fd_sc_hd |
| Flip-flop | **0** | như trên |
| Diện tích | **285,2736 µm²** | như trên |
| Chỉ tính `SUM` (không cờ) | 24 cell · 195,1872 µm² | như trên |
| Đường tới hạn | `b[0] → v` | OpenSTA 3.1.0 |
| **Độ trễ tổ hợp** | **1,34 ns** | như trên |
| Đường nhanh nhất `b[0] → sum[0]` | **0,03 ns** | như trên |
| Công suất | 12,1 µW — 100 % tổ hợp, 0 % tuần tự | như trên |

### Từng con số chứng minh gì — và KHÔNG chứng minh gì

| Con số | **Chứng minh** | **KHÔNG chứng minh** |
|---|---|---|
| 65 536/65 536 khớp | Hàm của DUT **tương đương** golden model. Không còn ca hành vi nào chưa kiểm. | Kiến trúc là ripple-carry. Một bộ CLA cũng PASS hết. |
| 0 flip-flop | Đúng phân loại Tổ hợp của Charter, xác nhận bởi **hai nguồn độc lập** (bảng cell + công suất nhóm Sequential = 0 %) | Netlist tương đương RTL về chức năng — cần mô phỏng gate-level |
| 48 cell · 285,27 µm² | Ripple-carry **nhỏ** — nhỏ hơn cả ước lượng 120–180 cell của Charter | Diện tích sau P&R — sẽ khác vì có dây và cell `lpflow_*` bị `dont_use` |
| 1,34 ns | Độ trễ **ở mức sau tổng hợp**, góc `tt_025C_1v80` | Độ trễ thật sau routing (sẽ **lớn hơn**, chưa có RC dây) |
| 12,1 µW | Thứ tự độ lớn công suất | Công suất thật của ứng dụng — dùng activity mặc định, không lấy từ VCD |

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

### Câu 1 — Khối cộng cần giao diện gì để tầng trên biết kết quả đã tràn hay chưa?

**Cần hai cờ khác nhau, không phải một.** `C` trả lời "có vượt 255 khi coi là số không
dấu?"; `V` trả lời "có sai dấu khi coi là bù 2?". Bằng chứng: bốn tổ hợp `(C,V)` đều xảy ra
trong dữ liệu đã chạy (bảng ở §2), nên hai cờ **độc lập**. Với ứng dụng đếm bước chân (số
không dấu), `C` là cờ firmware thực sự dùng; `V` có mặt để khối dùng lại được trong ngữ
cảnh bù 2.

### Câu 2 — Đường tín hiệu nào quyết định tần số tối đa, bằng chứng nào chỉ ra nó?

**Chuỗi carry.** Bằng chứng đo được trên **cùng một netlist**:

| Đường | Nội dung | Độ trễ |
|---|---|---:|
| `b[0] → sum[0]` | 1 XOR, `carry[0]` là hằng số nên không phải chờ | **0,03 ns** |
| `b[0] → v` | qua 7 tầng carry rồi vào logic cờ | **1,34 ns** |

Chênh **≈ 45×** với cùng điểm xuất phát, cùng thư viện. Khác biệt duy nhất: đường thứ hai
phải chờ carry lan qua các tầng. Nếu XOR là nút thắt thì `sum[0]` — thuần XOR — đã phải
chậm; thực tế nó là đường **nhanh nhất** của toàn thiết kế.

### Câu 3 — Bốn cờ tốn thêm bao nhiêu phần diện tích?

**+46,2 % diện tích (+24 cell, +90,09 µm²)**, đo bằng cách tổng hợp hai phiên bản cùng
kiến trúc, cùng thư viện, cùng script:

| Phiên bản | Cell | Diện tích |
|---|---:|---:|
| Chỉ `SUM` | 24 | 195,1872 µm² |
| `SUM` + 4 cờ | 48 | 285,2736 µm² |

Phân bổ: `C` và `N` tốn **0 cổng**; toàn bộ 24 cell tăng thêm thuộc về `Z` (cây NOR) và `V`.

**Thêm một chi phí ít ai nghĩ tới:** bốn cờ còn làm đường tới hạn dài thêm **+11,7 %**
(1,34 ns tới `v` so với 1,20 ns tới `c`).

## 8. Trả lời câu phân tích riêng (Charter mục 9)

> *"Xác định đường tới hạn trong báo cáo STA. Chỉ ra nó đi qua bao nhiêu tầng carry, và
> giải thích vì sao chuỗi carry quyết định tần số tối đa chứ không phải phép XOR tính tổng."*

**Đường tới hạn:** `b[0]` → `v`, **1,34 ns**, 8 cell.
**Đường tới `c`:** 8 cell, **toàn bộ thuộc chuỗi carry** — đúng bằng số tầng dự đoán từ RTL.

Chi tiết từng cell và lập luận đầy đủ: `06_GDSII/sta/critical_path_analysis.md`.

### Ba kết quả đáng nói

**① Endpoint tới hạn là `v`, không phải `c`.** Trái trực giác "carry-out chậm nhất". Cả hai
đường cùng đến mốc 1,17 ns tại cell `_82_`; khác biệt ở cell cuối: `and3b_1` (tính `V`,
0,17 ns) chậm hơn `a21oi_1` (tính `C`, 0,03 ns). Kết quả này **xác nhận dự đoán** đã ghi
**trước khi chạy STA** trong `03_ARCHITECTURE/datapath.md` §3.

**② "8 cell trên đường" KHÔNG đồng nghĩa "8 tầng carry" một cách hiển nhiên.** Số 8 trùng
dự đoán, nhưng đọc kết nối netlist thì cell đầu `_43_` (`a22oi_1`) nhận **cả** `a[0]`,
`b[0]`, `a[1]`, `b[1]` — nó gộp số hạng sinh carry của **hai** bit. `abc` cũng đổi cực tính
xen kẽ AOI/OAI để bớt inverter. Kết luận về số tầng phải đến từ **đọc netlist**, không từ
**đếm cell**.

**③ Công suất xác nhận lại "0 ô nhớ" một cách độc lập.** `report_power` cho 100 % công
suất thuộc nhóm Combinational, 0 % Sequential, 0 % Clock. Đây là bằng chứng thứ hai, khác
nguồn với bảng cell của Yosys.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|---|
| 1 | Viết `assign sum = a + b;` cho gọn | Mất kiến trúc ripple; không đếm được tầng carry | Đọc RTL; và STA sẽ cho đường ngắn bất thường, số cell `maj3`/`a22oi` không thành chuỗi |
| 2 | Đặt thanh ghi tích luỹ **vào trong** A01 | Đổi loại mạch sang Tuần tự, vi phạm Charter mục 10 | `synth_stat.txt` có cell `__dfxtp`; `report_power` có nhóm Sequential ≠ 0 % |
| 3 | Nhầm "diện tích lớn" với "chậm" | Kết luận ngược hoàn toàn | So 48 cell (nhỏ) với 1,34 ns so 0,03 ns (chậm gấp 45×) |
| 4 | Tưởng `C` và `V` là một | Firmware xử lý tràn sai | TC-003 (`C=1,V=0`) và TC-004 (`C=0,V=1`) — cặp phản chứng |
| 5 | Nghĩ chuỗi carry "toàn số 1" là ca chậm nhất | Chọn sai vector đo timing | TC-007 (`127+127`) có `carry=011111110` nhưng chỉ **1** tầng lan, vì mỗi tầng **tự sinh** carry |
| 6 | Diễn giải "period 10 ns" thành "chạy ở 100 MHz" | Khẳng định vượt mức | `02_SPECIFICATION/timing.md` §3 — `vclk` là mốc quy chiếu, A01 không có clock |
| 7 | Dùng waveform để chứng minh độ trễ | Waveform hành vi là zero-delay | Mở VCD: mọi tín hiệu đổi tức thời tại `#1` |
| 8 | Kết luận "mô phỏng PASS ⟹ kiến trúc đúng" | Kiểm chứng chức năng mù về cấu trúc | Một bộ CLA cũng PASS 65 536/65 536 |
| 9 | Tự chọn phương án xử lý ngân sách chân | Charter mục 4 bắt **hỏi giảng viên trước** | `02_SPECIFICATION/interface.md` §5 — còn để 🟡 MỞ |
| 10 | So số cell/diện tích của A01 với đề khác | Hai đề có thể chạy môi trường khác | `02_SPECIFICATION/parameters.md` §2 — điều kiện tạo bằng chứng |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| 1 | Vì sao khối này có đúng 0 flip-flop? | Vì là mạch tổ hợp: đầu ra chỉ là hàm của đầu vào hiện tại. Thanh ghi TỔNG nằm **ngoài** A01. |
| 2 | Không có clock, vậy sao carry lại "đi tuần tự" qua 8 tầng? | "Tuần tự" ở đây là phụ thuộc **dữ liệu**, không phải phụ thuộc **chu kỳ**. `carry[i+1]` chờ điện áp trên `carry[i]` xác lập, không chờ cạnh clock. |
| 3 | Vì sao `sum[i]` không ổn định trước `carry[i]`? | Vì `sum[i] = a[i] ⊕ b[i] ⊕ carry[i]` — `carry[i]` là một trong ba toán hạng. |
| 4 | `C` khác `V` ở chỗ nào? Cho ví dụ `C=1, V=0`. | `C` = tràn không dấu, `V` = tràn có dấu. Ví dụ: `255 + 1` → `C=1, V=0`. |
| 5 | Chuỗi `carry` của `127+127` toàn số 1 — đây có phải ca chậm nhất không? | **Không.** Mỗi tầng tự sinh carry (`a[i]&b[i]=1`) nên không phải chờ tầng trước. Ca chậm nhất là `255+1`, lan đủ 8 tầng. |
| 6 | Bạn đếm 8 cell trên đường tới `c` — có chắc đó là 8 tầng carry không? | Phải đọc kết nối netlist. `_43_` gộp bit 0 và bit 1 vào một cell, nên ánh xạ không 1:1. |
| 7 | Vì sao đường tới hạn kết thúc ở `v` chứ không ở `c`? | Cả hai cùng xuất phát từ `_82_` tại 1,17 ns; cell cuối tính `V` (`and3b_1`, 0,17 ns) chậm hơn cell cuối tính `C` (`a21oi_1`, 0,03 ns). |
| 8 | 65 536/65 536 PASS — điều này chứng minh mạch là ripple-carry chưa? | Chưa. Kiểm chứng chức năng mù về cấu trúc. Bằng chứng kiến trúc phải đọc từ RTL và netlist. |
| 9 | Con số 1,34 ns có phải độ trễ thật của chip không? | Không. Đây là độ trễ **sau tổng hợp**, chưa có RC dây, chỉ một góc PVT. Sau routing sẽ lớn hơn. |
| 10 | Ripple nhỏ nhưng chậm — vậy có nên đổi sang CLA không? | Không, vì hai lý do: CLA nằm ngoài phạm vi (Charter mục 3), và ứng dụng chỉ cần ~50 Hz trong khi khối chạy được ở mức ns — tối ưu sai chỗ. |
| 11 | Bốn cờ tốn bao nhiêu? | +46,2 % diện tích (+24 cell) và +11,7 % độ trễ. `C`, `N` tốn 0 cổng; toàn bộ là `Z` và `V`. |
| 12 | Vấn đề ngân sách chân đã giải quyết chưa? | Chưa — 28 bit trên 24 chân, Charter mục 4 bắt hỏi giảng viên trước. Ba phương án đã phân tích, chưa chọn. |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

### Đã chứng minh

1. Hàm của A01 đúng trên **toàn bộ** không gian đầu vào (65 536/65 536, 0 lỗi).
2. Năm bất biến của đặc tả luôn giữ (0 vi phạm / 65 546 vector).
3. Ba hiện thực độc lập (Python, SV reference, RTL) đồng ý với nhau.
4. **0 ô nhớ** — xác nhận bởi hai bằng chứng độc lập (bảng cell + báo cáo công suất).
5. Ripple-carry **nhỏ**: 48 cell, thấp hơn cả ước lượng 120–180 của Charter.
6. Ripple-carry **chậm**: 1,34 ns so với 0,03 ns trên cùng netlist — chênh 45×.
7. Bốn cờ tốn +46,2 % diện tích và +11,7 % độ trễ.

### Chưa chứng minh

1. Netlist tương đương RTL về chức năng — cần mô phỏng gate-level.
2. Độ trễ **thật sau routing** — 1,34 ns chưa tính ký sinh dây.
3. Biên an toàn qua các góc PVT — mới chạy `tt_025C_1v80`.
4. Công suất thật của ứng dụng — 12,1 µW dùng activity mặc định.
5. Layout tuân thủ quy tắc chế tạo (DRC), khớp netlist (LVS), và có file GDSII.
6. Lớp vỏ vật lý 24 chân — 🟡 **chờ quyết định của giảng viên**.

### Ngoài phạm vi — không được khẳng định

"Đã sign-off", "đã tape-out", "đã chế tạo", "đã kiểm tra sau chế tạo", "chạy được ở XXX MHz".
Charter mục 3 loại tất cả khỏi phạm vi đề tài.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
