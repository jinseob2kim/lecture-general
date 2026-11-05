# RACING synthetic data 재현 지침

RACING trial (Lancet 2022) 구조를 따라 만든 **3,780명 synthetic patient-level data**로 논문의 표와 그림을 재현한다. 목표는 원 논문 값의 정확한 복제가 아니라, 같은 구조의 분석과 같은 형식의 산출물을 만드는 것이다.

## 폴더

- `data/RACING_synthetic_data.csv` (또는 `.xlsx`): 입력 자료, 3,780명 × 57변수
- `paper/`: 원 논문 PDF (숫자 비교용 reference)
- `global.R`: 읽기·전처리·`varlist`·`out`·`out.label`·`out.long`·`out.long.label`
- `analysis.R`: `source("global.R")`로 시작. `ft_list`, `plot_list` 생성
- `results/RACING_Tables.xlsx`: Table 1–4 (시트별), `results/RACING_primary_PH_assumption.xlsx`
- `figures/RACING_Figures.pptx`: Figure 1–3 (벡터그래픽, 슬라이드 1장에 그림 1개)

## 기본 스타일

- data.table 사용, dplyr 사용 안 함. pipe는 `%>%`만
- 파생변수는 모두 `out` 생성 전에 `global.R`에서 만든다. `analysis.R`에서는 `dd <- copy(out)` 안에서만 임시 변수
- 리스트는 `lapply`로 만들고, 파일 저장 같은 side-effect는 for문
- 표: flextable → `ft_list`. `set_caption()`, `add_footer_lines()`(통계방법 + synthetic data 문구), 반복 grouping 값은 `merge_v()` + top/left 정렬
- Excel: `flexlsx::wb_add_flextable()` + `openxlsx2`로 시트별 저장
- 그림: ggplot 객체를 `plot_list`에 저장 → for문으로 `officer` + `rvg::dml()` PPT, `ph_location_fullsize()`
- 사용자에게 보이는 텍스트는 raw 변수명 대신 라벨, `≥`/`≤` 유니코드
- P value는 소수 셋째 자리, 0.001 미만은 `P < 0.001`
- survfit/coxph는 `eval(substitute())` 패턴, `jskm()`에는 `data = dd`

## RACING 구조

- documented ASCVD 3,780명, 1:1 randomised, open-label, non-inferiority
- Combination: rosuvastatin 10 mg + ezetimibe 10 mg (n = 1,894)
- Monotherapy: rosuvastatin 20 mg (n = 1,886)
- Primary endpoint: 3년 CV death, major CV events, non-fatal stroke 복합
- Non-inferiority margin: absolute difference 2.0%p
- Key LDL endpoint: LDL-C <70 mg/dL at 1, 2, 3 years

## 자료 구조

- 시간 단위는 정수 개월
- `primary_time_mo`: primary event 발생자만 값이 있고 미발생자는 `NA`
- `admend_mo`: 관찰 종료·검열 시점 (1–36개월)
- 생존분석 시간 = event 발생자 `primary_time_mo`, 미발생자 `admend_mo`. 미발생자를 제외하면 안 됨
- `secondary_event` 이하 임상 endpoint는 3년 누적 발생 여부만 있으므로 Cox·KM 사용 안 함
- `LDL_y1–3` 결측은 대치하지 않고 시점별 non-missing N을 분모로
- `safety_population`, `intolerance_stop_reduce`는 없다. 만들거나 논문 수치로 합성하지 않는다

## 변수

- ID·군: `ID`, `group` (`Combination`, `Monotherapy`)
- Baseline: `Age`, `Sex`, `Height`, `Weight`, `BMI`, `Prior_MI`, `Prior_PCI`, `Prior_CABG`, `ACS`, `Prior_stroke`, `CKD`, `ESRD_dialysis`, `PAD`, `Hypertension`, `Diabetes`, `Diabetes_insulin`, `Smoking`, `Baseline_LDL`, `Pre_HI_statin`, `Pre_HI_statin_ezetimibe`, `Pre_MI_statin`, `Pre_MI_statin_ezetimibe`, `Pre_LI_statin`, `Pre_none`
- 생존: `admend_mo`, `primary_time_mo`, `primary_event`
- 3년 임상 endpoint: `primary_event`, `secondary_event`, `cv_death_event`, `allcause_death_event`, `mace_event`, `coronary_revasc_event`, `peripheral_revasc_event`, `cv_hosp_event`, `hf_hosp_event`, `nonfatal_stroke_event`, `ischemic_stroke_event`, `hemorrhagic_stroke_event`
- LDL 반복측정: `LDL_y1–3`, `LDL70_y1–3` (<70), `LDL55_y1–3` (<55)
- Safety: `new_diabetes`, `new_diabetes_med`, `muscle_ae`, `myalgia`, `myopathy`, `myonecrosis`, `hepatic_ae`, `ck_elevation`, `fasting_glucose_elevation`, `gallbladder_ae`, `major_bleeding`, `cancer`, `neurocognitive_disorder`, `cataract_surgery`
- Subgroup (global.R에서 out 전에 생성): `Age60`, `Sex`, `BMI25`, `Diabetes`, `Hypertension`, `CKD`, `Prior_MI`, `Prior_stroke`, `PAD`, `Baseline_LDL_100`

## global.R 순서

1. 패키지, 경로 → 2. 자료 읽기 → 3. 변수명·형식 정리, 치료군 factor → 4. 구조 검증 (N, 군별 N, `admend_mo` 범위, 미발생자 `primary_time_mo` NA) → 5. 생존시간·subgroup 파생변수 → 6. `varlist` (Base, Clinical, LDL, Safety, Subgroup, Event, Time) → 7. `out` → 8. factor/numeric, 0/1은 levels `c("0","1")` 고정 → 9. `out.label` → 10. `out.long`, `out.long.label` (LDL 1·2·3년)

## 산출물

**Table 1 · baseline**: ITT, 군간 P value 없음 (원 논문 형식). 연속형 mean (SD) 또는 median (IQR), 범주형 n (%). 약물 사용력은 section row 아래 들여쓰기. footer에 descriptive summary, 가설검정 안 함.

**Table 2 · 3-year clinical endpoints**: 군별 n (%), absolute difference (Combination − Monotherapy). Primary는 90% CI, 나머지 95% CI. CI는 continuity correction 없는 two-sample score method. Primary에만 Cox HR (95% CI)와 Cox P. 나머지 P는 chi-squared 또는 Fisher exact (기대도수 기준). footer에 margin 2.0%p, CI 수준, 검정법.

**Figure 2 · KM**: primary endpoint만. `jskm(..., data = dd, cumhaz = TRUE)`, x축 months, y축 "Cumulative incidence". Primary Cox는 `cox.zph(fit, transform = "identity")` 결과를 `results/RACING_primary_PH_assumption.xlsx`에 저장.

**Table 3 · LDL-C**: `out.long` 기준 1·2·3년. 시점별 observed N, LDL-C median (IQR), <70·<55 달성 n/N (%)와 difference 95% CI (score method). 결측은 0이나 미달로 바꾸지 않음. 시점 열은 `merge_v()`.

**Table 4 · safety**: 전체 무작위배정 대상자를 분모. n (%), difference 95% CI (score method), P는 chi-squared 또는 Fisher exact.

**Figure 3 · subgroup forest**: primary endpoint. 군별 events/total (%), absolute difference와 90% CI. 0%p 기준선, 2.0%p margin 점선, x축 percentage-point 선형. forestploter: CI 열은 공백 열, subgroup level 들여쓰기, 추정 불가는 점·선 생략.

**Figure 1 · flow**: 자료에서 randomized/allocation 수 계산. 약제 불내성 중단은 published RACING 수치 Combination 88/1,846 (4.8%), Monotherapy 150/1,832 (8.2%)를 쓸 수 있으며, 코드에 `# summary numbers from Lancet RACING paper` 주석, 그림 주석에 출처·한계 명시.

## 최종 확인

- N 3,780, 57변수, 군별 1,894 / 1,886
- primary rate 약 9%대, LDL <70 달성률 Combination이 더 높은지
- `out`을 analysis.R에서 수정하지 않았는지
- primary difference는 90% CI, 나머지 95% CI
- primary 외 endpoint에 Cox·HR 없음
- 모든 footer가 실제 검정·CI 산출법과 일치
- `ft_list` 4개, `plot_list` 3개, xlsx 시트 4개, pptx 슬라이드 3장
- 모든 산출물에 synthetic data 문구
