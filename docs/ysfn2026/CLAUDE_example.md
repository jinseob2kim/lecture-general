# 의학통계 분석 스타일 (CLAUDE.md 예시)

`~/.claude/CLAUDE.md`(모든 프로젝트에 적용) 또는 연구 폴더의 `CLAUDE.md`(그 연구에만 적용)에 저장해서 쓴다.
아래 내용은 예시이므로 본인이 쓰는 패키지와 규칙에 맞게 고친다.

## 1. 기본 원칙

- `data.table`을 메인으로 쓰고 dplyr 스타일은 쓰지 않는다. pipe는 `%>%`만 쓴다.
- 정리는 `global.R`, 분석은 `analysis.R`로 나눈다. `analysis.R`은 `source("global.R")`로 시작한다.
- 파생변수는 모두 `global.R`에서 `out`을 만들기 전에 만든다. `out` 이후에는 새 변수를 만들지 않는다.
  분석 중 임시 변수가 필요하면 `dd <- copy(out)` 안에서만 만든다.
- 리스트는 `lapply` + `rbindlist`로 한 번에 만들고, 파일 저장 같은 작업은 for문으로 한다.
- 불필요한 함수 래핑 없이 스크립트로 쭉 흐르게 쓴다.

## 2. global.R 순서

1. 데이터 읽기 → 2. 전처리·파생변수 → 3. 분석 변수를 `varlist`에 저장
   (생존분석이면 `varlist$Event`, `varlist$Time` 순서를 맞춘다)
4. `out` 생성 → 5. factor/numeric 지정 → 6. `out.label <- jstable::mk.lev(out)` → 7. 라벨 입력

```r
varlist <- list(Base = c("Age", "Sex", "DM"), Event = "death", Time = "death_day")
out <- a[, .SD, .SDcols = unlist(varlist)]

factor_vars <- names(out)[sapply(out, function(x) length(table(x))) <= 6]
out[, (factor_vars) := lapply(.SD, factor), .SDcols = factor_vars]
conti_vars <- setdiff(names(out), factor_vars)
out[, (conti_vars) := lapply(.SD, as.numeric), .SDcols = conti_vars]

out.label <- jstable::mk.lev(out)
out.label[variable == "DM", `:=`(var_label = "Diabetes", val_label = c("No", "Yes"))]
```

- 0/1 변수는 한쪽 값만 있어도 `levels = c("0", "1")`로 고정한다 (Table 1에 "Yes: 0 (0%)"가 나오게).
- 반복측정 자료는 `out`을 바탕으로 `out.long`, `out.long.label`을 같은 방식으로 만든다.

## 3. 표

- `flextable`로 만들고 `set_caption()`으로 표 제목, `add_footer_lines()`로 통계방법을 적는다.
- 표는 Excel로만 저장한다 (`flexlsx` + `openxlsx2`, 표마다 시트 하나).

```r
library(flextable); library(flexlsx); library(openxlsx2)
wb <- wb_workbook()
for (sn in names(ft_list)) {
  wb$add_worksheet(sn)
  wb <- wb_add_flextable(wb, sn, ft_list[[sn]])
}
wb$save("Tables.xlsx")
```

논문에 바로 쓰는 표 규칙:

- 같은 그룹명이 연속 행에 반복되면 `merge_v()`로 병합하고 위·왼쪽 정렬한다.
- raw 변수명(`dose_mg`, `ANC_bl`) 대신 사람이 읽는 라벨을 쓴다 (`out.label`).
- HR, OR, AUC, 평균, 비율 등 모든 점추정에는 95% CI를 붙이고, CI 산출법을 footer에 적는다.
- footer에는 실제 사용한 검정·모델을 한 줄로 적는다. footer만 읽어도 방법을 알 수 있어야 한다.

## 4. 그림

- 기본은 PPT 저장. `officer` + `rvg::dml()`로 편집 가능한 벡터그래픽, 크기는 fullsize.
- ggplot 객체를 `plot_list`에 먼저 모으고 for문으로 슬라이드에 넣는다.

```r
library(officer); library(rvg)
doc <- read_pptx()
for (nm in names(plot_list)) {
  doc <- doc %>% add_slide(layout = "Blank") %>%
    ph_with(dml(ggobj = plot_list[[nm]]), location = ph_location_fullsize())
}
print(doc, target = "Figures.pptx")
```

- 그림 안의 통계값은 직접 계산해서 `annotate()`로 넣는다 (`stat_cor()`, `stat_compare_means()`는 음수 부호가 깨진다).
- P value는 소수 셋째 자리까지, 0.001 미만은 `P < 0.001`.

## 5. 주로 쓰는 패키지

- `jstable`: `CreateTableOneJS()`(Table 1, `labeldata = out.label, Labels = TRUE`), `glmshow.display()`, `cox2.display()`, `geeglm.display()`, `lmer.display()`, 라벨 적용은 `LabeljsTable()`, `LabeljsCox()`
- `jskm`: Kaplan–Meier (`jskm()`, `svyjskm()`)
- `forestploter`: subgroup forest plot
- `mgcv::gam()` + `splineplot`: 비선형 관계

## 6. 자주 틀리는 것

- `survfit()`, `coxph()`에 formula를 변수로 넘기면 `jskm`, `cox2.display`가 실패한다. `eval(substitute())`를 쓴다.
  ```r
  fit <- eval(substitute(coxph(f, data = dd), list(f = fmla)))
  ```
- `jskm(fit, pval = TRUE)`에는 `data = dd`가 필요하다.
- Table 1에서 nonnormal을 지정하면 footer도 Wilcoxon으로 바꾼다. 2군 비교면 `testNonNormal = wilcox.test`.
- Table 1 footer는 실제 검정과 일치시킨다 (예: "P by t-test / Chi-squared or Fisher's exact test").
- 보이는 텍스트의 부등호는 `≥`, `≤`, 단위는 kg/m²로 쓴다.
- nested model의 AUC 비교는 DeLong 대신 likelihood ratio test를 쓴다.
