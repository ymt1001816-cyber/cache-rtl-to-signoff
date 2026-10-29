# test_cache.py : cocotb testbench for the 1 KB direct-mapped, write-through, no-write-allocate cache
#   memory model with random latency, Python reference model that predicts hit / miss,
#   scoreboard on data AND memory traffic, functional coverage that must be complete
import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge

LINES, WORDS = 64, 4                    # 64 lines x 4 words x 4 bytes = 1 KB
N = int(os.environ.get("N", "3000"))    # random requests


class Memory:
    """Main memory: answers mem_rd / mem_wr after a random 1-4 cycle latency. Drives at the falling edge."""

    def __init__(self, dut):
        self.dut = dut
        self.data = {}                  # word address -> value (default pattern A000_0000 + address)
        self.reads = self.writes = 0
        self.latencies = set()
        dut.mem_ack.value = 0
        dut.mem_rdata.value = 0

    def read(self, waddr):
        return self.data.get(waddr, 0xA000_0000 + waddr)

    async def run(self):
        """Same as the memory in tb_cache.v, but the latency is random for every access.
        Reacts at the rising edge (like a nonblocking assignment): it reads the values the DUT had
        before the edge, and its new mem_ack / mem_rdata are seen by the DUT at the next edge."""
        dut = self.dut
        wait, lat, ack = 0, random.randint(1, 4), False
        while True:
            await RisingEdge(dut.clk)
            if ack:                     # ack lasts one cycle
                dut.mem_ack.value = 0
                ack = False
                continue
            rd, wr = dut.mem_rd.value == 1, dut.mem_wr.value == 1     # "== 1": X before reset counts as 0
            if not (rd or wr):
                continue
            wait += 1
            if wait < lat:
                continue
            waddr = int(dut.mem_addr.value)
            if rd:
                dut.mem_rdata.value = self.read(waddr)
                self.reads += 1
            else:
                self.data[waddr] = int(dut.mem_wdata.value)
                self.writes += 1
            dut.mem_ack.value = 1
            ack = True
            self.latencies.add(lat)
            wait, lat = 0, random.randint(1, 4)


class CacheModel:
    """Reference model: which line holds which tag. Predicts hit / miss; data comes from the memory model."""

    def __init__(self):
        self.tag = [None] * LINES

    @staticmethod
    def split(addr):
        return (addr >> 10) & 0x3F, (addr >> 4) & (LINES - 1)    # tag, index

    def access(self, addr, is_write):
        """Return (hit, conflict) and update the tags like the RTL."""
        # called BEFORE the DUT does the access
        #   hit      = line i holds tag t
        #   conflict = miss, and line i already holds another tag (the refill will evict it)
        #   update   = only a READ miss refills the line (store t in self.tag[i]);
        #              a write never changes the tags (write-through, no-write-allocate)
        t, i = self.split(addr)
        hit = self.tag[i] == t
        conflict = not hit and self.tag[i] is not None
        if not is_write and not hit:
            self.tag[i] = t
        return hit, conflict


class Coverage:
    def __init__(self):
        self.bins = {k: 0 for k in ("read hit", "read miss", "write hit", "write miss",
                                    "read miss evicts another tag", "read right after write to same word")}

    def hit(self, name):
        self.bins[name] += 1

    def report(self, log):
        for k, v in self.bins.items():
            log.info("  coverage %-36s %6d", k, v)
        return [k for k, v in self.bins.items() if v == 0]


class Tb:
    def __init__(self, dut):
        self.dut, self.mem, self.model, self.cov = dut, Memory(dut), CacheModel(), Coverage()
        self.passed = self.failed = 0
        self.last_write = None

    async def start(self):
        dut = self.dut
        cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
        cocotb.start_soon(self.mem.run())
        dut.cpu_rd.value = dut.cpu_wr.value = 0
        dut.cpu_addr.value = dut.cpu_wdata.value = 0
        dut.rst_n.value = 0
        for _ in range(3):
            await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        dut.rst_n.value = 1

    async def finish(self):
        """End every test one clock edge after the last write: in this cocotb build (2.1 dev + Icarus 14 dev),
        a test that ends in the same time step as a signal write makes vvp crash on exit."""
        await RisingEdge(self.dut.clk)

    def check(self, ok, msg):
        if ok:
            self.passed += 1
        else:
            self.failed += 1
            if self.failed <= 10:
                self.dut._log.error(msg)

    async def request(self, addr, wdata=None):
        """Drive one CPU request (same timing as tb_cache.v); return cpu_rdata."""
        dut = self.dut
        # same steps as task cpu_read / cpu_write in tb/tb_cache.v
        #   a. await FallingEdge(dut.clk); set cpu_addr, and cpu_rd = 1 (read, wdata is None)
        #      or cpu_wdata + cpu_wr = 1 (write)
        #   b. await FallingEdge(dut.clk); then keep awaiting FallingEdge while dut.cpu_ready.value != 1
        #      (count the cycles and assert cycles < 100, so a hung DUT fails instead of running forever)
        #   c. read: rdata = int(dut.cpu_rdata.value) now, while cpu_ready = 1; write: rdata = None
        #   d. await RisingEdge, await FallingEdge, then cpu_rd = cpu_wr = 0; return rdata
        await FallingEdge(dut.clk)
        dut.cpu_addr.value = addr
        dut.cpu_rd.value = int(wdata is None)
        dut.cpu_wr.value = int(wdata is not None)
        if wdata is not None:
            dut.cpu_wdata.value = wdata
        await FallingEdge(dut.clk)
        cycles = 0
        while dut.cpu_ready.value != 1:
            cycles += 1
            assert cycles < 100, f"CPU request timed out at address {addr:04x}"
            await FallingEdge(dut.clk)
        rdata = int(dut.cpu_rdata.value) if wdata is None else None
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        dut.cpu_rd.value = dut.cpu_wr.value = 0
        return rdata

    async def read(self, addr):
        r0 = self.mem.reads
        hit, conflict = self.model.access(addr, False)
        expect = self.mem.read(addr >> 2)
        got = await self.request(addr)
        n = self.mem.reads - r0
        self.check(got == expect, f"read {addr:04x}: data {got:08x}, expected {expect:08x}")
        self.check(n == (0 if hit else WORDS),
                   f"read {addr:04x}: {n} memory reads, expected {0 if hit else WORDS} ({'hit' if hit else 'miss'})")
        self.cov.hit("read hit" if hit else "read miss")
        if conflict:
            self.cov.hit("read miss evicts another tag")
        if self.last_write == addr >> 2:
            self.cov.hit("read right after write to same word")
        self.last_write = None

    async def write(self, addr, data):
        r0, w0 = self.mem.reads, self.mem.writes
        hit, _ = self.model.access(addr, True)
        await self.request(addr, data)
        # write scoreboard
        #   check 1: exactly 1 memory write and 0 memory reads during this request (write-through, no-write-allocate)
        #   check 2: the memory now holds data at word address addr >> 2 (self.mem.read)
        #   coverage: "write hit" or "write miss"; then remember self.last_write = addr >> 2
        nr, nw = self.mem.reads - r0, self.mem.writes - w0
        self.check(nw == 1 and nr == 0,
                   f"write {addr:04x}: {nw} memory writes, {nr} memory reads; expected 1 and 0")
        self.check(self.mem.read(addr >> 2) == data,
                   f"write {addr:04x}: memory data {self.mem.read(addr >> 2):08x}, expected {data:08x}")
        self.cov.hit("write hit" if hit else "write miss")
        self.last_write = addr >> 2


def random_addr():
    """4 tags x 64 lines x 4 words: enough reuse for hits, enough tags for conflicts."""
    return (random.randrange(4) << 10) | (random.randrange(LINES) << 4) | (random.randrange(WORDS) << 2)


@cocotb.test()
async def test_directed(dut):
    """Read miss, read hit, write hit, read back, write miss (no allocate), conflict miss."""
    tb = Tb(dut)
    await tb.start()
    await tb.read(0x0000)
    await tb.read(0x0004)
    await tb.write(0x0004, 0x1234_5678)
    await tb.read(0x0004)
    await tb.write(0x4404, 0xCAFE_0001)
    await tb.read(0x4404)
    await tb.read(0x0400)
    await tb.read(0x0004)
    await tb.finish()
    assert tb.failed == 0, f"{tb.failed} checks failed"
    dut._log.info("directed: %d checks passed", tb.passed)


@cocotb.test()
async def test_random(dut):
    """N random reads / writes with random memory latency; data, hit / miss and coverage checked."""
    tb = Tb(dut)
    await tb.start()
    # N random requests, addresses from random_addr()
    #   about 30% writes (random 32-bit data: random.getrandbits(32)), the rest reads
    #   after some of the writes, read the same address right away (fills "read right after write to same word")
    for _ in range(N):
        addr = random_addr()
        if random.random() < 0.30:
            await tb.write(addr, random.getrandbits(32))
            if random.random() < 0.50:
                await tb.read(addr)
        else:
            await tb.read(addr)
    await tb.finish()
    missing = tb.cov.report(dut._log)
    dut._log.info("memory latencies seen: %s", sorted(tb.mem.latencies))
    dut._log.info("random: %d checks passed, %d failed", tb.passed, tb.failed)
    assert tb.failed == 0, f"{tb.failed} checks failed"
    assert not missing, f"coverage holes: {missing}"
    assert tb.mem.latencies == {1, 2, 3, 4}, "not every memory latency was used"
