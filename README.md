# Smart Contract Security Testing

This project demonstrates security testing methodology for Ethereum smart contracts using **Foundry** (unit testing) and **Medusa** (fuzzing).

## Features
- **Calldata Gas Optimization**: Analysis of gas costs for zero vs non-zero bytes.
- **General Logic Implementation**: Basic counter contract with fuzz tests.
- **Reentrancy Vulnerability**:
    - Vulnerable Bank contract implementation.
    - Manual exploit using Foundry tests.
    - Automated detection using Medusa fuzzing with a custom harness.

## Requirements
- [Foundry](https://getfoundry.sh/)
- [Medusa](https://github.com/crytic/medusa)
- Python 3.8+ (for scripts)

## Installation

1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd tt
   ```

2. Install dependencies:
   ```bash
   forge install
   ```

3. Setup Python environment (for gas measurement):
   ```bash
   # Linux/Mac
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt

   # Windows
   python -m venv venv_win
   .\venv_win\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```

## Usage

### Run Unit Tests
```bash
forge test
```

### Run Gas Measurement
```bash
python tests/measure_calldata_gas.py
```

### Run Fuzzing (Medusa)
To detect the reentrancy vulnerability:
```bash
medusa --config medusa_reentrancy.json fuzz
```

## Reports
Security reports are generated and archived in the `reports/` directory.
Use `python scripts/archive_report.py` to archive the current `report.md` linked to the current git commit.
