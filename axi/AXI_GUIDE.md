# AXI4-Lite 練習：幫 cache 加一個業界標準的 CPU 介面

## 為什麼

現在 cache 的 CPU 端是自己定義的介面（`cpu_rd`／`cpu_wr`／`cpu_ready`）。真實晶片的 IP 都掛在標準匯流排上，
ARM 的 **AMBA AXI** 最常見。DV 工程師的日常工作有很大一部分是驗證「某個 IP 有沒有遵守 AXI 協定」，
所以面試很常問 AXI 的 handshake 規則。AXI4-Lite 是簡化版：沒有 burst，一次傳一個字，最適合入門。

## 架構

```
CPU / testbench ──AXI4-Lite──► axil_cache (你寫的 wrapper) ──cpu_*──► cache_top (原本的，不動) ──mem_*──► memory
```

wrapper 只負責「翻譯」：把 AXI 的讀寫請求轉成 `cpu_rd`／`cpu_wr`，等 `cpu_ready` 後再回 AXI 的回應。

## 5 個 channel

| Channel | 方向 | 訊號 | 意思 |
|---|---|---|---|
| AW（write address） | master → slave | `awvalid` `awready` `awaddr` | 我要寫這個地址 |
| W（write data） | master → slave | `wvalid` `wready` `wdata` `wstrb` | 要寫的資料（`wstrb` = 哪幾個 byte） |
| B（write response） | slave → master | `bvalid` `bready` `bresp` | 寫完了（`bresp` = 00 OKAY） |
| AR（read address） | master → slave | `arvalid` `arready` `araddr` | 我要讀這個地址 |
| R（read data） | slave → master | `rvalid` `rready` `rdata` `rresp` | 讀到的資料 |

## 最重要的規則：VALID / READY handshake

**一次傳輸只在 `VALID && READY` 同時為 1 的那個 clock 上升緣發生。**

1. **VALID 不能等 READY**：送的一方不可以等看到 READY 才拉 VALID（否則兩邊互等 → deadlock）
2. **VALID 拉起來後不能自己放下**，資料也不能變，直到 handshake 完成（面試必問）
3. **READY 可以等 VALID**：收的一方可以看到 VALID 才拉 READY
4. AW 和 W 是兩個獨立的 channel，**順序不固定**：可能地址先到、資料先到，或同一個 cycle 一起到 → slave 兩個都收到才開始寫
5. B 回應要在 AW 和 W **都完成之後**才能送
6. R 回應要在 AR 完成之後才能送

## 你要寫的：`axi/axil_cache.v`

骨架已經放好，介面不要改（testbench 會用）。建議的狀態機：

```
IDLE ──(arvalid)──► READ  ──(cpu_ready)──► RRESP ──(rready)──► IDLE
  └──(收齊 AW + W)──► WRITE ──(cpu_ready)──► BRESP ──(bready)──► IDLE
```

提示：

- IDLE 時：`arready = 1`；AW 和 W 各用一個暫存器記住「收到了沒」，兩個都收到才去 WRITE
- 讀和寫同時來的話，選一個優先就好（例如讀優先），規格允許
- READ／WRITE 狀態時，把 `cpu_rd`／`cpu_wr` 拉起來，地址和資料要用**暫存器存好的值**（AXI 的 valid 在 handshake 後就會放掉）
- `cpu_ready` 那個 cycle 把 `cpu_rdata` 存起來，在 RRESP 狀態送出去，`rvalid` 要一直保持到 `rready`（規則 2）
- `wstrb`：cache 只支援整個 word 寫入，先假設 `wstrb = 4'hf`（加分：不是 `f` 時回 `bresp = 2'b10 SLVERR`）
- `cache_top` 的 `cpu_addr` 是 16 位元的 byte 地址：用 `awaddr[15:0]`／`araddr[15:0]`

## 檢查

```bash
cd axi && iverilog -g2012 -o sim ../rtl/cache_top.v axil_cache.v tb_axil_cache.sv && vvp -n sim
```

目標：`AXI-LITE: PASS ... FAIL 0` 和 `protocol violations: 0`

testbench 會：

- 故意讓 AW 和 W 用不同順序到達
- 隨機延遲 `bready`／`rready`
- 檢查你的 `rvalid`／`bvalid` 拉起來之後有沒有自己放下

## 下一步（寫完 RTL 之後）

1. **Protocol assertion**（你寫 SVA）：把上面規則 1、2、5 寫成 assertion，放在 `axi/axil_sva.sv`
2. **UVM agent**：AXI master driver + monitor，接到原本的 scoreboard

## 面試常問

- AXI 有幾個 channel？為什麼讀寫分開？→ 5 個；讀寫可以同時進行
- VALID 可以等 READY 嗎？→ 不行，會 deadlock
- AXI4 和 AXI4-Lite 差在哪？→ Lite 沒有 burst、沒有 ID，每次一個 data beat
- `wstrb` 是什麼？→ byte enable，哪幾個 byte 要寫
