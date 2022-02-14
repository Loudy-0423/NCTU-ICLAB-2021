//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2020 ICLAB Fall Course
//   Lab06       : GF 2k Arithmetic Soft IP
//   Author      : Tien-Hui Lee (bnfw623@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : v1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
    `define CYCLE_TIME 10.0
`endif

`ifdef GATE
    `define CYCLE_TIME 10.0
`endif


module PATTERN_IP(
    // Output signals
    POLY,IN1,IN2,
    // Input signals
    RESULT
);

//================================================================
//   INPUT AND OUTPUT DECLARATION
//================================================================
parameter DEG = 4, OP = 3;
output reg[DEG:0] POLY;
output reg[DEG-1:0] IN1;
output reg[DEG-1:0] IN2;

input [DEG-1:0] RESULT;

//pragma protect begin_protected
//pragma protect key_keyowner=Cadence Design Systems.
//pragma protect key_keyname=CDS_KEY
//pragma protect key_method=RC5
//pragma protect key_block
wYE+tmxP0p09+tk+xqtdU9wlKNKBf2gkhhwJXAZNvslKIIF8zDFFplFxPWINfr7+
1HmCkReNORI4I6n7F6YQOpOPi9KPx+L5ET2huL7SUk6x3axfWOMnwMtlR+qiZ3Fl
KIfVfvNaIuPf47cIXVR37tk3rXGOJdwHp6OBf7L+U34WhDJdokj/Tw==
//pragma protect end_key_block
//pragma protect digest_block
L2MCpi9Bzv7xVjDupcjs1QLpImo=
//pragma protect end_digest_block
//pragma protect data_block
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
7gUOI/Ks01/SniAEVGFRjQ==
//pragma protect end_data_block
//pragma protect digest_block
7fRKg8OjmGT2SDnNW97mPkTw2bk=
//pragma protect end_digest_block
//pragma protect end_protected

endmodule
