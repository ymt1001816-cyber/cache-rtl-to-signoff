# Functional coverage, after closure: 100 seeds merged

**94 / 94 bins covered (100.0%)**, 0 holes

| Group | Covered | Least-hit bin |
|---|---|---|
| op_result | 5 / 5 | write hit (4745) |
| tag_range | 4 / 4 | tag 63 (737) |
| line_refill | 64 / 64 | line 29 (1031) |
| op_word | 8 / 8 | write word 0 (7419) |
| mem_latency | 8 / 8 | mem write latency 4 (7487) |
| sequence | 3 / 3 | read other word of a line just written (114) |
| corner | 2 / 2 | lowest address 0x0000 (299) |

## Coverage vs number of seeds

| Seeds | Coverage |
|---|---|
| 1 | 100.0% |
| 2 | 100.0% |
| 5 | 100.0% |
| 10 | 100.0% |
| 20 | 100.0% |
| 50 | 100.0% |
| 100 | 100.0% |

## Holes

None.

## Bins (merged hits, first seed)

| Group | Bin | Hits | First seed |
|---|---|---|---|
| op_result | read hit | 13437 | 1 |
| op_result | read cold miss | 6700 | 1 |
| op_result | read conflict miss | 66016 | 1 |
| op_result | write hit | 4745 | 1 |
| op_result | write miss | 25384 | 1 |
| tag_range | tag 0 | 23943 | 1 |
| tag_range | tag 1-31 | 80372 | 1 |
| tag_range | tag 32-62 | 11230 | 1 |
| tag_range | tag 63 | 737 | 1 |
| line_refill | line 0 | 1641 | 1 |
| line_refill | line 1 | 1173 | 1 |
| line_refill | line 2 | 1130 | 1 |
| line_refill | line 3 | 1153 | 1 |
| line_refill | line 4 | 1153 | 1 |
| line_refill | line 5 | 1122 | 1 |
| line_refill | line 6 | 1143 | 1 |
| line_refill | line 7 | 1098 | 1 |
| line_refill | line 8 | 1174 | 1 |
| line_refill | line 9 | 1122 | 1 |
| line_refill | line 10 | 1098 | 1 |
| line_refill | line 11 | 1137 | 1 |
| line_refill | line 12 | 1132 | 1 |
| line_refill | line 13 | 1104 | 1 |
| line_refill | line 14 | 1098 | 1 |
| line_refill | line 15 | 1173 | 1 |
| line_refill | line 16 | 1057 | 1 |
| line_refill | line 17 | 1132 | 1 |
| line_refill | line 18 | 1152 | 1 |
| line_refill | line 19 | 1069 | 1 |
| line_refill | line 20 | 1120 | 1 |
| line_refill | line 21 | 1140 | 1 |
| line_refill | line 22 | 1157 | 1 |
| line_refill | line 23 | 1103 | 1 |
| line_refill | line 24 | 1129 | 1 |
| line_refill | line 25 | 1133 | 1 |
| line_refill | line 26 | 1113 | 1 |
| line_refill | line 27 | 1110 | 1 |
| line_refill | line 28 | 1151 | 1 |
| line_refill | line 29 | 1031 | 1 |
| line_refill | line 30 | 1157 | 1 |
| line_refill | line 31 | 1118 | 1 |
| line_refill | line 32 | 1145 | 1 |
| line_refill | line 33 | 1106 | 1 |
| line_refill | line 34 | 1086 | 1 |
| line_refill | line 35 | 1083 | 1 |
| line_refill | line 36 | 1113 | 1 |
| line_refill | line 37 | 1108 | 1 |
| line_refill | line 38 | 1138 | 1 |
| line_refill | line 39 | 1095 | 1 |
| line_refill | line 40 | 1119 | 1 |
| line_refill | line 41 | 1208 | 1 |
| line_refill | line 42 | 1108 | 1 |
| line_refill | line 43 | 1069 | 1 |
| line_refill | line 44 | 1089 | 1 |
| line_refill | line 45 | 1120 | 1 |
| line_refill | line 46 | 1068 | 1 |
| line_refill | line 47 | 1150 | 1 |
| line_refill | line 48 | 1176 | 1 |
| line_refill | line 49 | 1240 | 1 |
| line_refill | line 50 | 1174 | 1 |
| line_refill | line 51 | 1108 | 1 |
| line_refill | line 52 | 1167 | 1 |
| line_refill | line 53 | 1100 | 1 |
| line_refill | line 54 | 1168 | 1 |
| line_refill | line 55 | 1190 | 1 |
| line_refill | line 56 | 1170 | 1 |
| line_refill | line 57 | 1112 | 1 |
| line_refill | line 58 | 1067 | 1 |
| line_refill | line 59 | 1138 | 1 |
| line_refill | line 60 | 1138 | 1 |
| line_refill | line 61 | 1125 | 1 |
| line_refill | line 62 | 1109 | 1 |
| line_refill | line 63 | 1206 | 1 |
| op_word | read word 0 | 21622 | 1 |
| op_word | read word 1 | 21458 | 1 |
| op_word | read word 2 | 21480 | 1 |
| op_word | read word 3 | 21593 | 1 |
| op_word | write word 0 | 7419 | 1 |
| op_word | write word 1 | 7584 | 1 |
| op_word | write word 2 | 7531 | 1 |
| op_word | write word 3 | 7595 | 1 |
| mem_latency | mem read latency 1 | 72914 | 1 |
| mem_latency | mem read latency 2 | 72484 | 1 |
| mem_latency | mem read latency 3 | 72684 | 1 |
| mem_latency | mem read latency 4 | 72782 | 1 |
| mem_latency | mem write latency 1 | 7520 | 1 |
| mem_latency | mem write latency 2 | 7609 | 1 |
| mem_latency | mem write latency 3 | 7513 | 1 |
| mem_latency | mem write latency 4 | 7487 | 1 |
| sequence | read right after write to same word | 15187 | 1 |
| sequence | read other word of a line just written | 114 | 1 |
| sequence | re-fetch the tag evicted by the previous miss on that line | 11106 | 1 |
| corner | lowest address 0x0000 | 299 | 1 |
| corner | highest address 0xFFFC | 303 | 1 |
