# A01 · Bảng yêu cầu (Requirements)

Mọi yêu cầu dưới đây đều **suy trực tiếp từ Project Charter — A01**. Cột *Nguồn* chỉ rõ mục
nào của Charter sinh ra yêu cầu đó. Không có yêu cầu nào do người soạn tự thêm.

Ký hiệu mức: **M** = bắt buộc (must) · **S** = nên có (should) · **O** = tuỳ chọn (optional).

---

## 1. Yêu cầu chức năng

| ID | Mức | Nội dung yêu cầu | Nguồn (Charter) |
|---|---|---|---|
| REQ-A01-001 | M | Khối tính tổng 8-bit `SUM = (A + B) mod 256` của hai toán hạng 8-bit `A`, `B`. | Mục 1, 4 |
| REQ-A01-002 | M | Sinh cờ `C` = 1 khi và chỉ khi `A + B ≥ 256` (tràn **không dấu**). | Mục 1, 4 |
| REQ-A01-003 | M | Sinh cờ `Z` = 1 khi và chỉ khi `SUM == 0`. | Mục 4 |
| REQ-A01-004 | M | Sinh cờ `N` = `SUM[7]` (bit dấu khi diễn giải bù 2). | Mục 4 |
| REQ-A01-005 | M | Sinh cờ `V` = 1 khi và chỉ khi hai toán hạng **cùng dấu** (bù 2) cho kết quả **khác dấu** — tràn có dấu. | Mục 4 |
| REQ-A01-006 | M | Kiến trúc phải là **ripple-carry**: chuỗi 8 tầng full-adder nối tiếp, `carry[0] = 0`. | Tên đề, mục 9, 10 |
| REQ-A01-007 | M | Khối là mạch **tổ hợp thuần**: không clock, không reset, **0 ô nhớ (flip-flop)**. | Mục 10 — "Dấu hiệu làm đúng: 0 ô nhớ" |

## 2. Yêu cầu giao diện

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-A01-010 | M | Ánh xạ chân theo danh mục đề: `ui_in[7:0] = A`, `uio_in[7:0] = B`, `uo_out[7:0] = SUM`, `uio_out[3:0] = {V,N,Z,C}`. | Mục 4 |
| REQ-A01-011 | M | Bảng giao diện phải đầy đủ: tên tín hiệu, chiều, độ rộng, mức tích cực, giả định. | Mục 5, 6 |
| REQ-A01-012 | M | Ngân sách chân: thiết kế cần 16 bit vào + 12 bit ra = **28 bit** trên ô Tiny Tapeout chỉ có **24 chân** → **vượt ngân sách**. | Mục 4 |
| REQ-A01-013 | M | Vì A01 là mạch tổ hợp, nạp hai nhịp sẽ **thêm ô nhớ** (mâu thuẫn REQ-A01-007). **Phải hỏi giảng viên trước khi chọn cách xử lý.** | Mục 4 (nguyên văn) |

> ⚠️ **REQ-A01-013 hiện là điểm MỞ.** Xem `02_SPECIFICATION/interface.md` §5 để biết ba
> phương án và khuyến nghị. Lõi logic 16-vào/12-ra đã được **chốt**; lớp vỏ vật lý
> (wrapper) **chưa chốt** và cố ý không được bịa ra.

## 3. Yêu cầu kiểm chứng

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-A01-020 | M | Chạy đủ 5 ca kiểm thử bắt buộc: `0+0`, `255+0`, `255+1`, `127+1`, `200+100`. | Mục 8 |
| REQ-A01-021 | M | Bổ sung **ít nhất hai ca tự xây dựng**, trong đó có **ca biên**. | Mục 8 |
| REQ-A01-022 | M | Mỗi khẳng định phải đi kèm **bằng chứng** và **điều kiện tạo ra bằng chứng**. | Mục 6 |
| REQ-A01-023 | S | Thu một **artifact số có chú thích** (waveform / báo cáo tổng hợp) và nêu điều kiện tạo ra nó. | Mục 3, 5 |

## 4. Yêu cầu phân tích riêng (đặc thù của A01)

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-A01-030 | M | Xác định **đường tới hạn (critical path)** trong báo cáo STA do chính sinh viên sinh ra. | Mục 9 |
| REQ-A01-031 | M | Chỉ ra đường tới hạn đi qua **bao nhiêu tầng carry**. | Mục 9 |
| REQ-A01-032 | M | Giải thích **vì sao chuỗi carry quyết định tần số tối đa**, chứ không phải phép XOR tính tổng. | Mục 9 |
| REQ-A01-033 | M | Trả lời 3 câu hỏi kỹ thuật Charter mục 2 (xem §5 dưới) bằng **số liệu của chính mình**. | Mục 2, 9 |

## 5. Ba câu hỏi kỹ thuật của Charter (mục 2)

1. **Khối cộng cần giao diện gì để tầng trên biết kết quả đã tràn hay chưa?**
2. **Đường tín hiệu nào trong khối quyết định tần số tối đa — và bằng chứng nào chỉ ra nó?**
3. **Bốn cờ C, Z, N, V tốn thêm bao nhiêu phần diện tích so với chỉ tính tổng?**

> Sinh viên được phép thay bằng câu hỏi của mình, miễn là cụ thể và trả lời được bằng bằng
> chứng — không viết "tìm hiểu về…". *(Charter mục 2)*

Câu trả lời + bằng chứng: `05_VERIFICATION/verification_report.md` và `06_GDSII/physical_report.md`.

## 6. Yêu cầu bàn giao (Charter mục 5)

| ID | Mức | Nội dung |
|---|---|---|
| REQ-A01-040 | M | Hồ sơ phân tích đủ **tám thành phần** (xem `scope.md` §1), có **số phiên bản** và **ngày sửa**. |
| REQ-A01-041 | M | Bảng giao diện: tên tín hiệu, chiều, độ rộng, mức tích cực, giả định. |
| REQ-A01-042 | M | Một artifact số có chú thích và nêu điều kiện tạo ra nó. |
| REQ-A01-043 | M | Kết luận nêu rõ **đã chứng minh được gì** và **chưa chứng minh được gì**. |

## 7. Mốc thực hiện (Charter mục 7)

| Mốc | Tuần | Nội dung |
|---|---|---|
| M1 | T7 | Chốt đề và viết charter: ứng dụng, mục tiêu, 2–3 câu hỏi kỹ thuật |
| M2 | T8–9 | Bảng hành vi suy từ đặc tả; đọc RTL và waveform; lập danh sách ca kiểm thử |
| M3 | T11–12 | Sơ đồ khối hỗ trợ; thu artifact số, chú thích và đối chiếu bảng hành vi |
| M4 | T13–14 | Hoàn thiện bảng giao diện, RTM-lite, sơ đồ vòng đời; rà từng khẳng định |
| M5 | T15 | Nộp hồ sơ và trình bày; trả lời câu phân tích riêng bằng số của chính mình |

## 8. Rủi ro chính (Charter mục 10)

> **Chỗ hay tắc:** Nhầm "diện tích lớn" với "chậm". Bộ cộng ripple **NHỎ** nhưng **CHẬM**
> vì chuỗi carry 8 tầng.
>
> **Dấu hiệu làm đúng:** 0 ô nhớ. Đường tới hạn phải đi qua đúng 8 tầng carry — đếm được
> trên báo cáo STA.

Bằng chứng phản bác nhầm lẫn này: kết quả tổng hợp thật trong
`06_GDSII/synthesis/synth_stat.txt` — **48 cell, 0 flip-flop, 285.27 µm²** — rất nhỏ, trong
khi độ trễ bị chuỗi carry chi phối.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Nguồn chuẩn: `Project_Charter_80_De.docx`, mục A01.*
