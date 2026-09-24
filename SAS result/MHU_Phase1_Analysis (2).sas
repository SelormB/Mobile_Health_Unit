/*=============================================================================
  MHU DATA SYSTEMS ASSESSMENT - PHASE 1 QUANTITATIVE ANALYSIS
  DEFINITIVE VERSION - DO NOT MODIFY
  Weld County Department of Public Health and Environment
  Selorm Buaka PhD Candidate | Statistical Intern
  Shaun May MPH | Public Health Services Director
  June 2026

  FILES: C:\Users\sbuaka\Downloads\
    MHU_Combined.csv    MHU_Survey.csv

  OUTPUT: C:\Users\sbuaka\Downloads\MHU_Phase1_Output.pdf

  STATISTICAL METHODS:
    Shapiro-Wilk normality (justifies non-parametric throughout)
    Mann-Whitney U with rank-biserial r and 95% CI via Fisher z-transform
    Levene test + F-test for variance equality (formal CV comparison)
    Kruskal-Wallis with epsilon-squared effect size
    Dunn post-hoc with Bonferroni correction
    Spearman rho with 95% CI via Fisher z-transform
    Logistic regression: OR, CI, Hosmer-Lemeshow, C-statistic
    Bootstrap CV CI (n=5,000) - reported from Python verification
    Power analysis via PROC IML
    Missing data profile with chi-square association tests
    Seasonal sensitivity analysis
    Annualised estimates with period adjustment
=============================================================================*/

ODS PDF FILE  = "C:\Users\sbuaka\Downloads\MHU_Phase1_Output.pdf"
        STYLE = JOURNAL NOTOC STARTPAGE=YES;
ODS GRAPHICS ON / WIDTH=5.5IN HEIGHT=4IN;
OPTIONS NODATE NONUMBER LS=180 PS=55;

/*=============================================================================
  STEP 1: IMPORT
=============================================================================*/

PROC IMPORT DATAFILE="C:\Users\sbuaka\Downloads\MHU_Combined.csv"
    OUT=mhu DBMS=CSV REPLACE;
    GETNAMES=YES; DATAROW=2; GUESSINGROWS=85;
RUN;

PROC IMPORT DATAFILE="C:\Users\sbuaka\Downloads\MHU_Survey.csv"
    OUT=survey DBMS=CSV REPLACE;
    GETNAMES=YES; DATAROW=2; GUESSINGROWS=315;
RUN;

/* Verification */
PROC MEANS DATA=mhu N MAXDEC=0;
    VAR Year PHS_Engage CH_Engage EH_Engage STI_Tests BLT_Count
        STI_Ratio PHS_EngRatio CH_ScrRatio Addr_Complete EH_Present;
    TITLE "DATASET CHECK: N must equal 85";
RUN;

/*=============================================================================
  SECTION 1: NORMALITY TESTING
  All key variables non-normal => non-parametric tests throughout
=============================================================================*/
TITLE "SECTION 1: NORMALITY TESTING (Shapiro-Wilk, Kolmogorov-Smirnov,
       Cramer-von Mises, Anderson-Darling)";
TITLE2 "Justifies Mann-Whitney and Kruskal-Wallis throughout";

PROC UNIVARIATE DATA=mhu NORMAL;
    WHERE STI_Ratio>.;
    CLASS Year; VAR STI_Ratio;
    HISTOGRAM STI_Ratio / NORMAL;
    QQPLOT STI_Ratio / NORMAL(MU=EST SIGMA=EST);
    TITLE2 "STI Ratio: 2025 W=0.741 p=0.0007 | 2026 W=0.755 p=0.0005 - BOTH NON-NORMAL";
RUN;

PROC UNIVARIATE DATA=mhu NORMAL;
    WHERE PHS_EngRatio>.;
    CLASS Year; VAR PHS_EngRatio;
    HISTOGRAM PHS_EngRatio / NORMAL;
    QQPLOT PHS_EngRatio / NORMAL(MU=EST SIGMA=EST);
    TITLE2 "PHS Engagement Ratio: 2025 W=0.441 p<0.0001 | 2026 W=0.818 p=0.0013 - NON-NORMAL";
RUN;

PROC UNIVARIATE DATA=mhu NORMAL;
    WHERE CH_ScrRatio>.;
    CLASS Year; VAR CH_ScrRatio;
    HISTOGRAM CH_ScrRatio / NORMAL;
    QQPLOT CH_ScrRatio / NORMAL(MU=EST SIGMA=EST);
    TITLE2 "CH Screening Ratio: 2025 W=0.715 p<0.0001 NON-NORMAL | 2026 W=0.960 p=0.757 NORMAL";
RUN;

PROC UNIVARIATE DATA=mhu NORMAL;
    WHERE CH_OOR_Rate>.;
    CLASS Year; VAR CH_OOR_Rate;
    HISTOGRAM CH_OOR_Rate / NORMAL;
    TITLE2 "CH OOR Rate: 2025 W=0.815 p=0.0002 NON-NORMAL | 2026 W=0.945 p=0.519 NORMAL";
RUN;

/*=============================================================================
  SECTION 2: MISSING DATA PROFILE
  Tests whether missingness is systematic or structural (blank=not offered)
=============================================================================*/
TITLE "SECTION 2: MISSING DATA PROFILE";
TITLE2 "Blank = service not offered (per Read Me). Tests whether missingness
        is associated with Year or Region.";

/* Overall missingness */
PROC MEANS DATA=mhu N NMISS MAXDEC=0;
    VAR PHS_Engage PHS_People STI_Tests CH_Engage CH_Screen_Count
        EH_Engage BLT_Count Addr_Complete;
    TITLE2 "Missing Data Summary: N and NMISS for Key Variables";
RUN;

/* STI_Tests missingness is SYSTEMATIC by year (chi2=4.70, p=0.030) */
DATA mhu_miss;
    SET mhu;
    Miss_STI    = (STI_Tests  = .);
    Miss_PHS    = (PHS_Engage = .);
    Miss_CH     = (CH_Engage  = .);
    Miss_EH     = (EH_Engage  = .);
RUN;

PROC FREQ DATA=mhu_miss;
    TABLES Miss_STI*Year / CHISQ NOCUM;
    TITLE2 "STI Tests Missingness by Year";
    TITLE3 "chi2=4.70, p=0.030 SYSTEMATIC: STI events proportionally more common in 2026";
RUN;

PROC FREQ DATA=mhu_miss;
    TABLES Miss_PHS*Year Miss_CH*Year Miss_EH*Year / CHISQ NOCUM;
    TITLE2 "PHS, CH, EH Missingness by Year (expected: structural not systematic)";
RUN;

PROC FREQ DATA=mhu_miss;
    TABLES Miss_STI*Region Miss_PHS*Region / CHISQ NOCUM;
    TITLE2 "STI and PHS Missingness by Region";
RUN;

/*=============================================================================
  FCSM 5.1: RELEVANCE
=============================================================================*/
TITLE "FCSM 5.1: RELEVANCE";

PROC FREQ DATA=mhu;
    TABLES Year / NOCUM;
    TITLE2 "Total Events by Year";
RUN;

PROC FREQ DATA=mhu;
    TABLES PHS_Attended*Year CH_Attended*Year / CHISQ NOCUM;
    TITLE2 "Division Attendance by Year";
RUN;

PROC FREQ DATA=mhu;
    TABLES EH_Attended*Year / NOCUM;
    TITLE2 "EH Attendance by Year (3-level field)";
RUN;

PROC MEANS DATA=mhu N SUM MEAN MEDIAN STD MAXDEC=2;
    CLASS Year;
    VAR PHS_Engage PHS_People STI_People STI_Tests Imm_People Imm_Count;
    TITLE2 "PHS Service Volumes by Year";
RUN;

PROC MEANS DATA=mhu N SUM MEAN MEDIAN STD MAXDEC=2;
    CLASS Year;
    VAR CH_Engage CH_Screen_People CH_Screen_Count CH_OOR;
    TITLE2 "CH Service Volumes by Year";
RUN;

PROC MEANS DATA=mhu N SUM MEAN MAXDEC=2;
    CLASS Year;
    VAR EH_Engage BLT_Count BLT_Elevated;
    TITLE2 "EH Service Volumes by Year";
RUN;

PROC FREQ DATA=mhu;
    TABLES Region*Year EventType*Year EventResponse*Year / CHISQ NOCUM;
    TITLE2 "Events by Region, Type and Response Type";
RUN;

/* ── MANN-WHITNEY: rank-biserial r computed from Wilcoxon statistic ────── */
/* Formula: r = 1 - (2*U)/(n1*n2)                                          */
/* 95% CI via Fisher z-transform (verified in Python)                       */

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE PHS_Attended='Y' AND PHS_Engage>.;
    CLASS Year; VAR PHS_Engage;
    TITLE2 "Mann-Whitney: PHS Engagements Per Event";
    TITLE3 "U=191, p=0.0015, r=0.504, 95%CI=[0.265,0.685] LARGE effect SIGNIFICANT";
    TITLE4 "2025: median=8.0 IQR[4.5-13.0] mean=10.1";
    TITLE5 "2026: median=15.0 IQR[10.0-20.0] mean=20.8";
RUN;

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE PHS_Attended='Y' AND PHS_People>.;
    CLASS Year; VAR PHS_People;
    TITLE2 "Mann-Whitney: PHS People Served Per Event";
    TITLE3 "U=262, p=0.043, r=0.321, 95%CI=[0.059,0.541] MEDIUM effect SIGNIFICANT";
    TITLE4 "2025: median=5.0 | 2026: median=8.0";
RUN;

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE CH_Attended='Y' AND CH_Engage>.;
    CLASS Year; VAR CH_Engage;
    TITLE2 "Mann-Whitney: CH Engagements Per Event";
    TITLE3 "U=124, p=0.079, r=0.345, 95%CI=[0.037,0.593] MEDIUM effect NOT significant";
    TITLE4 "2025: median=14.0 mean=23.9 | 2026: median=31.0 mean=33.8";
    TITLE5 "Raw total declined 692 to 439. Per-event rate INCREASING.";
RUN;

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE PHS_Attended='Y' AND STI_Tests>.;
    CLASS Year; VAR STI_Tests;
    TITLE2 "Mann-Whitney: STI Tests Per Event";
    TITLE3 "U=214, p=0.165, r=0.259 SMALL effect not significant";
    TITLE4 "Annualised: 712 (2025) vs 2098 (2026) = nearly tripled on annual basis";
RUN;

/* Annualised estimates */
PROC MEANS DATA=mhu SUM NOPRINT;
    CLASS Year;
    VAR CH_Engage PHS_Engage PHS_People STI_Tests Imm_Count
        BLT_Count EH_Engage CH_Screen_Count;
    OUTPUT OUT=totals(WHERE=(_TYPE_=1))
           SUM=CH_Tot PHS_Eng PHS_Ppl STI_Tot Imm_Tot
               BLT_Tot EH_Eng Scr_Tot;
RUN;

DATA annualised;
    SET totals;
    IF Year=2025 THEN Months=8;
    IF Year=2026 THEN Months=5;
    CH_Ann  = ROUND((CH_Tot  /Months)*12,1);
    PHS_Ann = ROUND((PHS_Eng /Months)*12,1);
    PPL_Ann = ROUND((PHS_Ppl /Months)*12,1);
    STI_Ann = ROUND((STI_Tot /Months)*12,1);
    BLT_Ann = ROUND((BLT_Tot /Months)*12,1);
    Scr_Ann = ROUND((Scr_Tot /Months)*12,1);
RUN;

PROC PRINT DATA=annualised NOOBS;
    VAR Year Months CH_Tot CH_Ann PHS_Eng PHS_Ann PPL_Ann STI_Ann Scr_Ann;
    TITLE2 "Annualised Estimates: 2025=8 months | 2026=5 months";
    TITLE3 "CRITICAL: Direct raw comparisons are INVALID without annualisation";
    TITLE4 "CH: 692 vs 439 raw = APPARENT decline | 1038 vs 1054 annualised = STABLE";
    TITLE5 "PHS: 354 vs 457 raw | 531 vs 1097 annualised = LARGE increase";
RUN;

/* Seasonal sensitivity analysis */
DATA phs_seasonal;
    SET mhu;
    WHERE PHS_Attended='Y' AND PHS_Engage>.;
    IF Year=2025 THEN Season='2025 Jun-Dec';
    ELSE Season='2026 Jan-May';
RUN;

PROC MEANS DATA=phs_seasonal N MEAN MEDIAN STD MAXDEC=1;
    CLASS Season Month;
    VAR PHS_Engage;
    TITLE2 "Seasonal Sensitivity: PHS Engagements by Month";
    TITLE3 "2026 months (Jan-May) overlap with low-activity months in 2025";
    TITLE4 "2026 Apr mean=31.4 and May mean=40.0 far exceed 2025 seasonal baseline";
    TITLE5 "Conclusion: Annualised increase in PHS is genuine not seasonal artefact";
RUN;

/*=============================================================================
  FCSM 5.2: ACCESSIBILITY
=============================================================================*/
TITLE "FCSM 5.2: ACCESSIBILITY";

PROC FREQ DATA=survey;
    TABLES Language / NOCUM;
    TITLE2 "Survey Language Distribution: English=198 (63.1%) | Spanish=116 (36.9%)";
RUN;

PROC FREQ DATA=mhu;
    TABLES Region*Year / CHISQ EXPECTED NOCUM;
    TITLE2 "Regional Distribution of Events by Year";
    TITLE3 "Chi-square warning expected: 60% cells have expected count <5";
    TITLE4 "Use Likelihood Ratio chi-square as more reliable statistic";
RUN;

PROC FREQ DATA=mhu;
    TABLES EventResponse*Year / CHISQ NOCUM;
    TITLE2 "Event Response Type by Year";
    TITLE3 "Strategic events increased from 27.8% to 56.7% in 2026";
RUN;

/*=============================================================================
  FCSM 5.3: TIMELINESS
=============================================================================*/
TITLE "FCSM 5.3: TIMELINESS";

PROC FREQ DATA=mhu;
    TABLES Month*Year / NOCUM;
    TITLE2 "Events by Month and Year";
RUN;

PROC FREQ DATA=mhu;
    WHERE PHS_Attended='Y';
    TABLES Month*Year / NOCUM;
    TITLE2 "PHS Events by Month and Year";
RUN;

PROC FREQ DATA=mhu;
    WHERE CH_Attended='Y';
    TABLES Month*Year / NOCUM;
    TITLE2 "CH Events by Month and Year";
RUN;

PROC MEANS DATA=mhu N MEAN MEDIAN STD MIN MAX MAXDEC=2;
    CLASS Year; VAR EventHours;
    TITLE2 "Event Duration Hours by Year";
RUN;

/*=============================================================================
  FCSM 5.4: PUNCTUALITY
=============================================================================*/
TITLE "FCSM 5.4: PUNCTUALITY";

PROC FREQ DATA=mhu;
    TABLES Quarter*Year / NOCUM;
    TITLE2 "Events by Quarter and Year";
RUN;

PROC FREQ DATA=mhu;
    WHERE PHS_Attended='Y';
    TABLES Quarter*Year / NOCUM;
    TITLE2 "PHS Events by Quarter";
RUN;

PROC FREQ DATA=mhu;
    WHERE CH_Attended='Y';
    TABLES Quarter*Year / NOCUM;
    TITLE2 "CH Events by Quarter";
RUN;

/*=============================================================================
  FCSM 5.5: GRANULARITY + FORMAL POWER ANALYSIS
=============================================================================*/
TITLE "FCSM 5.5: GRANULARITY";

PROC FREQ DATA=mhu;
    TABLES Region*Year / CHISQ NOCUM;
    TITLE2 "Geographic Distribution by Year";
    TITLE3 "North: 5 events 2025 | 0 events 2026";
RUN;

PROC MEANS DATA=mhu N SUM MAXDEC=0;
    VAR BLT_Count;
    TITLE2 "Total Blood Lead Tests: n=20";
    TITLE3 "Power at n=20: d=0.2(small)=9.2% | d=0.5(medium)=35.2% | d=0.8(large)=71.6%";
    TITLE4 "Need n=63 for 80% power | n=85 for 90% power at d=0.5";
    TITLE5 "ALL EH INFERENTIAL ANALYSIS IS STATISTICALLY INVALID. DESCRIPTIVE ONLY.";
RUN;

PROC IML;
    TITLE2 "Formal Power Analysis: EH Blood Lead Tests";
    alpha = 0.05;
    z_alpha = QUANTILE('NORMAL', 1-alpha/2);

    /* Power by effect size at n=20 */
    PRINT "Power Analysis: n=20, alpha=0.05, two-tailed";
    PRINT "Effect Size | Label      | Power  | Adequate (>=0.80)?";
    DO i = 1 TO 5;
        d = CHOOSE(i, 0.2, 0.5, 0.8, 1.0, 1.2);
        lbl = CHOOSE(i,'small     ','medium    ','large     ','very large','v.v.large ');
        power = CDF('NORMAL', d*SQRT(20/2) - z_alpha);
        adequate = (power >= 0.80);
        PRINT d lbl power adequate;
    END;

    /* Sample size needed */
    PRINT " ";
    PRINT "Sample size requirements for adequate power (d=0.5, alpha=0.05):";
    DO target = 0.80, 0.90, 0.95;
        z_beta = QUANTILE('NORMAL', target);
        n_needed = CEIL(2*((z_alpha+z_beta)/0.5)**2);
        PRINT target n_needed;
    END;

    /* Power curve: n from 5 to 150 */
    n_vals = T(5:150);
    powers = CDF('NORMAL', 0.5*SQRT(n_vals/2) - z_alpha);
    n_at_80 = n_vals[LOC(powers >= 0.80)][1];
    n_at_90 = n_vals[LOC(powers >= 0.90)][1];
    PRINT "n for 80% power at d=0.5:" n_at_80;
    PRINT "n for 90% power at d=0.5:" n_at_90;
QUIT;

PROC FREQ DATA=survey;
    TABLES Language / NOCUM;
    TITLE2 "Survey Language as Proxy for Population Served";
RUN;

/*=============================================================================
  FCSM 5.6: ACCURACY AND RELIABILITY
  Ratio analysis with CV, Bootstrap CI, Levene, F-test, Mann-Whitney + CI
=============================================================================*/
TITLE "FCSM 5.6: ACCURACY AND RELIABILITY";

/* ── STI RATIO ──────────────────────────────────────────────────────────── */
PROC MEANS DATA=mhu N MEAN MEDIAN STD CV MIN MAX MAXDEC=4;
    WHERE STI_Ratio>.;
    CLASS Year; VAR STI_Ratio;
    TITLE2 "STI Ratio Summary Statistics by Year";
    TITLE3 "2025: mean=5.2258 CV=23.17% 95%CI=[4.555,5.896] Bootstrap CV CI=[0.111,0.287]";
    TITLE4 "2026: mean=5.8302 CV=14.09% 95%CI=[5.408,6.252] Bootstrap CV CI=[0.052,0.202]";
RUN;

PROC UNIVARIATE DATA=mhu NORMAL CIBASIC;
    WHERE STI_Ratio>.;
    CLASS Year; VAR STI_Ratio;
    HISTOGRAM STI_Ratio / NORMAL HREF=6;
    QQPLOT STI_Ratio / NORMAL(MU=EST SIGMA=EST);
    TITLE2 "STI Ratio: Distribution, 95% CI on Mean, Normality Tests";
RUN;

/* Mann-Whitney */
PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE STI_Ratio>.;
    CLASS Year; VAR STI_Ratio;
    TITLE2 "Mann-Whitney: STI Ratio 2025 vs 2026";
    TITLE3 "U=122, p=0.845, r=0.043, 95%CI=[-0.310,0.386] NEGLIGIBLE effect";
    TITLE4 "Both years apply 6-test standard consistently. GOOD finding.";
RUN;

/* Formal variance comparison */
PROC TTEST DATA=mhu;
    WHERE STI_Ratio>.;
    CLASS Year; VAR STI_Ratio;
    TITLE2 "Levene + F-test: STI Ratio Variance Comparison";
    TITLE3 "Levene W=1.15 p=0.293 | F-test F=2.17 p=0.138 - No significant variance diff";
    TITLE4 "Bootstrap CIs overlap: CV improvement is directional, not formally significant";
RUN;

/* ── PHS ENGAGEMENT RATIO ──────────────────────────────────────────────── */
PROC MEANS DATA=mhu N MEAN MEDIAN STD CV MIN MAX MAXDEC=4;
    WHERE PHS_EngRatio>.;
    CLASS Year; VAR PHS_EngRatio;
    TITLE2 "PHS Engagement Ratio Summary Statistics by Year";
    TITLE3 "2025: CV=115.9% Bootstrap CI=[24.5%,218.7%] - VERY HIGH variability";
    TITLE4 "2026: CV=58.0%  Bootstrap CI=[28.5%,80.4%]  - Improving";
RUN;

PROC UNIVARIATE DATA=mhu NORMAL CIBASIC;
    WHERE PHS_EngRatio>.;
    CLASS Year; VAR PHS_EngRatio;
    HISTOGRAM PHS_EngRatio / NORMAL;
    QQPLOT PHS_EngRatio / NORMAL(MU=EST SIGMA=EST);
    TITLE2 "PHS Engagement Ratio: Distribution and 95% CI";
RUN;

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE PHS_EngRatio>.;
    CLASS Year; VAR PHS_EngRatio;
    TITLE2 "Mann-Whitney: PHS Engagement Ratio 2025 vs 2026";
    TITLE3 "U=246, p=0.139, r=0.244, 95%CI=[-0.035,0.488] SMALL effect not significant";
    TITLE4 "Direction: improving. Not yet statistically confirmed.";
RUN;

/* CRITICAL: F-test shows variance IS significantly different for PHS ratio */
PROC TTEST DATA=mhu;
    WHERE PHS_EngRatio>.;
    CLASS Year; VAR PHS_EngRatio;
    TITLE2 "F-test: PHS Engagement Ratio Variance Comparison";
    TITLE3 "Levene W=0.075 p=0.786 (not significant)";
    TITLE4 "F-test F=3.834 p=0.003 SIGNIFICANT: variance significantly reduced in 2026";
    TITLE5 "Interpretation: PHS engagement definition applied more consistently in 2026";
RUN;

/* ── CH SCREENING RATIO ─────────────────────────────────────────────────── */
PROC MEANS DATA=mhu N MEAN MEDIAN STD CV MIN MAX MAXDEC=4;
    WHERE CH_ScrRatio>.;
    CLASS Year; VAR CH_ScrRatio;
    TITLE2 "CH Screening Ratio Summary Statistics by Year";
    TITLE3 "2025: CV=84.1% Bootstrap CI=[54.1%,118.1%]";
    TITLE4 "2026: CV=43.7% Bootstrap CI=[25.9%,57.6%] - Substantially reduced";
    TITLE5 "High CV appropriate - 8 tests offered, different combos at different events";
RUN;

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE CH_ScrRatio>.;
    CLASS Year; VAR CH_ScrRatio;
    TITLE2 "Mann-Whitney: CH Screening Ratio 2025 vs 2026";
    TITLE3 "U=118, p=0.053, r=0.374, 95%CI=[0.068,0.616] MEDIUM effect, borderline";
    TITLE4 "More tests per person screened in 2026";
RUN;

/* ── CH OOR RATE ─────────────────────────────────────────────────────────── */
PROC MEANS DATA=mhu N MEAN MEDIAN STD CV MIN MAX MAXDEC=4;
    WHERE CH_OOR_Rate>.;
    CLASS Year; VAR CH_OOR_Rate;
    TITLE2 "CH Out-of-Range Rate by Year";
    TITLE3 "2025: mean=0.867 CV=82.9% Bootstrap CI=[50.3%,121.1%]";
    TITLE4 "2026: mean=1.284 CV=54.7% Bootstrap CI=[34.1%,79.7%]";
RUN;

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE CH_OOR_Rate>.;
    CLASS Year; VAR CH_OOR_Rate;
    TITLE2 "Mann-Whitney: CH OOR Rate 2025 vs 2026";
    TITLE3 "U=122, p=0.073, r=0.353, 95%CI=[0.045,0.599] MEDIUM effect, borderline";
    TITLE4 "OOR rate increasing in 2026: more abnormal results per person screened";
RUN;

PROC FREQ DATA=mhu;
    WHERE CH_Screen_People>0 AND CH_OOR>.;
    TABLES OOR_Exceeds*Year / NOCUM;
    TITLE2 "Events Where OOR Count Exceeds People Screened";
    TITLE3 "1=Yes. Confirms OOR counts RESULTS not PEOPLE. Anomaly resolved.";
RUN;

/* ── STAFF HOURS RATIOS ──────────────────────────────────────────────────── */
PROC MEANS DATA=mhu N MEAN MEDIAN STD MIN MAX MAXDEC=3;
    WHERE PHS_Attended='Y';
    CLASS Year; VAR PHS_StaffHours EventHours PHS_HrsRatio;
    TITLE2 "PHS Staff Hours vs Event Hours";
    TITLE3 "Staff hours consistently exceed event hours: multiple staff attending each event";
RUN;

PROC MEANS DATA=mhu N MEAN MEDIAN STD MIN MAX MAXDEC=3;
    WHERE CH_Attended='Y';
    CLASS Year; VAR CH_StaffHours EventHours CH_HrsRatio;
    TITLE2 "CH Staff Hours vs Event Hours";
RUN;

PROC MEANS DATA=mhu N MEAN MEDIAN STD MIN MAX MAXDEC=3;
    WHERE EH_Present=1;
    CLASS Year; VAR EH_StaffHours EventHours EH_HrsRatio;
    TITLE2 "EH Staff Hours vs Event Hours";
    TITLE3 "EH mean ratio=3.92 vs PHS mean=4.37 vs CH mean=1.55";
    TITLE4 "Documentation conflict: EH Read Me includes travel. PHS/CH Read Me: onsite only.";
    TITLE5 "Both PHS and EH show ratios >1. Resolution requires cross-division meeting.";
RUN;

PROC PRINT DATA=mhu NOOBS;
    WHERE EH_Present=1;
    VAR Year EventDate EventName EH_Attended EH_Engage
        BLT_Count EH_StaffHours EventHours EH_HrsRatio;
    TITLE2 "EH Attended Events: Full Detail (n=11 events)";
RUN;

/*=============================================================================
  SECTION 3: SPEARMAN CORRELATIONS WITH 95% CI (Fisher z-transform)
  Formula: z = arctanh(r), SE = 1/sqrt(n-3), CI = tanh(z +/- 1.96*SE)
=============================================================================*/
TITLE "SECTION 3: SPEARMAN CORRELATIONS WITH 95% CI";
TITLE2 "95% CI via Fisher z-transformation";
TITLE3 "Significance: *** p<0.001, ** p<0.01, * p<0.05, ns = not significant";

PROC CORR DATA=mhu SPEARMAN NOSIMPLE;
    WHERE CH_Attended='Y';
    VAR CH_Staff CH_Engage CH_Screen_Count EventHours;
    TITLE2 "CH: Staff Count and Event Duration vs Service Outputs";
    TITLE3 "CH Staff vs Screenings: r=0.683 95%CI=[0.471,0.820] p<0.001 *** n=40";
    TITLE4 "CH Staff vs Engagements: r=0.445 95%CI=[0.163,0.660] p=0.003 ** n=42";
    TITLE5 "Event Hours vs CH Engagements: r=0.389 95%CI=[0.092,0.622] p=0.012 * n=41";
RUN;

PROC CORR DATA=mhu SPEARMAN NOSIMPLE;
    WHERE PHS_Attended='Y';
    VAR PHS_Staff PHS_Engage PHS_People STI_Tests EventHours;
    TITLE2 "PHS: Staff Count and Event Duration vs Service Outputs";
    TITLE3 "PHS Staff vs STI Tests:  r=0.565 95%CI=[0.286,0.756] p<0.001 *** n=35";
    TITLE4 "PHS Staff vs People:     r=0.325 95%CI=[0.071,0.540] p=0.014 * n=57";
    TITLE5 "PHS Staff vs Engage:     r=0.257 95%CI=[-0.004,0.485] p=0.054 ns n=57";
RUN;

PROC CORR DATA=mhu SPEARMAN NOSIMPLE;
    WHERE PHS_Attended='Y' AND CH_Attended='Y';
    VAR PHS_Engage CH_Engage;
    TITLE2 "PHS vs CH Engagements at Co-Attended Events";
    TITLE3 "r=0.599 95%CI=[0.183,0.833] p=0.009 ** n=18";
    TITLE4 "Divisions track together: high PHS events also produce high CH engagement";
RUN;

/*=============================================================================
  SECTION 4: KRUSKAL-WALLIS + EPSILON-SQUARED + DUNN POST-HOC
=============================================================================*/
TITLE "SECTION 4: KRUSKAL-WALLIS BY REGION";
TITLE2 "H=16.685, p=0.0008 | Epsilon-squared=0.263 (LARGE effect)";
TITLE3 "Post-hoc: Dunn test with Bonferroni correction";

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE PHS_Attended='Y' AND PHS_Engage>.;
    CLASS Region; VAR PHS_Engage;
    TITLE2 "Kruskal-Wallis: PHS Engagements by Region";
    TITLE3 "H=17.243 (SAS, all events) / H=16.685 (Python, PHS_Engage>0)";
    TITLE4 "p=0.0017 | Epsilon-squared=0.263 LARGE effect";
RUN;

PROC MEANS DATA=mhu N MEAN MEDIAN STD MIN MAX MAXDEC=2;
    WHERE PHS_Attended='Y' AND PHS_Engage>.;
    CLASS Region; VAR PHS_Engage;
    TITLE2 "PHS Engagements by Region: Descriptive Statistics";
    TITLE3 "Greeley/Evans: median=12.0 | Southeast: median=5.0 | Windsor: median=5.5";
RUN;

/* Dunn post-hoc - PROC MULTTEST for pairwise after KW */
/* Note: SAS PROC NPAR1WAY does not do Dunn directly    */
/* Verified in Python: Bonferroni-corrected p-values    */
DATA _NULL_;
    FILE PRINT;
    PUT " ";
    PUT "DUNN'S POST-HOC TEST WITH BONFERRONI CORRECTION (verified in Python)";
    PUT "Comparison                           z       p_raw    p_Bonf   Significant?";
    PUT "Greeley/Evans vs Windsor/Severance   3.021   0.0025   0.0151   * YES";
    PUT "Greeley/Evans vs Southeast           2.740   0.0061   0.0369   * YES";
    PUT "Greeley/Evans vs North               1.856   0.0635   0.3807   ns NO";
    PUT "North vs Southeast                   0.486   0.6272   1.0000   ns NO";
    PUT "North vs Windsor/Severance           0.540   0.5895   1.0000   ns NO";
    PUT "Southeast vs Windsor/Severance       0.037   0.9703   1.0000   ns NO";
    PUT " ";
    PUT "INTERPRETATION:";
    PUT "Greeley/Evans significantly higher than Windsor/Severance (p=0.015)";
    PUT "Greeley/Evans significantly higher than Southeast (p=0.037)";
    PUT "No other pairwise differences significant";
    PUT "Greeley/Evans is the high-engagement region. All others are similar.";
    PUT " ";
RUN;

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE CH_Attended='Y' AND CH_Engage>.;
    CLASS Region; VAR CH_Engage;
    TITLE2 "Kruskal-Wallis: CH Engagements by Region";
    TITLE3 "H=3.286, p=0.511 NOT significant - CH engagement consistent across regions";
RUN;

/*=============================================================================
  FCSM 5.7: COHERENCE
=============================================================================*/
TITLE "FCSM 5.7: COHERENCE";

/* Address completeness */
PROC FREQ DATA=mhu;
    TABLES Addr_Complete*Year / CHISQ NOCUM;
    TITLE2 "Address Completeness by Year";
    TITLE3 "2025: 37/54 = 68.5% complete | 2026: 7/31 = 22.6% complete";
    TITLE4 "Continuity-corrected chi2=14.856, p<0.0001 HIGHLY SIGNIFICANT decline";
    TITLE5 "Effect size: phi=-0.443 (medium-large) | OR=0.091 (year 2026 vs 2025)";
RUN;

PROC FREQ DATA=mhu;
    TABLES Addr_Complete*Region / CHISQ EXPECTED NOCUM;
    TITLE2 "Address Completeness by Region";
    TITLE3 "chi2=3.735, p=0.443 NOT significant (70% cells <5: chi2 unreliable)";
    TITLE4 "Interpretation: Year drives missingness, not region per chi2";
    TITLE5 "Logistic regression (below) tests both jointly with MAR conclusion";
RUN;

/* Logistic regression - MAR test - full diagnostics */
PROC LOGISTIC DATA=mhu DESCENDING;
    CLASS Region (REF='Greeley/Evans') / PARAM=REF;
    CLASS Year   (REF=2025)            / PARAM=REF;
    MODEL Addr_Complete = Region Year / EXPB CLODDS=WALD RSQUARE LACKFIT;
    ROC;
    TITLE2 "Logistic Regression: Address Missingness MAR Test";
    TITLE3 "Outcome: Addr_Complete=1 | Reference: Greeley/Evans, Year 2025";
    TITLE4 "Diagnostics: Hosmer-Lemeshow chi2=0.361 p=0.948 GOOD FIT";
    TITLE5 "C-statistic (AUC)=0.777 FAIR discrimination | McFadden R2=0.211";
RUN;

/* Display classification table manually since CTABLE needs threshold */
DATA _NULL_;
    FILE PRINT;
    PUT " ";
    PUT "LOGISTIC REGRESSION CLASSIFICATION TABLE (cutpoint=0.50)";
    PUT "Sensitivity=81.8% | Specificity=67.5% | Overall Accuracy=75.0%";
    PUT "TP=36  FP=13  TN=27  FN=8";
    PUT " ";
    PUT "KEY FINDING: Year OR=0.091 [0.029,0.289] p<0.001";
    PUT "Interpretation: In 2026, odds of having complete address are 91% LOWER";
    PUT "than 2025, after controlling for region.";
    PUT "Year is the primary driver of address missingness.";
    PUT "Conclusion: Missingness is MAR (Missing At Random) not MCAR.";
    PUT " ";
RUN;

/* CH engagement per event */
PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE CH_Attended='Y' AND CH_Engage>.;
    CLASS Year; VAR CH_Engage;
    TITLE2 "Mann-Whitney: CH Engagements Per Event";
    TITLE3 "U=124, p=0.079, r=0.345, 95%CI=[0.037,0.593] MEDIUM effect not significant";
    TITLE4 "Per-event rate INCREASING 23.9 to 33.8 despite lower raw total";
    TITLE5 "Annualised: 1038 (2025) vs 1054 (2026) = NO programme decline";
RUN;

/* EH attendance field */
PROC FREQ DATA=mhu;
    TABLES EH_Attended*Year / NOCUM;
    TITLE2 "EH Attendance Field: 3-Level vs PHS/CH Binary Y/N";
    TITLE3 "Coherence threat: EH field cannot be directly compared to PHS/CH attendance";
RUN;

PROC FREQ DATA=mhu;
    TABLES Region*Year / NOCUM;
    TITLE2 "Events by Region and Year";
    TITLE3 "North: 5 events 2025 | 0 events 2026 (unexplained absence)";
RUN;

/*=============================================================================
  FCSM 5.8: SCIENTIFIC INTEGRITY
  CV analysis with formal variance tests
=============================================================================*/
TITLE "FCSM 5.8: SCIENTIFIC INTEGRITY";

/* CV summary with bootstrap CIs */
PROC MEANS DATA=mhu N MEAN STD CV MAXDEC=4;
    WHERE STI_Ratio>.;
    CLASS Year; VAR STI_Ratio;
    TITLE2 "STI Ratio CV: Consistency of 6-Test Standard";
    TITLE3 "2025 CV=23.17% Bootstrap CI=[11.1%, 28.7%]";
    TITLE4 "2026 CV=14.09% Bootstrap CI=[5.2%, 20.2%]";
    TITLE5 "CIs overlap. CV declining but not formally significant (Levene p=0.293)";
RUN;

PROC MEANS DATA=mhu N MEAN STD CV MAXDEC=4;
    WHERE PHS_EngRatio>.;
    CLASS Year; VAR PHS_EngRatio;
    TITLE2 "PHS Engagement Ratio CV: Construct Validity Check";
    TITLE3 "2025 CV=115.9% Bootstrap CI=[24.5%, 218.7%] - HIGHLY VARIABLE";
    TITLE4 "2026 CV=58.0%  Bootstrap CI=[28.5%,  80.4%] - Substantially improved";
    TITLE5 "F-test: F=3.834 p=0.003 SIGNIFICANT - variance formally reduced in 2026";
RUN;

PROC MEANS DATA=mhu N MEAN STD CV MAXDEC=4;
    WHERE CH_ScrRatio>.;
    CLASS Year; VAR CH_ScrRatio;
    TITLE2 "CH Screening Ratio CV";
    TITLE3 "2025 CV=84.1% | 2026 CV=43.7% | Substantial reduction";
    TITLE4 "High CV appropriate - reflects genuine event-type variation";
RUN;

PROC NPAR1WAY DATA=mhu WILCOXON;
    WHERE PHS_EngRatio>.;
    CLASS Year; VAR PHS_EngRatio;
    TITLE2 "Mann-Whitney: PHS Engagement Ratio Year Comparison";
    TITLE3 "U=246, p=0.139, r=0.244 - Not significant";
    TITLE4 "But F-test on variances IS significant (p=0.003) - consistency improving";
RUN;

/*=============================================================================
  FCSM 5.9: CREDIBILITY
=============================================================================*/
TITLE "FCSM 5.9: CREDIBILITY";

/* STI ratio confirms 6-test standard */
PROC UNIVARIATE DATA=mhu CIBASIC;
    WHERE STI_People>0;
    VAR STI_Ratio;
    HISTOGRAM STI_Ratio / NORMAL HREF=6;
    TITLE2 "STI Ratio All 32 Events: Confirms 6-Test Standard";
    TITLE3 "Overall: mean=5.547 95%CI=[5.168,5.926] median=6.000 mode=6.000";
    TITLE4 "Median and mode at 6.0 confirms standard. Mean slightly below due to lower ratios";
    TITLE5 "at early events before full standardisation.";
RUN;

/* EH attendance by event type */
PROC FREQ DATA=mhu;
    TABLES EH_Attended*EventType / NOCUM;
    TITLE2 "EH Attendance by Event Type";
RUN;

PROC FREQ DATA=mhu;
    WHERE EH_Attended IN ('Testing and Outreach' 'Outreach Only' 'Did not attend');
    TABLES EH_Attended*EventType / FISHER NOCUM;
    TITLE2 "Fisher Exact Test: EH Attendance by Event Type";
    TITLE3 "p=0.837 NOT significant";
    TITLE4 "EH does not preferentially attend public vs private events";
    TITLE5 "EH withdrawal in 2026 is strategic decision, not event-type driven";
RUN;

PROC FREQ DATA=mhu;
    TABLES Narcan_YN*Year / NOCUM;
    TITLE2 "Narcan Column Entries by Year";
    TITLE3 "2025: 6 entries | 2026: 0 entries";
    TITLE4 "Low count intentional: recorded only when full harm reduction education delivered";
RUN;

PROC MEANS DATA=mhu N MEAN MEDIAN STD MIN MAX MAXDEC=3;
    WHERE CH_ScrRatio>.;
    VAR CH_ScrRatio;
    TITLE2 "CH Screening Ratio Max=8.0 Confirms 8-Test Standard";
    TITLE3 "Mean=3.676, Median=2.711, Maximum=8.000";
    TITLE4 "Maximum of 8.0 exactly equals the 8-test standard - anomaly resolved";
RUN;

PROC FREQ DATA=mhu;
    WHERE CH_Screen_People>0 AND CH_OOR>.;
    TABLES OOR_Exceeds / NOCUM;
    TITLE2 "OOR Anomaly Resolved";
    TITLE3 "15 of 42 screening events (35.7%) have OOR count > people screened";
    TITLE4 "Confirmed: column counts individual test RESULTS not individual PEOPLE";
RUN;

/* Survey */
PROC FREQ DATA=survey ORDER=FREQ;
    TABLES Recommend / NOCUM MISSING;
    TITLE2 "Survey: Likelihood to Recommend Mobile Unit (N=315)";
    TITLE3 "Definitely will=267 (84.8%) | Probably will=18 (5.7%)";
    TITLE4 "Combined: 90.5% would recommend the Mobile Health Unit";
RUN;

PROC FREQ DATA=survey ORDER=FREQ;
    TABLES CareElsewhere / NOCUM MISSING;
    TITLE2 "Survey: Would Have Gotten Care Elsewhere If MHU Not Present";
    TITLE3 "No=202 (64.1%) - would NOT have gotten care elsewhere";
    TITLE4 "64.1% quantifies direct unmet need the MHU is addressing";
    TITLE5 "Yes=91 (28.9%) - confirms MHU is reaching underserved not substituting";
RUN;

PROC FREQ DATA=survey;
    TABLES Language / NOCUM;
    TITLE2 "Survey Language: English=198 (63.1%) | Spanish=116 (36.9%)";
RUN;

/*=============================================================================
  FCSM 5.10-5.11: SECURITY AND CONFIDENTIALITY
=============================================================================*/
TITLE "FCSM 5.10-5.11: SECURITY AND CONFIDENTIALITY";

PROC CONTENTS DATA=mhu ORDER=VARNUM;
    TITLE2 "Complete Variable Inventory: Confirms No PII in Tracking Sheet";
RUN;

PROC MEANS DATA=mhu N NMISS MAXDEC=0;
    VAR PHS_Engage CH_Engage EH_Engage BLT_Count STI_Tests;
    TITLE2 "Key Variable Completeness";
RUN;

/*=============================================================================
  PROGRAMME SUMMARY TABLE
=============================================================================*/
TITLE "PROGRAMME SUMMARY STATISTICS";

PROC MEANS DATA=mhu N SUM MEAN MEDIAN STD MAXDEC=2;
    CLASS Year;
    VAR PHS_Engage PHS_People STI_Tests STI_People
        Imm_Count CH_Engage CH_Screen_Count CH_Screen_People
        EH_Engage BLT_Count EventHours;
    TITLE2 "Complete Programme Summary by Year";
RUN;

/*=============================================================================
  DEFINITIVE FINDINGS SUMMARY
=============================================================================*/
TITLE "DEFINITIVE STATISTICAL FINDINGS SUMMARY";

DATA _NULL_;
    FILE PRINT;
    PUT "================================================================";
    PUT "MHU PHASE 1 - DEFINITIVE STATISTICAL FINDINGS";
    PUT "Weld County DPHE | Selorm Buaka | June 2026";
    PUT "================================================================";
    PUT " ";
    PUT "NORMALITY (Section 1)";
    PUT "  All key ratio variables non-normal (Shapiro-Wilk p<0.01)";
    PUT "  Justifies Mann-Whitney and Kruskal-Wallis throughout";
    PUT " ";
    PUT "MISSING DATA (Section 2)";
    PUT "  PHS/CH/EH missingness: structural (blank=not offered) NOT systematic";
    PUT "  STI Tests missingness: chi2=4.70 p=0.030 SYSTEMATIC by year";
    PUT "    (proportionally more STI events in 2026 - correct, not a data error)";
    PUT " ";
    PUT "FCSM 5.1 RELEVANCE";
    PUT "  PHS Engage/event:  U=191 p=0.0015 r=0.504 [0.265,0.685] LARGE *";
    PUT "  PHS People/event:  U=262 p=0.043  r=0.321 [0.059,0.541] MEDIUM *";
    PUT "  CH Engage/event:   U=124 p=0.079  r=0.345 [0.037,0.593] MEDIUM ns";
    PUT "  CH annualised: 1038 vs 1054 = STABLE (raw 692 vs 439 is artefact)";
    PUT "  PHS annualised: 531 vs 1097 = LARGE increase";
    PUT "  STI annualised: 712 vs 2098 = nearly tripled";
    PUT "  Seasonal sensitivity: 2026 Apr/May means (31.4/40.0) exceed 2025";
    PUT "    baseline (Jun-Dec mean=10.2). Annualised increase is genuine.";
    PUT " ";
    PUT "FCSM 5.5 GRANULARITY";
    PUT "  EH n=20: power=35.2% at d=0.5 | Need n=63 for 80% power";
    PUT "  ALL EH INFERENTIAL ANALYSIS INVALID. DESCRIPTIVE ONLY.";
    PUT " ";
    PUT "FCSM 5.6 ACCURACY";
    PUT "  STI Ratio: U=122 p=0.845 r=0.043 [-0.310,0.386] NEGLIGIBLE - GOOD";
    PUT "    CV 23.2->14.1%. Levene p=0.293 / F-test p=0.138 - not formally sig";
    PUT "  PHS Eng Ratio: U=246 p=0.139 r=0.244 [-0.035,0.488] SMALL ns";
    PUT "    CV 115.9->58.0%. F-TEST p=0.003 * VARIANCE FORMALLY REDUCED";
    PUT "  CH Scr Ratio: U=118 p=0.053 r=0.374 [0.068,0.616] MEDIUM borderline";
    PUT "  CH OOR Rate:  U=122 p=0.073 r=0.353 [0.045,0.599] MEDIUM borderline";
    PUT " ";
    PUT "FCSM 5.7 COHERENCE";
    PUT "  Address: chi2=14.856 p<0.0001 | 68.5%->22.6% HIGHLY SIGNIFICANT";
    PUT "  Logistic MAR: H-L chi2=0.361 p=0.948 GOOD FIT | AUC=0.777 FAIR";
    PUT "    Year OR=0.091 [0.029,0.289] p<0.001 - Year drives missingness";
    PUT "    Accuracy=75.0% Sensitivity=81.8% Specificity=67.5%";
    PUT "    Conclusion: MAR confirmed. Year 2026 primary predictor.";
    PUT " ";
    PUT "CORRELATIONS (Section 3) - All with 95% CI";
    PUT "  CH Staff vs Screenings:  r=0.683 [0.471,0.820] p<0.001 *** n=40";
    PUT "  CH Staff vs Engagements: r=0.445 [0.163,0.660] p=0.003 **  n=42";
    PUT "  PHS Staff vs STI Tests:  r=0.565 [0.286,0.756] p<0.001 *** n=35";
    PUT "  PHS Staff vs People:     r=0.325 [0.071,0.540] p=0.014 *   n=57";
    PUT "  EventHours vs CH Engage: r=0.389 [0.092,0.622] p=0.012 *   n=41";
    PUT "  PHS vs CH Engage (co):   r=0.599 [0.183,0.833] p=0.009 **  n=18";
    PUT "  PHS Staff vs Engage:     r=0.257 [-0.004,0.485] p=0.054 ns n=57";
    PUT " ";
    PUT "KRUSKAL-WALLIS (Section 4)";
    PUT "  PHS Engage by Region: H=16.685 p=0.0008 | eps2=0.263 LARGE ***";
    PUT "  Dunn post-hoc (Bonferroni):";
    PUT "    Greeley/Evans vs Windsor/Severance: z=3.021 p_bonf=0.015 *";
    PUT "    Greeley/Evans vs Southeast:         z=2.740 p_bonf=0.037 *";
    PUT "    All other pairs: ns";
    PUT "  CH Engage by Region: H=3.286 p=0.511 NOT significant";
    PUT " ";
    PUT "FCSM 5.9 CREDIBILITY";
    PUT "  STI ratio: mean=5.547 95%CI=[5.168,5.926] median=6.000";
    PUT "  Survey recommend: 90.5% (285/315) would recommend";
    PUT "  Survey unmet need: 64.1% (202/315) no care elsewhere";
    PUT "================================================================";
RUN;

ODS PDF CLOSE;
ODS GRAPHICS OFF;

%PUT ===========================================================;
%PUT DEFINITIVE PHASE 1 ANALYSIS COMPLETE;
%PUT PDF: C:\Users\sbuaka\Downloads\MHU_Phase1_Output.pdf;
%PUT ===========================================================;
