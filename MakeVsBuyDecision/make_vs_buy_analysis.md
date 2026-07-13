# Make vs. Buy Financial Decision Report

This report evaluates the financial feasibility of making a component in-house using new machinery versus buying it from the market over a 5-year project horizon.

---

## 📊 Summary of Decision Metrics

| Metric | Option A: Make | Option B: Buy | Difference (Savings) |
| :--- | :---: | :---: | :---: |
| **Undiscounted Net Outflows** | Shs -7,000,000.00 | Shs -8,540,000.00 | Shs 1,540,000.00 |
| **Present Value of Outflows (10% WACC)** | Shs -5,466,493.10 | Shs -6,354,682.68 | **Shs 888,189.57** |

> [!IMPORTANT]
> **RECOMMENDED ACTION: MAKE THE COMPONENT**
> In-house manufacturing is the financially superior option. Under a 10% cost of capital (discount rate), making the component results in a Present Value cost of **Shs -5,466,493.10** compared to **Shs -6,354,682.68** for buying. This represents a net present value saving of **Shs 888,189.57**.

---

## 🛠️ Key Assumptions

* **Income Tax Rate**: 30.0% (applied as a tax shield on operating and capital losses/expenses)
* **Discount Rate**: 10.0% WACC
* **Machinery Initial Cost**: Shs 1,000,000 (Class IV wear & tear allowance applied)
* **Machinery Salvage Value (Year 5)**: Shs 200,000
* **Depreciation Rate**: 12.5% reducing balance basis (wear & tear allowance for Class IV machinery)
* **Terminal Loss**: Evaluated at Year 5 based on final book value vs. salvage value.

---

## 📝 Step-by-Step Cash Flow Breakdown

### 1. Option A: Make the Component
* **Year 0**: Machinery capital expenditure of **Shs 1,000,000** (Cash Outflow).
* **Year 1-5 Operating Costs**: Manufacturing costs incurred and reduced by a 30% tax shield.
* **Depreciation Allowance**: Annual tax shield of `Depreciation * 30%` is claimed.
* **Year 5 Terminal Inflow**: Salvage value inflow of **Shs 200,000** plus a tax shield of **Shs 93,872.68** on the terminal capital loss of **Shs 312,908.94**.

| Cash Flow Component | Year 0 | Year 1 | Year 2 | Year 3 | Year 4 | Year 5 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Machinery Outlay** | -1,000,000 | 0 | 0 | 0 | 0 | 0 |
| **Manufacturing Cost** | 0 | -1,400,000 | -1,600,000 | -1,800,000 | -2,000,000 | -2,400,000 |
| **Tax Shield on Cost (30%)** | 0 | +420,000 | +480,000 | +540,000 | +600,000 | +720,000 |
| **Depreciation Allowance (12.5%)**| 0 | 125,000 | 109,375 | 95,703 | 83,740 | 73,273 |
| **Tax Shield on Depreciation (30%)**| 0 | +37,500 | +32,813 | +28,711 | +25,122 | +21,982 |
| **Machinery Salvage Value** | 0 | 0 | 0 | 0 | 0 | +200,000 |
| **Terminal Loss Tax Shield** | 0 | 0 | 0 | 0 | 0 | +93,873 |
| **Net Cash Flow (Make)** | **-1,000,000** | **-942,500** | **-1,087,188** | **-1,231,289** | **-1,374,878** | **-1,364,146** |

### 2. Option B: Buy the Component
* Purchasing cost is a tax-deductible expense, resulting in a net cash outflow of `Cost * (1 - Tax Rate) = Cost * 70%`.

| Cash Flow Component | Year 0 | Year 1 | Year 2 | Year 3 | Year 4 | Year 5 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Market Purchase Cost** | 0 | -2,000,000 | -2,200,000 | -2,400,000 | -2,600,000 | -3,000,000 |
| **Tax Shield on Purchase (30%)** | 0 | +600,000 | +660,000 | +720,000 | +780,000 | +900,000 |
| **Net Cash Flow (Buy)** | **0** | **-1,400,000** | **-1,540,000** | **-1,680,000** | **-1,820,000** | **-2,100,000** |

---

## 🔍 Financial Analysis & Interpretation

1. **Operating Cost Advantage**: In-house manufacturing costs are lower than purchase costs every year. Even with Year 0 capital outlay of Shs 1,000,000, the operating savings quickly pay back the machine.
2. **Tax Shields**: The Wear and Tear allowance (Class IV machinery - 12.5% reducing balance) generates tax shields that reduce the net cost of making. At Year 5, selling the machine below book value creates a terminal tax shield of **Shs 93,873**, which further increases Year 5 cash inflows.
3. **Discounted Present Value**: Because the cash outflows for making are lower than buying across all years, the present value of outflows is significantly lower for the Make option. Making the component remains the optimal decision across any reasonable discount rate (WACC).
