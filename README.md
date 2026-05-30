# Growth Budget Allocation

## Overview
This project evaluates whether and where an incremental $3M growth budget should be deployed in 2015. The analysis uses a decision gate framework to
screen markets, levers, and segments. Options viable under a risk managed mandate survive the screen; paths lacking sufficient scale or structural
demand are excluded. 

The pipeline surfaces only signals material enough to change allocation decisions, keeping the process resistant to weak, incentive
based narratives that do not scale.

## Decision context
**Decision:** How to allocate an incremental $3M growth budget  
**Scope:** 2015 planning cycle  

**Objectives:**
- Identify markets capable of absorbing the $3M 2015 growth budget and exclude those that cannot
- Distinguish structural demand drivers from incentive based levers
- Define conditions under which deploying the $3M budget would create unacceptable risk or future regret

> Executive deliverable (decision narrative + recommendations): [`Executive decision summary (Website)`](https://bryan-melvida.super.site/data-analytics/3m-growth-allocation-decision-screen)

## Deliverables
- **Decision narrative report** (Power BI, exported as static PDF)
- **Executive summary** (website format)
- **SQL analysis pipeline** supporting all conclusions
- **Documented assumptions, preprocessing decisions, and exclusions**

## How the analysis is structured
- `01_data_cleaning.sql`
  - Ingest raw transactional data
  - Validate quality, consistency, and anomalies
  - Apply targeted corrections before analysis

- `02_exploratory_data_analysis.sql`
  - Screen budget allocation through demand, scale, and risk
  - Surface only signals that can change a deployment decision
  - Eliminate narratives that are incentive based or do not scale
  - Produce decision inputs, not recommendations

- `03_reporting_extract.sql`
  - Extract reporting data derived from validated analysis outputs

## Repository structure

```
├── data/
│   ├── raw/                                   # original source data
│   ├── processed/                             # cleaned and validated data
│   └── exported_tables/                       # extracts ready for reporting
├── sql/
│   └── scripts/
│       ├── 01_data_cleaning.sql               # data validation and corrections
│       ├── 02_exploratory_data_analysis.sql   # decision gate analysis
│       └── 03_reporting_extract.sql           # final reporting outputs
├── docs/
│   ├── decision_logs.md                       # decision framework and evaluation structure
│   ├── analysis_pipeline.md                   # analytical flow and logic
│   ├── data_dictionary.md                     # field definitions
│   ├── preprocessing_log.md                   # data handling decisions
│   └── decision_gate_rationale.md             # decision constraints and growth narratives ruled out
└── power_bi/
    ├── artifacts/                             # exported decision artifacts (PDF and images)
    │   └── images/                            # exported image previews of decision pages
    └── reports/                               # Power BI reports and model files (PBIX)
```

## Scope boundaries
This project intentionally does **not**:
- Optimize spend mix or execution tactics
- Rank or prioritize within surviving options
- Recommend growth actions absent structural demand

Its purpose is to establish eligibility, exclusion, and risk boundaries.
