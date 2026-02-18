# Zig Benchmark Engine & AoC Runner

A sub-millisecond, high-performance benchmarking harness for [Advent of Code](https://adventofcode.com/), built in [Zig](https://ziglang.org/).

This engine is designed to be **statistically rigorous**. It isolates your solution's logic to report the "true" execution time of your algorithms.

## 🚀 Features

* **Zero-Allocation Runner:** The harness itself allocates almost nothing; your solutions run in a controlled environment.
* **Kernel Trust Cache Optimization:** The engine is architected to account for macOS/Linux binary verification delays (~5µs overhead on new binaries).
* **Automatic Discovery:** Just add `day_XX.zig` to the year folder; the build system finds and compiles it.
* **Comptime Generation:** The test runner is generated at compile time for maximum efficiency.

## 🛠️ Usage

### Prerequisites

* Tested on **Zig 0.15.2**

### Running Solutions

Run the solution for a specific day (defaulting to 2025):

```bash
# Run Day 1
zig build solve -Dday=1

# Run Day 1 through Day 5
zig build solve -Dday=1..5
```

### Benchmarking

Enable the statistical benchmarking mode. This runs your solution multiple times (default: 100 iterations), calculates the Mean, Median, Min, Max, and Standard Deviation.

```bash
# Benchmark Day 2 with ReleaseFast optimizations
zig build solve -Dday=2 -Dbench=true -Doptimize=ReleaseFast
```

**Note:** For the most accurate results on laptops, **plug your device into power** to prevent the PMU (Power Management Unit) from throttling the CPU frequency.

## ⚙️ Configuration Flags

|Flag          |Type           |Default  |Description|
|--------------|---------------|---------|-----------|
|`-Dday`       |`u8` or `range`|`1`      |The day(s) to execute. Accepts single numbers (`1`) or ranges (`1..5`).|
|`-Dyear`      |`u16`          |`2025`   |The target year directory.|
|`-Dbench`     |`bool`         |`false`  |Enable statistical benchmarking mode.|
|`-Dbench_iter`|`usize`        |`100`    |Number of iterations for the benchmark loop.|
|`-Doptimize`  |`enum`         |`Debug`  |Compilation mode (`Debug`, `ReleaseSafe`, `ReleaseFast`, `ReleaseSmall`).|

## 📂 Project Structure

```text
.
├── build.zig               # The Build Logic (Orchestrator)
├── src/
│   └── runner.zig          # The Engine (Agnostic Benchmarking Harness)
├── 2025/                   # Your Solutions (The Data)
│   ├── day_01.zig
│   └── ...
├── input/                  # Your Input Data
│   └── 2025/
│       ├── day_01.txt
│       └── ...
└── README.md
```

## 🧠 Performance Notes

### The "New Binary" Tax

On modern operating systems (especially macOS with Silicon), the Kernel performs mandatory verification (AMFI/Code Signing) on every new binary hash. This introduces a ~5µs - 10µs latency on the very first execution of a fresh build.

## ⚖️ License

MIT
