# tb/

Testbenches, one subfolder per IP, mirroring `rtl/` exactly. Each testbench should implement the
test cases assigned to it in `doc/ARCHITECTURE.md` Section 12 (Verification Plan), referenced by
Test ID (e.g. `tb/uart/` implements TC-UART-01, TC-UART-02).

A top-level full-system testbench (in `tb/core/`) boots the application binary described in Section
11 and checks end-to-end behavior (TC-APP-01).
