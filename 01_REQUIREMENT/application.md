# A01 · Bối cảnh ứng dụng

| | |
|---|---|
| Mã đề | **A01** |
| Tên đề | Bộ cộng 8-bit nối tiếp carry (ripple-carry) có cờ trạng thái |
| Nhóm đề | A · Số học tổ hợp |
| Độ khó | Trung bình (nhẹ) |
| Loại mạch | **Tổ hợp** |
| Quy mô ước lượng (Charter) | ~120–180 cell · 1×1 tile |
| Nguồn gốc | Project Charter — A01, mục 1 |

---

## 1. Vấn đề thực tế

Vòng đeo tay theo dõi vận động phải **cộng dồn số bước chân**. Mỗi chu kỳ đo, cảm biến gia
tốc sinh ra một số bước mới; hệ thống phải cộng số đó vào tổng đang giữ và báo cho tầng
trên biết kết quả có bị tràn hay không.

Trích nguyên văn Charter mục 1:

> Bối cảnh ứng dụng: Khối cộng dồn số bước chân trong vòng đeo tay theo dõi vận động: mỗi
> chu kỳ cộng số bước mới đo được vào tổng đang giữ, bốn cờ dùng để báo tràn cho tầng trên.

## 2. Vị trí khối A01 trong hệ thống

```
        ┌─────────────────────────────────────────────────────────────────┐
        │                  VÒNG ĐEO TAY ĐẾM BƯỚC CHÂN                     │
        │                                                                 │
        │  ┌──────────┐   ┌──────────┐   ┌──────────────┐   ┌──────────┐  │
 gia    │  │ Cảm biến │   │   ADC    │   │  Bộ phát hiện│   │  Thanh   │  │
 tốc ───┼─▶│ gia tốc  │──▶│ (analog/ │──▶│   bước chân  │──▶│   ghi    │  │
        │  │  (analog)│   │  mixed)  │   │    (số)      │   │  TỔNG    │  │
        │  └──────────┘   └──────────┘   └──────────────┘   └────┬─────┘  │
        │                                        │ B[7:0]        │A[7:0]  │
        │                                        │ (bước mới)    │(tổng)  │
        │                                        ▼               ▼        │
        │                              ╔═══════════════════════════════╗  │
        │                              ║   ►►► KHỐI A01 (đề này) ◄◄◄   ║  │
        │                              ║  Bộ cộng ripple-carry 8-bit   ║  │
        │                              ║        + 4 cờ C,Z,N,V         ║  │
        │                              ╚═══════╤═══════════════╤═══════╝  │
        │                                      │ SUM[7:0]      │{V,N,Z,C} │
        │                                      ▼               ▼          │
        │                           ┌──────────────────┐  ┌─────────────┐ │
        │                           │ ghi ngược về     │  │ Tầng firmware│ │
        │                           │ thanh ghi TỔNG   │  │ xử lý tràn   │ │
        │                           └──────────────────┘  └─────────────┘ │
        │                                                                 │
        │  ┌──────────┐   ┌──────────┐                                    │
        │  │  Màn hình│   │   Pin /  │                                    │
        │  │   LCD    │   │  nguồn   │  (analog)                          │
        │  └──────────┘   └──────────┘                                    │
        └─────────────────────────────────────────────────────────────────┘
```

## 3. Phân loại analog / digital / mixed

| Khối | Phân loại | Lý do |
|---|---|---|
| Cảm biến gia tốc | Analog | Đại lượng vật lý liên tục |
| ADC | Mixed-signal | Vào analog, ra số |
| Bộ phát hiện bước chân | Digital | Xử lý mẫu số |
| Thanh ghi TỔNG | Digital (tuần tự) | Có ô nhớ, có clock |
| **A01 — bộ cộng + cờ** | **Digital, tổ hợp thuần** | **Đầu ra chỉ phụ thuộc đầu vào hiện tại; không clock, không ô nhớ** |
| Quản lý pin/nguồn | Analog | Điều áp, đo dung lượng |

## 4. Diễn giải quan trọng về "tổng đang giữ"

Charter nói "cộng số bước mới đo được vào **tổng đang giữ**". Câu này dễ bị hiểu nhầm
thành "A01 phải có thanh ghi tích luỹ".

**Không phải vậy.** Charter phân loại A01 là mạch **Tổ hợp**. Vì vậy:

* `A[7:0]` = **tổng hiện tại**, do một thanh ghi **bên ngoài** khối A01 cung cấp;
* `B[7:0]` = **số bước mới** đo được trong chu kỳ này;
* `SUM[7:0]` = tổng mới, được **tầng ngoài** ghi ngược trở lại thanh ghi TỔNG.

Ô nhớ tích luỹ nằm **ngoài** lõi tổ hợp A01. Nếu sinh viên đặt thanh ghi vào trong A01 thì
đã đổi loại mạch so với Charter và vi phạm mục 10 (dấu hiệu làm đúng: **0 ô nhớ**).

## 5. Vì sao bốn cờ là một phần của yêu cầu, không phải trang trí

| Cờ | Ý nghĩa với firmware vòng đeo tay |
|---|---|
| `C` | Tổng bước đã vượt 255 → firmware phải cộng thêm 1 vào byte cao (mở rộng đa byte) |
| `Z` | Tổng bằng 0 → dùng để phát hiện đã reset bộ đếm ngày mới |
| `N` | Bit dấu của kết quả — chỉ có nghĩa khi diễn giải bù 2 (ví dụ khối hiệu chuẩn dùng lại phần cứng này) |
| `V` | Tràn **có dấu** — báo phép tính bù 2 cho kết quả sai dấu |

`C` và `V` **không** thay thế nhau. Xem `02_SPECIFICATION/functional_spec.md` §4.

---

**Truy vết:** yêu cầu sinh ra từ tài liệu này được đánh số `REQ-A01-0xx` trong
`01_REQUIREMENT/requirements.md` và truy vết đến bằng chứng trong `07_TRACEABILITY/RTM.csv`.
