# 강의 그림: 비열등성 개념도(RACING 수치), 3+3 용량 증량·MRMC 판독 설계·메타분석·PPV·대상자 수 곡선 (가상 데이터), 중간분석 유의 기준 (gsDesign)
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

## 2. 3+3 용량 증량 예시 (가상): 코호트 5개, 용량 4단계
de <- data.table(cohort = rep(1:5, each = 3), dose = rep(c(1, 2, 3, 3, 4), each = 3), pt = rep(1:3, 5),
                 dlt = c(0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0))
de[, x := cohort + (pt - 2) * 0.2]
de[, dlt_f := factor(dlt, levels = 0:1, labels = c("DLT 없음", "DLT 발생"))]
de_lab <- data.table(cohort = 1:5, dose = c(1, 2, 3, 3, 4),
                     txt = c("0/3 → 증량", "0/3 → 증량", "1/3 → 3명 추가", "1/6 → 증량", "2/3 → 중단"))
de_arr <- data.table(x = 1:4 + 0.34, xend = 2:5 - 0.34, y = c(1, 2, 3, 3), yend = c(2, 3, 3, 4))

## 3. MRMC 판독 설계 (가상): 판독의 6명 × 케이스 12건, 같은 케이스를 두 번 판독
mm <- CJ(session = c("AI 없는 조건", "AI 있는 조건"), reader = 1:5, case = 1:8)
mm[, truth := factor(fcase(case <= 3, "암", case <= 5, "양성 병변", default = "정상"), levels = c("암", "양성 병변", "정상"))]

## 4. 메타분석 forest plot (가상): 8개 연구 민감도 통합
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

## 5. 유병률에 따른 양성예측도 (민감도·특이도 90% 가정)
pv <- data.table(p = exp(seq(log(0.005), log(0.6), length.out = 300)))
pv[, ppv := 0.9 * p / (0.9 * p + 0.1 * (1 - p))]
pv_pt <- data.table(p = c(0.01, 0.10, 0.50))
pv_pt[, ppv := 0.9 * p / (0.9 * p + 0.1 * (1 - p))]
pv_pt[, txt := paste0("PPV ", round(ppv * 100), "%")]

## 6. 기대 차이·표준편차에 따른 대상자 수 (가상, 두 군 평균 비교, 양측 α 0.05, 검정력 80%)
sc <- CJ(delta = seq(0.4, 1.2, by = 0.01), sd = c(1.3, 1.8))
sc[, n_total := 2 * ceiling(2 * (qnorm(0.975) + qnorm(0.8))^2 * sd^2 / delta^2)]
setorder(sc, delta, sd)
sc[, grp := factor(paste0("표준편차 ", sd), levels = c("표준편차 1.8", "표준편차 1.3"))]
sc_pt <- sc[delta %in% c(0.5, 1.0)]

## 7. 중간분석 1회 (자료 50%)의 유의 기준 p 값: O'Brien–Fleming vs Pocock (양측 α 0.05, gsDesign 경계)
ia <- rbindlist(lapply(c("OF", "Pocock"), function(sf) {
  g <- gsDesign::gsDesign(k = 2, test.type = 2, alpha = 0.025, beta = 0.2, sfu = sf, timing = c(0.5, 1))
  data.table(method = fifelse(sf == "OF", "O'Brien–Fleming", "Pocock"), look = c("중간분석 (자료 50%)", "최종분석"),
             p = 2 * (1 - pnorm(g$upper$bound)))
}))
ia[, look := factor(look, levels = c("중간분석 (자료 50%)", "최종분석"))]
ia[, method := factor(method, levels = c("O'Brien–Fleming", "Pocock"))]
ia[, x := as.integer(look) + fifelse(method == "O'Brien–Fleming", -0.19, 0.19)]
ia[, lab := sprintf("%.3f", p)]
ia[, inside := p > 0.02]

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
    theme(legend.position = c(0.7, 0.62), legend.text = element_text(size = 26), legend.background = element_blank()),

  interim_alpha = ggplot(ia, aes(x, p, fill = method)) +
    geom_col(width = 0.36) +
    geom_hline(yintercept = 0.05, linetype = "dashed", colour = "grey40", linewidth = 1) +
    annotate("text", x = 0.55, y = 0.0535, label = "중간분석이 없으면 0.05", hjust = 0, colour = "grey30", family = fam, size = 7.5) +
    geom_text(data = ia[inside == TRUE], aes(label = lab), vjust = 1.6, colour = "white", family = fam, size = 8.5, fontface = "bold") +
    geom_text(data = ia[inside == FALSE], aes(label = lab), vjust = -0.5, colour = "#1B5E20", family = fam, size = 8.5, fontface = "bold") +
    scale_x_continuous(breaks = 1:2, labels = levels(ia$look), limits = c(0.5, 2.5)) +
    scale_fill_manual(values = c("O'Brien–Fleming" = "#2E7D32", "Pocock" = "#90A4AE"), name = NULL) +
    scale_y_continuous(limits = c(0, 0.06), breaks = seq(0, 0.06, 0.01), expand = expansion(mult = c(0, 0.02))) +
    labs(x = NULL, y = "유의 기준 p 값") +
    theme(legend.position = "top", legend.text = element_text(size = 24))
)

fig_size <- list(ni_racing = c(11, 6.4),
                 dose_escalation = c(10.5, 5.9), mrmc_grid = c(11, 5.6), meta_forest = c(8.2, 7), ppv_prev = c(8.6, 6.6), sample_curve = c(9, 6.6),
                 interim_alpha = c(8.6, 6.4))
for (nm in names(plot_list)) {
  ggsave(file.path("img", paste0(nm, ".png")), plot_list[[nm]], device = ragg::agg_png,
         width = fig_size[[nm]][1], height = fig_size[[nm]][2], dpi = 160, bg = "white")
}
