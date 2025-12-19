// SPDX-FileCopyrightText: 2025 VSD
// SPDX-License-Identifier: Apache-2.0
//
// SCL180 Pad Macros for vsdRiscvScl180
// Pure SCL180 implementation - no SKY130 references

`ifndef SCL180_PADS_V
`define SCL180_PADS_V

// ============================================================================
// INPUT PAD - SCL180 pc3d01 (Input-only pad)
// ============================================================================
`define INPUT_PAD_SCL(X, Y) \
    pc3d01_wrapper X``_pad ( \
        .PAD(X), \
        .IN(Y) \
    )

// ============================================================================
// OUTPUT PAD - SCL180 pt3b02 (Output with tri-state)
// ============================================================================
`define OUTPUT_PAD_SCL(X, Y, OUT_EN_N) \
    pt3b02_wrapper X``_pad ( \
        .PAD(X), \
        .OUT(Y), \
        .OE_N(OUT_EN_N) \
    )

// ============================================================================
// BIDIRECTIONAL PAD - SCL180 pc3b03ed (Configurable I/O)
// ============================================================================
`define BIDIR_PAD_SCL(X, Y_IN, Y_OUT, INPUT_DIS, OUT_EN_N, DM) \
    pc3b03ed_wrapper X``_pad ( \
        .PAD(X), \
        .IN(Y_IN), \
        .OUT(Y_OUT), \
        .INPUT_DIS(INPUT_DIS), \
        .OUT_EN_N(OUT_EN_N), \
        .dm(DM) \
    )

// ============================================================================
// RESET PAD - SCL180 pc3d01 (Always-on input for reset)
// Purpose: Receives external reset signal
// Justification: No POR gating needed - pad input buffer is always active
// ============================================================================
`define RESET_PAD_SCL(X, Y) \
    pc3d01_wrapper X``_pad ( \
        .PAD(X), \
        .IN(Y) \
    )

// ============================================================================
// CLOCK PAD - SCL180 pc3d01 (Input for clock signals)
// ============================================================================
`define CLOCK_PAD_SCL(X, Y) \
    pc3d01_wrapper X``_pad ( \
        .PAD(X), \
        .IN(Y) \
    )

// ============================================================================
// POWER PAD - SCL180 pv0sd (Power/Ground)
// Note: Typically instantiated directly, not via macro
// ============================================================================

`endif // SCL180_PADS_V
