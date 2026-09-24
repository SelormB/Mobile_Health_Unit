# Mobile Health Unit Data Systems Assessment

Weld County Department of Public Health and Environment (DPHE), Greeley, Colorado

This repository holds the working files for a data quality assessment of the Weld County DPHE Mobile Health Unit (MHU). The assessment covers the three divisions that operate the unit: Public Health Services (PHS), Community Health (CH), and Environmental Health (EH). The goal is to assess, standardize, and improve how MHU data are collected and reported, and to produce an external-facing dashboard built on verified data.

The assessment is organized around the Federal Committee on Statistical Methodology (FCSM) Framework for Data Quality (2020), applied across its 11 dimensions.

## Project phases

| Phase | Output | Status |
|---|---|---|
| Phase 1 | Data Quality Assessment report: 17 SAS figures, 5 joint displays, 16 recommendations | Complete |
| Phase 2 | Recommendations report: implementation detail for all 16 recommendations, data dictionary, external benchmarking, summary table | Complete |
| Phase 3 | External Tableau dashboard | Complete |

## Repository contents

| Item | Description |
|---|---|
| `Phase_One.pdf` | Phase 1 Data Quality Assessment report |
| `Phase_2.pdf` | Phase 2 Recommendations report |
| `Phase_3/` | Dashboard materials and supporting data |
| `SAS result/` | SAS programs and output behind the Phase 1 figures and tables |
| `Interview questions/` | Interview guides used with division staff |
| `MHU_Merged_2025_2026 (1).xlsx` | Merged MHU event data across divisions, 2025 to 2026 |
| `MHU_Logic_Model.docx` | MHU program logic model |
| `MHU_Executive.pptx` | Executive briefing slides |
| `FCSM.20.04_A_Framework_for_Data_Quality.pdf` | FCSM data quality framework (reference) |
| `cdc_157018_DS1.pdf` | CDC reference document (reference) |

## Methods

Quantitative analysis was done in SAS. Qualitative data came from structured interviews with staff in all three divisions and were coded with a 26-code codebook mapped to the FCSM framework. Quantitative and qualitative findings are integrated through joint displays in the Phase 1 report.

Community context uses the CDC/ATSDR Social Vulnerability Index (SVI). Tract-level SVI values are joined to MHU events at the region level using population-weighted regional means. Because this is a region-level join and not tract-level geocoding, SVI results describe the areas the unit visits, not the individuals it serves. This ecological limitation applies to every SVI figure in this repository and in the dashboard.

## Standard variable definitions

These definitions were confirmed by all three divisions in August 2026 and apply to all data from that point forward.

**Engagement.** Counted per individual. A family of four is four engagements.

**People served.** Any individual who receives a direct service (STI testing, immunization, A1c, health screening, blood lead test). Education or outreach alone does not count. Each division counts separately; overlap across divisions is expected.

**Staff hours.** Total hours, including travel, vehicle checks, and setup and breakdown.

**Attendance.** Three levels: Did not attend, Outreach Only, Service and Outreach.

**Blank cells.** A blank cell means the service was not offered. Do not enter zero.

Division-specific measures: STI testing is PHS only, blood lead testing is EH only, and health screenings are CH only.

## Tools

SAS (analysis), Tableau (dashboard), LaTeX (report production), Python and Excel (data auditing).

## Author

Selorm Buaka, M.S.
Statistical Intern, Weld County DPHE
Applied Statistics and Research Methods, University of Northern Colorado

## Use

These materials were produced for Weld County DPHE. Contact the author before reusing the data or findings.
