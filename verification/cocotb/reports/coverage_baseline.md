# Functional coverage, before closure: 100 seeds merged

**91 / 94 bins covered (96.8%)**, 3 holes

| Group | Covered | Least-hit bin |
|---|---|---|
| op_result | 5 / 5 | read cold miss (6500) |
| tag_range | 2 / 4 | tag 32-62 (0) |
| line_refill | 64 / 64 | line 59 (931) |
| op_word | 8 / 8 | write word 2 (7428) |
| mem_latency | 8 / 8 | mem write latency 3 (7475) |
| sequence | 3 / 3 | read other word of a line just written (44) |
| corner | 1 / 2 | highest address 0xFFFC (0) |

## Coverage vs number of seeds

| Seeds | Coverage |
|---|---|
| 1 | 96.8% |
| 2 | 96.8% |
| 5 | 96.8% |
| 10 | 96.8% |
| 20 | 96.8% |
| 50 | 96.8% |
| 100 | 96.8% |

## Holes

- tag_range: tag 32-62
- tag_range: tag 63
- corner: highest address 0xFFFC

## Bins (merged hits, first seed)

| Group | Bin | Hits | First seed |
|---|---|---|---|
| op_result | read hit | 19815 | 1 |
| op_result | read cold miss | 6500 | 1 |
| op_result | read conflict miss | 59354 | 1 |
| op_result | write hit | 7111 | 1 |
| op_result | write miss | 22971 | 1 |
| tag_range | tag 0 | 29237 | 1 |
| tag_range | tag 1-31 | 86514 | 1 |
| tag_range | tag 32-62 | 0 | - |
| tag_range | tag 63 | 0 | - |
| line_refill | line 0 | 1363 | 1 |
| line_refill | line 1 | 1060 | 1 |
| line_refill | line 2 | 1012 | 1 |
| line_refill | line 3 | 1104 | 1 |
| line_refill | line 4 | 1011 | 1 |
| line_refill | line 5 | 1013 | 1 |
| line_refill | line 6 | 1023 | 1 |
| line_refill | line 7 | 967 | 1 |
| line_refill | line 8 | 1072 | 1 |
| line_refill | line 9 | 1030 | 1 |
| line_refill | line 10 | 956 | 1 |
| line_refill | line 11 | 1062 | 1 |
| line_refill | line 12 | 1020 | 1 |
| line_refill | line 13 | 1040 | 1 |
| line_refill | line 14 | 1095 | 1 |
| line_refill | line 15 | 1028 | 1 |
| line_refill | line 16 | 967 | 1 |
| line_refill | line 17 | 1024 | 1 |
| line_refill | line 18 | 1081 | 1 |
| line_refill | line 19 | 985 | 1 |
| line_refill | line 20 | 1015 | 1 |
| line_refill | line 21 | 1063 | 1 |
| line_refill | line 22 | 1070 | 1 |
| line_refill | line 23 | 992 | 1 |
| line_refill | line 24 | 1040 | 1 |
| line_refill | line 25 | 977 | 1 |
| line_refill | line 26 | 1036 | 1 |
| line_refill | line 27 | 989 | 1 |
| line_refill | line 28 | 984 | 1 |
| line_refill | line 29 | 1022 | 1 |
| line_refill | line 30 | 1019 | 1 |
| line_refill | line 31 | 976 | 1 |
| line_refill | line 32 | 979 | 1 |
| line_refill | line 33 | 1047 | 1 |
| line_refill | line 34 | 1060 | 1 |
| line_refill | line 35 | 1071 | 1 |
| line_refill | line 36 | 1014 | 1 |
| line_refill | line 37 | 1056 | 1 |
| line_refill | line 38 | 1018 | 1 |
| line_refill | line 39 | 1026 | 1 |
| line_refill | line 40 | 1027 | 1 |
| line_refill | line 41 | 1063 | 1 |
| line_refill | line 42 | 1042 | 1 |
| line_refill | line 43 | 1019 | 1 |
| line_refill | line 44 | 992 | 1 |
| line_refill | line 45 | 1045 | 1 |
| line_refill | line 46 | 1029 | 1 |
| line_refill | line 47 | 1051 | 1 |
| line_refill | line 48 | 1048 | 1 |
| line_refill | line 49 | 1001 | 1 |
| line_refill | line 50 | 1002 | 1 |
| line_refill | line 51 | 1038 | 1 |
| line_refill | line 52 | 1037 | 1 |
| line_refill | line 53 | 944 | 1 |
| line_refill | line 54 | 1019 | 1 |
| line_refill | line 55 | 1033 | 1 |
| line_refill | line 56 | 1042 | 1 |
| line_refill | line 57 | 1026 | 1 |
| line_refill | line 58 | 963 | 1 |
| line_refill | line 59 | 931 | 1 |
| line_refill | line 60 | 1034 | 1 |
| line_refill | line 61 | 1017 | 1 |
| line_refill | line 62 | 1060 | 1 |
| line_refill | line 63 | 1024 | 1 |
| op_word | read word 0 | 21412 | 1 |
| op_word | read word 1 | 21731 | 1 |
| op_word | read word 2 | 21239 | 1 |
| op_word | read word 3 | 21287 | 1 |
| op_word | write word 0 | 7463 | 1 |
| op_word | write word 1 | 7637 | 1 |
| op_word | write word 2 | 7428 | 1 |
| op_word | write word 3 | 7554 | 1 |
| mem_latency | mem read latency 1 | 65667 | 1 |
| mem_latency | mem read latency 2 | 65540 | 1 |
| mem_latency | mem read latency 3 | 65889 | 1 |
| mem_latency | mem read latency 4 | 66320 | 1 |
| mem_latency | mem write latency 1 | 7570 | 1 |
| mem_latency | mem write latency 2 | 7491 | 1 |
| mem_latency | mem write latency 3 | 7475 | 1 |
| mem_latency | mem write latency 4 | 7546 | 1 |
| sequence | read right after write to same word | 15162 | 1 |
| sequence | read other word of a line just written | 44 | 1 |
| sequence | re-fetch the tag evicted by the previous miss on that line | 17505 | 1 |
| corner | lowest address 0x0000 | 210 | 1 |
| corner | highest address 0xFFFC | 0 | - |
