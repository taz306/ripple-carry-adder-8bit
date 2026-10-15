# A01 · Ca biên và ca góc (Corner Cases)

Tài liệu này giải thích **vì sao** từng ca được chọn. Danh sách thực thi nằm ở
`05_VERIFICATION/test_matrix.csv`; kết quả nằm ở `05_VERIFICATION/verification_report.md`.

---

## 1. Năm ca bắt buộc theo Charter mục 8

| TC | A | B | Charter gọi tên | Vì sao là ca biên |
|---|---:|---:|---|---|
| TC-001 | 0 | 0 | `0+0` | Giá trị nhỏ nhất của cả hai toán hạng. Ca **duy nhất** trong nhóm bắt buộc làm `Z=1` mà không qua tràn. Bắt lỗi logic zero-detect bị nối sai. |
| TC-002 | 255 | 0 | `255+0` | Toán hạng lớn nhất cộng phần tử đơn vị. Kiểm `SUM` đi qua nguyên vẹn và `N=1`. Bắt lỗi carry bị kẹt ở mức 1. |
| TC-003 | 255 | 1 | `255+1` (tràn) | **Tràn không dấu sát biên.** `carry` phải lan qua **cả 8 tầng** — ca gây ra đường lan truyền dài nhất. Kiểm `C=1`, `Z=1` đồng thời. |
| TC-004 | 127 | 1 | `127+1` (đổi dấu bù 2) | **Tràn có dấu.** `C=0` nhưng `V=1`. Ca kinh điển chứng minh `C` và `V` khác nhau. |
| TC-005 | 200 | 100 | `200+100` | Tràn không dấu thông thường, không nằm sát biên — kiểm phép cộng ở giữa dải. |

## 2. Năm ca tự xây dựng (đáp ứng REQ-A01-021)

| TC | A | B | Loại | Vì sao thêm ca này |
|---|---:|---:|---|---|
| TC-006 | 128 | 128 | **Ca biên** | `0x80 + 0x80`: bù 2 là `(−128) + (−128) = −256`, ra `0`. Ca **duy nhất** làm `C=1`, `Z=1`, `V=1` cùng lúc. Nếu logic `V` viết sai, ca này lộ ngay. |
| TC-007 | 127 | 127 | **Ca biên** | Hai số dương lớn nhất: `+127 + 127 = 254` → bù 2 là `−2`. `V=1`, `C=0`, `N=1`. Đối xứng với TC-006 ở phía dương. |
| TC-008 | 1 | 255 | Hoán vị | Kiểm tính **giao hoán** so với TC-003. Bắt lỗi chuỗi carry bị nối lệch giữa nhánh `a` và `b`. |
| TC-009 | 128 | 127 | Cận biên | `(−128) + 127 = −1`: khác dấu nên **không bao giờ tràn có dấu** → `V=0`. Bắt lỗi công thức `V` bỏ sót điều kiện "cùng dấu". |
| TC-010 | 170 | 85 | Mẫu bit xen kẽ | `0xAA + 0x55 = 0xFF`: mọi tầng đều có đúng một toán hạng bằng 1 ⟹ **không tầng nào sinh carry**. Ca đối lập với TC-003: đường carry ngắn nhất. |

## 3. Phân loại theo tiêu chí kỹ thuật

### 3.1 Theo hành vi chuỗi carry — số liệu tính từ chính công thức RTL

Cột "số tầng lan" = số tầng liên tiếp mà một carry **đã sinh ra** phải **truyền tiếp** qua
(tầng có `a[i] ⊕ b[i] = 1`). Đây mới là đại lượng quyết định độ trễ, **không** phải số bit
`carry` đang ở mức 1.

| TC | A + B | Chuỗi `carry[8:0]` | Số tầng lan | Ý nghĩa |
|---|---|---|---:|---|
| TC-001 | `0 + 0` | `000000000` | **0** | Không sinh carry |
| TC-002 | `255 + 0` | `000000000` | **0** | Không sinh carry |
| TC-010 | `0xAA + 0x55` | `000000000` | **0** | Mỗi tầng có đúng một toán hạng bằng 1 → không tầng nào sinh |
| TC-009 | `128 + 127` | `000000000` | **0** | Không sinh carry |
| TC-006 | `128 + 128` | `100000000` | **1** | Sinh ngay tại bit 7 → ra thẳng `C`, không lan |
| TC-007 | `127 + 127` | `011111110` | **1** | ⚠️ Mọi bit `carry` đều bằng 1, **nhưng** mỗi tầng **tự sinh** carry của mình (`a[i]&b[i]=1`) nên **không** phải chờ tầng trước |
| TC-005 | `200 + 100` | `110000000` | **2** | Sinh muộn tại bit 6, lan 1 tầng tới bit 7 |
| TC-004 | `127 + 1` | `011111110` | **7** | Sinh tại bit 0, lan tới bit 6 |
| **TC-003** | `255 + 1` | `111111110` | **8** | **Sinh tại bit 0, lan hết tới bit 7 — ca tới hạn** |
| **TC-008** | `1 + 255` | `111111110` | **8** | Hoán vị của TC-003, cũng là ca tới hạn |

> 🔎 **Bài học từ TC-007:** nhìn chuỗi `carry` toàn số 1 rất dễ tưởng đây là ca chậm nhất.
> Thực ra không phải — carry ở mỗi tầng được **sinh tại chỗ**, không phụ thuộc tầng trước,
> nên các tầng chạy **song song**. Đây là ví dụ cho thấy "carry bằng 1" ≠ "carry phải lan".
> Cặp TC-003 / TC-007 có cùng chuỗi carry `011111110` vs `111111110` nhưng độ trễ khác hẳn.

> 👉 Khi mô phỏng gate-level hoặc đo STA, **TC-003 và TC-008 là vector kích hoạt đường tới hạn**.

### 3.2 Theo tổ hợp cờ (bao phủ không gian cờ)

| C | Z | N | V | Có ca nào? | TC |
|:-:|:-:|:-:|:-:|---|---|
| 0 | 1 | 0 | 0 | ✅ | TC-001 |
| 0 | 0 | 1 | 0 | ✅ | TC-002, TC-009, TC-010 |
| 1 | 1 | 0 | 0 | ✅ | TC-003, TC-008 |
| 0 | 0 | 1 | 1 | ✅ | TC-004, TC-007 |
| 1 | 0 | 0 | 0 | ✅ | TC-005 |
| 1 | 1 | 0 | 1 | ✅ | TC-006 |
| các tổ hợp còn lại | | ✅ | phủ bởi quét vét cạn (§4) |

### 3.3 Ca **không** áp dụng cho A01

| Loại ca | Lý do không áp dụng |
|---|---|
| Reset assert / deassert | A01 không có reset |
| Clock gating, clock domain crossing | A01 không có clock |
| Back-to-back transaction | A01 không có giao thức |
| X-propagation từ trạng thái khởi tạo | A01 không có ô nhớ |
| Ca tràn bộ đệm / FIFO full-empty | A01 không có bộ đệm |

## 4. Quét vét cạn — vì sao đây là ca mạnh nhất

Không gian đầu vào là `2^16 = 65 536` tổ hợp. Testbench so khớp DUT với golden model trên
**toàn bộ** không gian này.

Hệ quả logic:

> Nếu 65 536/65 536 tổ hợp đều khớp, thì DUT **tương đương hàm** với golden model.
> Không còn ca nào khác để tìm ở mức hành vi.

Điều này **vẫn không** chứng minh:

- kiến trúc bên trong đúng là ripple-carry (phải đọc RTL + netlist — xem `06_GDSII/synthesis/`);
- thời gian lan truyền đạt yêu cầu (phải chạy STA);
- mạch đúng sau khi place & route (phải mô phỏng gate-level có SDF).

## 5. Ca cần bổ sung khi chuyển sang gate-level / post-layout

| Ca | Khi nào cần | Trạng thái |
|---|---|---|
| Mô phỏng gate-level với netlist sau tổng hợp | Sau khi có netlist | ⬜ netlist đã có tại `06_GDSII/synthesis/a01_netlist.v` |
| Mô phỏng có back-annotate SDF | Sau P&R | ⬜ |
| Kiểm glitch trên `SUM` trong lúc carry lan | Khi phân tích công suất động | ⬜ |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-A01-020, REQ-A01-021, AC-5, AC-6.*
