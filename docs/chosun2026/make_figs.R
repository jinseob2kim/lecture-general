# 강의 그림: 비열등성 개념도(RACING 수치), 3+3 용량 증량·Simon 2단계 특성 곡선·MRMC 판독 설계·ROC·waterfall·swimmer (가상 데이터)
library(data.table); library(magrittr); library(ggplot2)
setwd("~/lecture-general/docs/chosun2026")

fam <- "Noto Sans CJK KR"
theme_set(theme_classic(base_size = 26, base_family = fam))
m <- "−"  # 화면용 음수 부호
pct <- function(x) paste0(round(x * 100), "%")

## 1. 비열등성 개념도: B는 RACING 1차 평가변수 (Lancet 2022; 400: 380–90), 나머지는 개념 예시
ni <- data.table(
  case = c("A. 우월", "B. 비열등 (RACING)", "C. 결론 못 냄", "D. 열등"),
  est = c(-2.6, -0.78, 0.9, 3.2),
  lo = c(-4.0, -2.39, -0.6, 2.4),
  hi = c(-1.2, 0.83, 2.4, 4.0)
)
ni[, case := factor(case, levels = rev(case))]
ni[, racing := grepl("RACING", case)]

## 2. 판독자 연구 ROC: binormal (b = 1) 가상 곡선
fpr <- seq(0, 1, length.out = 401)
roc <- rbindlist(lapply(c(0.80, 0.87), function(auc) {
  data.table(auc = auc, fpr = fpr, tpr = pnorm(sqrt(2) * qnorm(auc) + qnorm(fpr)))
}))
roc[, grp := factor(fifelse(auc == 0.80, "AI 없이 (AUC 0.80)", "AI와 함께 (AUC 0.87)"))]

## 3. Waterfall: 가상 24명, 표적병변 크기 최대 변화 (RECIST 1.1 기준선)
wf <- data.table(chg = c(62, 48, 41, 35, 28, 22, 18, 12, 9, 5, 2, -1, -4, -8, -12, -15, -19, -24, -28, -33, -38, -47, -62, -100))
wf[, id := .I]
wf[, bor := factor(fcase(chg == -100, "CR", chg <= -30, "PR", chg >= 20, "PD", default = "SD"),
                   levels = c("CR", "PR", "SD", "PD"))]

## 4. Swimmer: 가상 10명, 용량군별 치료 기간과 반응 시점
sw <- data.table(
  id = 1:10,
  dose = factor(rep(c("용량 1", "용량 2", "용량 3", "용량 4"), c(2, 3, 2, 3))),
  dur = c(1.4, 2.1, 2.8, 1.9, 4.2, 5.6, 6.9, 8.3, 9.7, 12.1),
  resp = c(NA, NA, NA, NA, NA, NA, 1.8, 1.9, 2.0, 1.8),
  ongoing = c(F, F, F, F, F, F, F, F, T, T)
)
sw[, id := factor(id, levels = id[order(dur)])]

## 5. 3+3 용량 증량 예시 (가상): 코호트 5개, 용량 4단계
de <- data.table(cohort = rep(1:5, each = 3), dose = rep(c(1, 2, 3, 3, 4), each = 3), pt = rep(1:3, 5),
                 dlt = c(0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0))
de[, x := cohort + (pt - 2) * 0.2]
de[, dlt_f := factor(dlt, levels = 0:1, labels = c("DLT 없음", "DLT 발생"))]
de_lab <- data.table(cohort = 1:5, dose = c(1, 2, 3, 3, 4),
                     txt = c("0/3 → 증량", "0/3 → 증량", "1/3 → 3명 추가", "1/6 → 증량", "2/3 → 중단"))
de_arr <- data.table(x = 1:4 + 0.34, xend = 2:5 - 0.34, y = c(1, 2, 3, 3), yend = c(2, 3, 3, 4))

## 6. Simon 2단계 설계 특성 (p0 = 10%, p1 = 30%, α = 0.05, 검정력 80%; 최적 설계 r1 = 1, n1 = 10, r = 5, n = 29)
oc <- data.table(p = seq(0, 0.5, by = 0.0025))
oc[, succ := sapply(p, function(pp) sum(dbinom(2:10, 10, pp) * (1 - pbinom(5 - 2:10, 19, pp))))]
oc[, pet := pbinom(1, 10, p)]
oc_long <- melt(oc, id.vars = "p", variable.name = "what", value.name = "prob")
oc_long[, what := factor(what, levels = c("succ", "pet"), labels = c("성공 판정 확률", "1단계 중단 확률"))]
oc_pt <- data.table(p = c(0.1, 0.3, 0.1), prob = c(oc[p == 0.1, succ], oc[p == 0.3, succ], oc[p == 0.1, pet]),
                    what = factor(c("성공 판정 확률", "성공 판정 확률", "1단계 중단 확률"), levels = levels(oc_long$what)))
oc_pt[, txt := paste0(sprintf("%.1f", prob * 100), "%", c(" (α)", " (검정력)", ""))]

## 7. MRMC 판독 설계 (가상): 판독의 6명 × 케이스 12건, 같은 케이스를 두 번 판독
mm <- CJ(session = c("AI 없는 조건", "AI 있는 조건"), reader = 1:5, case = 1:8)
mm[, truth := factor(fcase(case <= 3, "암", case <= 5, "양성 병변", default = "정상"), levels = c("암", "양성 병변", "정상"))]

## 8. 메타분석 forest plot (가상): 8개 연구 민감도 통합
mf <- data.table(study = paste("연구", LETTERS[1:8]), est = c(0.81, 0.88, 0.84, 0.92, 0.79, 0.86, 0.90, 0.83),
                 n = c(120, 340, 210, 95, 180, 400, 150, 260))
mf[, se := sqrt(est * (1 - est) / n)]
mf[, `:=`(lo = est - 1.96 * se, hi = est + 1.96 * se)]
pooled <- mf[, .(est = sum(est / se^2) / sum(1 / se^2), se = sqrt(1 / sum(1 / se^2)))]
mf_all <- rbind(mf[, .(study, est, lo, hi, w = n)], data.table(study = "통합", est = pooled$est, lo = pooled$est - 1.96 * pooled$se,
                                                            hi = pooled$est + 1.96 * pooled$se, w = NA))
mf_all[, study := factor(study, levels = rev(study))]
dia <- data.table(x = c(mf_all[study == "통합", lo], mf_all[study == "통합", est], mf_all[study == "통합", hi], mf_all[study == "통합", est]),
                  y = c(1, 1.32, 1, 0.68))

## 9. 유병률에 따른 양성예측도 (민감도·특이도 90% 가정)
pv <- data.table(p = exp(seq(log(0.005), log(0.6), length.out = 300)))
pv[, ppv := 0.9 * p / (0.9 * p + 0.1 * (1 - p))]
pv_pt <- data.table(p = c(0.01, 0.10, 0.50))
pv_pt[, ppv := 0.9 * p / (0.9 * p + 0.1 * (1 - p))]
pv_pt[, txt := paste0("PPV ", round(ppv * 100), "%")]

## 10. 기대 차이·표준편차에 따른 대상자 수 (가상, 두 군 평균 비교, 양측 α 0.05, 검정력 80%)
sc <- CJ(delta = seq(0.4, 1.2, by = 0.01), sd = c(1.3, 1.8))
sc[, n_total := 2 * ceiling(2 * (qnorm(0.975) + qnorm(0.8))^2 * sd^2 / delta^2)]
setorder(sc, delta, sd)
sc[, grp := factor(paste0("표준편차 ", sd), levels = c("표준편차 1.8", "표준편차 1.3"))]
sc_pt <- sc[delta %in% c(0.5, 1.0)]

plot_list <- list(
  ni_racing = ggplot(ni, aes(x = est, y = case)) +
    annotate("rect", xmin = 2, xmax = 5, ymin = -Inf, ymax = Inf, fill = "#C62828", alpha = 0.07) +
    geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.8) +
    geom_vline(xintercept = 2, colour = "#C62828", linetype = "dashed", linewidth = 1.1) +
    geom_linerange(aes(xmin = lo, xmax = hi, colour = racing), linewidth = 2.6) +
    geom_point(aes(colour = racing), size = 6.5) +
    annotate("text", x = 1.88, y = 4.62, label = "비열등성 한계 +2.0%p", hjust = 1, colour = "#C62828",
             family = fam, size = 8, fontface = "bold") +
    annotate("text", x = -0.78, y = 3.4, label = paste0(m, "0.78 (90% CI ", m, "2.39 to 0.83)"),
             colour = "#2E7D32", family = fam, size = 8, fontface = "bold") +
    annotate("text", x = -4.9, y = 0.42, label = "← 병용이 좋음", hjust = 0, colour = "grey35", family = fam, size = 7.5) +
    annotate("text", x = 4.9, y = 0.42, label = "병용이 나쁨 →", hjust = 1, colour = "grey35", family = fam, size = 7.5) +
    scale_colour_manual(values = c(`TRUE` = "#2E7D32", `FALSE` = "grey60"), guide = "none") +
    scale_x_continuous(limits = c(-5, 5), breaks = -4:4, labels = function(x) sub("-", m, x)) +
    scale_y_discrete(expand = expansion(add = c(0.75, 0.85))) +
    labs(x = "3년 사건 발생률 차이 (병용 − 단독, %p)", y = NULL) +
    theme(axis.text.y = element_text(size = 27, colour = "black", face = "bold")),

  mrmc_roc = ggplot(roc, aes(fpr, tpr, colour = grp)) +
    annotate("segment", x = 0, y = 0, xend = 1, yend = 1, linetype = "dashed", colour = "grey60") +
    geom_path(linewidth = 2.2) +
    annotate("text", x = 0.97, y = 0.06, label = "가상 예시", hjust = 1, colour = "grey45", family = fam, size = 8) +
    scale_colour_manual(values = c("grey55", "#2E7D32"), name = NULL) +
    scale_x_continuous(breaks = c(0, 0.5, 1)) + scale_y_continuous(breaks = c(0, 0.5, 1)) +
    coord_equal() +
    labs(x = "1 − 특이도", y = "민감도") +
    theme(legend.position = c(0.6, 0.3), legend.text = element_text(size = 25),
          legend.background = element_blank()),

  waterfall = ggplot(wf, aes(x = id, y = chg, fill = bor)) +
    geom_col(width = 0.8) +
    geom_hline(yintercept = 0, colour = "grey30") +
    geom_hline(yintercept = c(20, -30), linetype = "dashed", colour = c("#C62828", "#1565C0"), linewidth = 1) +
    annotate("text", x = 24.4, y = 27, label = "+20% (참고선)", hjust = 1, colour = "#C62828", family = fam, size = 7.5) +
    annotate("text", x = 0.6, y = -37, label = paste0(m, "30% (PR 기준)"), hjust = 0, colour = "#1565C0", family = fam, size = 7.5) +
    annotate("text", x = 24.4, y = 66, label = "가상 데이터", hjust = 1, colour = "grey45", family = fam, size = 7.5) +
    scale_fill_manual(values = c(CR = "#0D47A1", PR = "#42A5F5", SD = "#B0BEC5", PD = "#E57373"), name = NULL, drop = FALSE) +
    scale_y_continuous(limits = c(-100, 70), breaks = seq(-100, 60, 20), labels = function(x) sub("-", m, x)) +
    labs(x = "환자", y = "기저치 대비 best change (%)") +
    theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), legend.position = "top"),

  swimmer = ggplot(sw) +
    geom_segment(aes(x = 0, xend = dur, y = id, yend = id, colour = dose), linewidth = 11) +
    geom_point(data = sw[!is.na(resp)], aes(x = resp, y = id, shape = "반응 시작"), size = 7, colour = "#0D47A1") +
    geom_point(data = sw[ongoing == F], aes(x = dur + 0.3, y = id, shape = "진행·중단"), size = 6, colour = "#C62828") +
    geom_segment(data = sw[ongoing == T], aes(x = dur + 0.1, xend = dur + 1.2, y = id, yend = id),
                 arrow = arrow(length = unit(0.4, "cm"), type = "closed"), colour = "grey25", linewidth = 1.2) +
    annotate("text", x = 13.8, y = 1, label = "가상 데이터", hjust = 1, colour = "grey45", family = fam, size = 7.5) +
    scale_colour_manual(values = c("#C8E6C9", "#81C784", "#43A047", "#1B5E20"), name = NULL) +
    scale_shape_manual(values = c(`반응 시작` = 17, `진행·중단` = 15), name = NULL) +
    scale_x_continuous(limits = c(0, 13.8), breaks = seq(0, 12, 3), expand = expansion(mult = c(0, 0.02))) +
    labs(x = "치료 기간 (개월)", y = "환자") +
    theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), legend.position = "top",
          legend.box = "vertical", legend.spacing.y = unit(0, "cm"), legend.margin = margin(0, 0, 0, 0)),

  dose_escalation = ggplot(de) +
    annotate("rect", xmin = 0.45, xmax = 5.6, ymin = 2.62, ymax = 3.38, fill = "#E8F5E9") +
    annotate("text", x = 5.55, y = 3.0, label = "MTD", hjust = 1, colour = "#1B5E20", family = fam, size = 9, fontface = "bold") +
    geom_segment(data = de_arr, aes(x = x, xend = xend, y = y, yend = yend),
                 arrow = arrow(length = unit(0.35, "cm"), type = "closed"), colour = "grey55", linewidth = 1) +
    geom_point(aes(x = x, y = dose, fill = dlt_f), shape = 21, size = 11, colour = "white", stroke = 1.5) +
    geom_text(data = de_lab, aes(x = cohort, y = dose + c(-0.4, -0.4, 0.42, -0.42, -0.4), label = txt), family = fam, size = 7, colour = "grey20") +
    scale_fill_manual(values = c(`DLT 없음` = "#66BB6A", `DLT 발생` = "#E53935"), name = NULL) +
    scale_x_continuous(breaks = 1:5, labels = paste0(1:5, "차"), limits = c(0.45, 5.6)) +
    scale_y_continuous(breaks = 1:4, labels = paste("용량", 1:4), limits = c(0.5, 4.4)) +
    labs(x = "코호트 (3명씩)", y = NULL) +
    theme(legend.position = "top", axis.text.y = element_text(size = 26, colour = "black", face = "bold")),

  simon_oc = ggplot(oc_long, aes(p, prob, colour = what, linetype = what)) +
    geom_vline(xintercept = c(0.1, 0.3), colour = "grey70", linetype = "dotted", linewidth = 1) +
    geom_line(linewidth = 2.2) +
    geom_point(data = oc_pt, size = 6) +
    geom_text(data = oc_pt[-1], aes(label = txt), hjust = -0.12, vjust = c(1.4, -0.6), family = fam, size = 8,
              fontface = "bold", show.legend = FALSE) +
    annotate("text", x = 0.09, y = 0.14, label = oc_pt$txt[1], hjust = 1, colour = "#2E7D32", family = fam, size = 8, fontface = "bold") +
    annotate("text", x = c(0.1, 0.3), y = 1.06, label = c("효과 없음 10%", "유망 30%"), family = fam, size = 7.5, colour = "grey30") +
    scale_colour_manual(values = c("#2E7D32", "#E53935"), name = NULL) +
    scale_linetype_manual(values = c("solid", "longdash"), name = NULL) +
    scale_x_continuous(labels = pct, breaks = seq(0, 0.5, 0.1)) +
    scale_y_continuous(labels = pct, breaks = seq(0, 1, 0.25), limits = c(0, 1.1)) +
    labs(x = "실제 반응률", y = "확률") +
    theme(legend.position = "top", legend.key.width = unit(1.6, "cm")),

  mrmc_grid = ggplot(mm, aes(case, reader, fill = truth)) +
    geom_tile(colour = "white", linewidth = 1.6) +
    facet_wrap(~session) +
    scale_fill_manual(values = c(`암` = "#E57373", `양성 병변` = "#FFB74D", `정상` = "#B0BEC5"), name = "케이스") +
    scale_y_reverse(breaks = 1:5, labels = paste("판독의", 1:5), expand = c(0, 0)) +
    scale_x_continuous(breaks = NULL, expand = c(0, 0)) +
    labs(x = "케이스 (두 조건 모두 같은 세트, 순서는 무작위)", y = NULL) +
    theme(text = element_text(size = 34), axis.text.y = element_text(size = 30, colour = "black"),
          legend.text = element_text(size = 30), legend.title = element_text(size = 30),
          legend.position = "top", strip.background = element_rect(fill = "#E8F5E9", colour = NA),
          strip.text = element_text(face = "bold", size = 32, colour = "#1B5E20"), axis.line = element_blank(),
          axis.ticks = element_blank(), panel.spacing = unit(1.4, "cm")),

  meta_forest = ggplot(mf_all[study != "통합"], aes(x = est, y = study)) +
    geom_vline(xintercept = pooled$est, colour = "#2E7D32", linetype = "dashed", linewidth = 0.9) +
    geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 1.4, colour = "grey35") +
    geom_point(aes(size = w), shape = 15, colour = "grey25") +
    geom_polygon(data = dia, aes(x = x, y = y), inherit.aes = FALSE, fill = "#2E7D32") +
    annotate("text", x = 0.99, y = 9.35, label = "가상 데이터", hjust = 1, colour = "grey45", family = fam, size = 7) +
    scale_size_continuous(range = c(4, 10), guide = "none") +
    scale_x_continuous(limits = c(0.7, 1), labels = pct) +
    scale_y_discrete(limits = levels(mf_all$study), expand = expansion(add = c(0.6, 0.9))) +
    labs(x = "민감도 (95% CI)", y = NULL) +
    theme(axis.text.y = element_text(size = 24, colour = "black")),

  ppv_prev = ggplot(pv, aes(p, ppv)) +
    geom_line(linewidth = 2.4, colour = "#1565C0") +
    geom_point(data = pv_pt, size = 7, colour = "#0D47A1") +
    geom_text(data = pv_pt, aes(label = txt), hjust = c(0.75, -0.2, 1.1), vjust = c(-1.3, 0.4, -0.9),
              family = fam, size = 9, fontface = "bold", colour = "#0D47A1") +
    annotate("text", x = 0.58, y = 0.05, label = "민감도·특이도 90% 가정", hjust = 1, colour = "grey40", family = fam, size = 7.5) +
    scale_x_log10(breaks = c(0.01, 0.05, 0.1, 0.2, 0.5), labels = c("1%", "5%", "10%", "20%", "50%")) +
    scale_y_continuous(limits = c(0, 1), labels = pct) +
    labs(x = "유병률 (로그 눈금)", y = "양성예측도 (PPV)"),

  sample_curve = ggplot(sc, aes(delta, n_total, colour = grp)) +
    geom_line(linewidth = 2.4) +
    geom_point(data = sc_pt, size = 6) +
    geom_text(data = sc_pt, aes(label = paste0(n_total, "명")), hjust = -0.25, vjust = c(-0.5, -0.5, 1.7, -0.6), family = fam, size = 8,
              fontface = "bold", show.legend = FALSE) +
    annotate("text", x = 1.2, y = 690, label = "가상 수치 · 양측 α 0.05 · 검정력 80%", hjust = 1, colour = "grey40", family = fam, size = 7) +
    scale_colour_manual(values = c("#EF6C00", "#1565C0"), name = NULL) +
    scale_x_continuous(breaks = seq(0.4, 1.2, 0.2)) +
    scale_y_continuous(limits = c(0, 700), breaks = seq(0, 700, 100)) +
    labs(x = "기대하는 두 군 통증 점수 차이", y = "필요 대상자 수 (두 군 합)") +
    theme(legend.position = c(0.7, 0.62), legend.text = element_text(size = 26), legend.background = element_blank())
)

fig_size <- list(ni_racing = c(11, 6.4), mrmc_roc = c(7.4, 7.4), waterfall = c(9, 6.2), swimmer = c(9, 6.2),
                 dose_escalation = c(10.5, 5.9), simon_oc = c(9.5, 6.0), mrmc_grid = c(11, 5.6), meta_forest = c(8.2, 7), ppv_prev = c(8.6, 6.6), sample_curve = c(9, 6.6))
for (nm in names(plot_list)) {
  ggsave(file.path("img", paste0(nm, ".png")), plot_list[[nm]], device = ragg::agg_png,
         width = fig_size[[nm]][1], height = fig_size[[nm]][2], dpi = 160, bg = "white")
}
