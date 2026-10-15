# =====================================================================
#  A01 — SDC cho PHAN TICH TIMING (virtual clock)
# ---------------------------------------------------------------------
#  CANH BAO QUAN TRONG
#  A01 la mach TO HOP THUAN. No KHONG CO CLOCK.
#  Clock 'vclk' duoi day la MOC QUY CHIEU de cong cu STA tinh duoc
#  slack tren duong to hop. KHONG duoc dien giai period 10 ns thanh
#  "A01 chay o 100 MHz".
#
#  Ba gia dinh phai neu kem moi con so bao cao (xem 02_SPECIFICATION/timing.md §3):
#    G-1  period vclk         = 10.0 ns   (gia dinh phan tich)
#    G-2  input/output delay  = 0.0 ns    (gia dinh ly tuong)
#    G-3  thu vien + PVT      = sky130_fd_sc_hd__tt_025C_1v80
#
#  Dai luong CO Y NGHIA can trich ra la 'data arrival time' cua duong
#  a/b -> c (hoac -> z, -> v), tuc DO TRE TO HOP THAT.
# =====================================================================

# --- Clock ao lam moc quy chieu -------------------------------------
create_clock -name vclk -period 10.0

# --- Gan moi cong vao/ra vao mien clock ao ---------------------------
set_input_delay  0.0 -clock vclk [get_ports {a[*] b[*]}]
set_output_delay 0.0 -clock vclk [get_ports {sum[*] c z n v}]

# --- Dieu kien tai/driver ------------------------------------------
# De mac dinh theo thu vien. Khi da biet tang ngoai that, thay bang:
#   set_load <pF> [all_outputs]
#   set_driving_cell -lib_cell <cell> [all_inputs]

# --- Ghi chu ---------------------------------------------------------
# KHONG khai bao set_false_path hay set_multicycle_path o day.
# A01 khong co ngoai le timing nao; moi duong deu phai duoc phan tich.
