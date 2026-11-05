## RACING synthetic data: Tables 1-4, Figures 1-3
source("global.R")

library(survival)
library(ggplot2)
library(flextable)
library(officer)
library(rvg)
library(jskm)
library(forestploter)
library(flexlsx)
library(openxlsx2)

## Common helpers --------------------------------------------------------------
syn_note <- "Synthetic data: results are from 3,780 synthetic patients generated to follow the RACING trial structure and do not reproduce the published trial results."
grp_lev <- levels(out$group)
grp_n <- table(out$group)
grp_head <- paste0(grp_lev, "\n(n = ", format(as.integer(grp_n), big.mark = ","), ")")

lab <- function(v) out.label[variable == v, var_label][1]
val <- function(v, l) out.label[variable == v & level == l, val_label][1]
fmt_n <- function(x) format(x, big.mark = ",", trim = TRUE)
fmt_np <- function(x, n) sprintf("%s (%.1f)", fmt_n(x), 100 * x / n)
fmt_p <- function(p) ifelse(is.na(p), "", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))

## Wilson score interval for one proportion
wilson <- function(x, n, z) {
  p <- x / n
  centre <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
  c(centre - half, centre + half)
}

## Two-sample score CI for p1 - p2 (Newcombe hybrid score, no continuity correction), in %p
diff_score <- function(x1, n1, x2, n2, level = 0.95) {
  z <- qnorm(1 - (1 - level) / 2)
  p1 <- x1 / n1; p2 <- x2 / n2
  w1 <- wilson(x1, n1, z); w2 <- wilson(x2, n2, z)
  d <- p1 - p2
  100 * c(est = d,
          lower = d - sqrt((p1 - w1[1])^2 + (w2[2] - p2)^2),
          upper = d + sqrt((w1[2] - p1)^2 + (p2 - w2[1])^2))
}
fmt_diff <- function(d) {
  d <- round(d, 1) + 0  # avoid "-0.0"
  sprintf("%.1f (%.1f to %.1f)", d[1], d[2], d[3])
}

## Chi-squared (no correction) or Fisher exact when any expected count < 5
test_bin <- function(x, g) {
  tab <- table(g, x)
  ex <- suppressWarnings(chisq.test(tab, correct = FALSE))$expected
  if (any(ex < 5)) fisher.test(tab)$p.value else chisq.test(tab, correct = FALSE)$p.value
}

## Binary endpoint row: n (%), difference with score CI, P
row_bin <- function(data, v, level = 0.95) {
  x <- sapply(grp_lev, function(g) data[group == g, sum(get(v) == "1", na.rm = TRUE)])
  n <- sapply(grp_lev, function(g) data[group == g & !is.na(get(v)), .N])
  d <- diff_score(x[1], n[1], x[2], n[2], level)
  data.table(Endpoint = lab(v), Comb = fmt_np(x[1], n[1]), Mono = fmt_np(x[2], n[2]),
             Diff = fmt_diff(d), P = fmt_p(test_bin(data[[v]], data$group)))
}

## Common flextable style
style_ft <- function(ft, caption, footer, merge_col = NULL) {
  if (!is.null(merge_col)) {
    ft <- ft %>% merge_v(j = merge_col) %>% valign(j = merge_col, valign = "top", part = "body") %>%
      align(j = merge_col, align = "left", part = "body")
  }
  ft %>%
    theme_booktabs() %>%
    set_caption(caption) %>%
    add_footer_lines(c(footer, syn_note)) %>%
    fontsize(size = 9, part = "all") %>%
    font(fontname = "Arial", part = "all") %>%
    align(j = -1, align = "center", part = "header") %>%
    bold(part = "header") %>%
    fix_border_issues() %>%
    autofit()
}

dd <- copy(out)
dd_long <- copy(out.long)
dd[, ev := as.integer(primary_event == "1")]
dd[, group_hr := relevel(group, ref = "Monotherapy")]

## Table 1: baseline characteristics ------------------------------------------
var.cont.mean <- c("Age", "Height", "Weight", "BMI")
var.cont.median <- c("Baseline_LDL")
var.drug <- c("Pre_HI_statin", "Pre_HI_statin_ezetimibe", "Pre_MI_statin",
              "Pre_MI_statin_ezetimibe", "Pre_LI_statin", "Pre_none")
var.t1 <- setdiff(varlist$Base, c("group", var.drug))

t1_row <- function(v, indent = 0) {
  if (v %in% var.cont.mean) {
    s <- sapply(grp_lev, function(g) dd[group == g, sprintf("%.1f (%.1f)", mean(get(v), na.rm = TRUE), sd(get(v), na.rm = TRUE))])
    nm <- paste0(lab(v), ", mean (SD)")
  } else if (v %in% var.cont.median) {
    s <- sapply(grp_lev, function(g) dd[group == g, {q <- quantile(get(v), c(0.5, 0.25, 0.75), na.rm = TRUE); sprintf("%.1f (%.1f-%.1f)", q[1], q[2], q[3])}])
    nm <- paste0(lab(v), ", median (IQR)")
  } else {
    l <- if (v == "Sex") "Female" else "1"
    s <- sapply(grp_lev, function(g) dd[group == g, fmt_np(sum(get(v) == l), .N)])
    nm <- if (v == "Sex") "Female sex" else lab(v)
  }
  data.table(Characteristic = nm, Comb = s[1], Mono = s[2], indent = indent)
}

t1 <- rbindlist(c(
  lapply(var.t1, t1_row),
  list(data.table(Characteristic = "Lipid-lowering therapy before enrolment", Comb = "", Mono = "", indent = 0)),
  lapply(var.drug, t1_row, indent = 1)
))
t1_indent <- which(t1$indent == 1)
t1[, indent := NULL]
setnames(t1, c("Characteristic", grp_head))

ft1 <- flextable(t1) %>%
  style_ft("Table 1. Baseline characteristics of the intention-to-treat population",
           "Data are mean (SD), median (IQR), or n (%). Descriptive summary only; no hypothesis testing between groups was performed.") %>%
  padding(i = t1_indent, j = 1, padding.left = 20, part = "body") %>%
  align(j = 1, align = "left", part = "all")

## Table 2: 3-year clinical endpoints -----------------------------------------
fit_cox <- eval(substitute(coxph(Surv(tt, ee) ~ group_hr, data = dd),
                           list(tt = as.name("primary_surv_mo"), ee = as.name("ev"))))
cox_sum <- summary(fit_cox)
cox_hr <- sprintf("%.2f (%.2f-%.2f)", cox_sum$conf.int[1, 1], cox_sum$conf.int[1, 3], cox_sum$conf.int[1, 4])
cox_p <- cox_sum$coefficients[1, "Pr(>|z|)"]

t2 <- rbindlist(lapply(varlist$Clinical, function(v) {
  primary <- v == "primary_event"
  r <- row_bin(dd, v, level = if (primary) 0.90 else 0.95)
  r[, HR := if (primary) cox_hr else ""]
  if (primary) r[, P := fmt_p(cox_p)]
  r[, Category := if (primary) "Primary endpoint" else "Secondary endpoints"]
  r
}))
setcolorder(t2, c("Category", "Endpoint", "Comb", "Mono", "Diff", "HR", "P"))
setnames(t2, c("Category", "Endpoint", grp_head,
               "Absolute difference, percentage points (CI)", "Hazard ratio (95% CI)", "P value"))

ft2 <- flextable(t2) %>%
  style_ft("Table 2. Clinical endpoints at 3 years (intention-to-treat population)",
           c("Data are n (%). Absolute difference = Combination - Monotherapy, in percentage points; CI by the two-sample score method (Newcombe hybrid score) without continuity correction.",
             "Primary endpoint: 90% CI for the difference, compared with the non-inferiority margin of 2.0 percentage points; hazard ratio (95% CI) and P value from a Cox proportional hazards model (reference: Monotherapy).",
             "Other endpoints: 95% CI for the difference; P values from the chi-squared test, or Fisher's exact test when any expected cell count was < 5. Cox models were not fitted because only 3-year cumulative occurrence is available."),
           merge_col = 1) %>%
  align(j = 1:2, align = "left", part = "all")

## Figure 2: Kaplan-Meier, primary endpoint ------------------------------------
sfit <- eval(substitute(survfit(Surv(tt, ee) ~ group, data = dd),
                        list(tt = as.name("primary_surv_mo"), ee = as.name("ev"))))
fig2 <- jskm(sfit, data = dd, cumhaz = TRUE, table = TRUE, marks = FALSE,
             xlabs = "Months since randomisation", ylabs = "Cumulative incidence (%)",
             xlims = c(0, 37.5), timeby = 6, ylims = c(0, 0.12), surv.by = 0.02,
             surv.scale = "percent",
             ystratalabs = grp_lev, ystrataname = "Group", linecols = "Set1",
             main = "Figure 2. Cumulative incidence of the primary endpoint",
             legendposition = c(0.2, 0.85)) %>%
  ggpubr::annotate_figure(bottom = ggpubr::text_grob(
    paste0("Kaplan-Meier cumulative incidence. Hazard ratio (Combination vs Monotherapy) ", cox_hr,
           ", P = ", fmt_p(cox_p), " (Cox model).\n", syn_note),
    size = 8, hjust = 0, x = 0.02))

## PH assumption (Schoenfeld residuals, identity transform)
zph <- cox.zph(fit_cox, transform = "identity")
ph_tab <- data.table(Term = c("Treatment group (Combination vs Monotherapy)", "Global"),
                     `Chi-squared` = round(zph$table[, "chisq"], 3),
                     df = zph$table[, "df"],
                     `P value` = fmt_p(zph$table[, "p"]))

## Table 3: LDL-C at 1, 2, 3 years ---------------------------------------------
t3 <- rbindlist(lapply(levels(dd_long$year), function(y) {
  s <- dd_long[year == y & !is.na(LDL)]
  nn <- sapply(grp_lev, function(g) s[group == g, .N])
  med <- sapply(grp_lev, function(g) s[group == g, {q <- quantile(LDL, c(0.5, 0.25, 0.75)); sprintf("%.1f (%.1f-%.1f)", q[1], q[2], q[3])}])
  tgt <- rbindlist(lapply(c("LDL70", "LDL55"), function(v) {
    x <- sapply(grp_lev, function(g) s[group == g, sum(get(v) == "1")])
    d <- diff_score(x[1], nn[1], x[2], nn[2], 0.95)
    data.table(Measure = paste0(out.long.label[variable == v, var_label][1], ", n/N (%)"),
               Comb = sprintf("%s/%s (%.1f)", fmt_n(x[1]), fmt_n(nn[1]), 100 * x[1] / nn[1]),
               Mono = sprintf("%s/%s (%.1f)", fmt_n(x[2]), fmt_n(nn[2]), 100 * x[2] / nn[2]),
               Diff = fmt_diff(d))
  }))
  rbind(data.table(Measure = c("Observed N", "LDL cholesterol, mg/dL, median (IQR)"),
                   Comb = c(fmt_n(nn[1]), med[1]), Mono = c(fmt_n(nn[2]), med[2]), Diff = ""),
        tgt)[, Year := y]
}))
setcolorder(t3, "Year")
setnames(t3, c("Time point", "Measure", grp_lev, "Absolute difference, percentage points (95% CI)"))

ft3 <- flextable(t3) %>%
  style_ft("Table 3. LDL cholesterol and target achievement at 1, 2, and 3 years",
           c("Denominators are participants with an observed LDL cholesterol value at each time point; missing values were not imputed or counted as not achieving the target.",
             "Absolute difference = Combination - Monotherapy, in percentage points; 95% CI by the two-sample score method (Newcombe hybrid score) without continuity correction."),
           merge_col = 1) %>%
  align(j = 1:2, align = "left", part = "all")

## Table 4: safety endpoints ---------------------------------------------------
t4 <- rbindlist(lapply(varlist$Safety, function(v) row_bin(dd, v, 0.95)))
setnames(t4, c("Safety endpoint", grp_head, "Absolute difference, percentage points (95% CI)", "P value"))

ft4 <- flextable(t4) %>%
  style_ft("Table 4. Safety endpoints",
           c("Data are n (%); denominators are all randomised participants.",
             "Absolute difference = Combination - Monotherapy, in percentage points; 95% CI by the two-sample score method (Newcombe hybrid score) without continuity correction. P values from the chi-squared test, or Fisher's exact test when any expected cell count was < 5.")) %>%
  align(j = 1, align = "left", part = "all")

ft_list <- list(`Table 1` = ft1, `Table 2` = ft2, `Table 3` = ft3, `Table 4` = ft4)

## Figure 3: subgroup forest plot ----------------------------------------------
sub_row <- function(s, name) {
  x <- sapply(grp_lev, function(g) s[group == g, sum(ev)])
  n <- sapply(grp_lev, function(g) s[group == g, .N])
  d <- if (all(n > 0)) diff_score(x[1], n[1], x[2], n[2], 0.90) else c(NA, NA, NA)
  data.table(Subgroup = name,
             Comb = ifelse(n[1] > 0, sprintf("%s/%s (%.1f)", fmt_n(x[1]), fmt_n(n[1]), 100 * x[1] / n[1]), ""),
             Mono = ifelse(n[2] > 0, sprintf("%s/%s (%.1f)", fmt_n(x[2]), fmt_n(n[2]), 100 * x[2] / n[2]), ""),
             est = d[1], lower = d[2], upper = d[3],
             CI = ifelse(is.na(d[1]), "Not estimable", fmt_diff(d)))
}

fd <- rbindlist(c(
  list(sub_row(dd, "All patients")),
  lapply(varlist$Subgroup, function(v) {
    rbind(data.table(Subgroup = lab(v), Comb = "", Mono = "", est = NA_real_, lower = NA_real_, upper = NA_real_, CI = ""),
          rbindlist(lapply(levels(dd[[v]]), function(l) sub_row(dd[get(v) == l], paste0("    ", val(v, l))))))
  })
))
fd[, ` ` := paste(rep(" ", 45), collapse = "")]
fd_show <- fd[, .(Subgroup, Comb, Mono, ` `, CI)]
setnames(fd_show, c("Subgroup", paste0(grp_lev, "\nevents/total (%)"), " ", "Difference, %p (90% CI)"))

x_rng <- range(c(fd$lower, fd$upper, 0, 2), na.rm = TRUE)
x_lim <- c(floor(x_rng[1] / 5) * 5, ceiling(x_rng[2] / 5) * 5)
tm <- forest_theme(base_size = 8, ci_pch = 15, ci_col = "black",
                   core = list(padding = grid::unit(c(3, 1.2), "mm")),
                   refline_gp = grid::gpar(lty = "solid", col = "grey30"),
                   vertline_lty = "dashed", vertline_col = "grey20",
                   footnote_gp = grid::gpar(cex = 0.7), footnote_parse = FALSE)
fig3 <- forest(as.data.frame(fd_show), est = fd$est, lower = fd$lower, upper = fd$upper,
               ci_column = 4, ref_line = 0, vert_line = 2, xlim = x_lim,
               ticks_at = seq(x_lim[1], x_lim[2], by = 5),
               xlab = "Absolute difference (Combination - Monotherapy), percentage points",
               title = "Figure 3. Primary endpoint by subgroup",
               theme = tm) %>%
  gridExtra::arrangeGrob(
    bottom = grid::textGrob(
      paste0("Solid line: no difference; dashed line: non-inferiority margin of 2.0 percentage points.\n",
             "90% CI by the two-sample score method (Newcombe hybrid score) without continuity correction.\n",
             syn_note),
      x = 0.08, hjust = 0, gp = grid::gpar(fontsize = 7)))

## Figure 1: flow diagram ------------------------------------------------------
# summary numbers from Lancet RACING paper (discontinuation/dose reduction due to intolerance)
intol <- data.table(group = grp_lev, x = c(88, 150), n = c(1846, 1832))
ldl_n <- dd_long[!is.na(LDL), .N, by = .(group, year)]

box_ldl <- function(g) paste0("LDL cholesterol observed: ",
                              paste(ldl_n[group == g][order(year), paste0(year, " n = ", fmt_n(N))], collapse = "; "))
arm_x <- c(0.27, 0.73)
boxes <- rbindlist(list(
  data.table(x = 0.5, y = 0.92, w = 0.36, h = 0.09,
             text = paste0("Patients with ASCVD randomised\nn = ", fmt_n(nrow(dd)))),
  data.table(x = arm_x, y = 0.68, w = 0.42, h = 0.12,
             text = paste0(c("Combination\nRosuvastatin 10 mg + ezetimibe 10 mg", "Monotherapy\nRosuvastatin 20 mg"),
                           "\nn = ", fmt_n(as.integer(grp_n)))),
  data.table(x = arm_x, y = 0.44, w = 0.42, h = 0.10,
             text = paste0("Discontinuation or dose reduction due to intolerance*\n",
                           intol$x, "/", fmt_n(intol$n), " (", sprintf("%.1f", 100 * intol$x / intol$n), "%)")),
  data.table(x = arm_x, y = 0.18, w = 0.42, h = 0.16,
             text = paste0("Included in intention-to-treat analysis\nn = ", fmt_n(as.integer(grp_n)),
                           "\n", sapply(grp_lev, function(g) gsub("; ", "\n", box_ldl(g)))))
))
arrows <- data.table(x = c(0.5, 0.5, arm_x[1], arm_x[2], arm_x[1], arm_x[2]),
                     xend = c(arm_x[1], arm_x[2], arm_x[1], arm_x[2], arm_x[1], arm_x[2]),
                     y = c(0.875, 0.875, 0.62, 0.62, 0.39, 0.39),
                     yend = c(0.74, 0.74, 0.49, 0.49, 0.26, 0.26))
fig1 <- ggplot() +
  geom_segment(data = arrows, aes(x = x, y = y, xend = xend, yend = yend),
               arrow = arrow(length = unit(2, "mm"), type = "closed")) +
  geom_rect(data = boxes, aes(xmin = x - w / 2, xmax = x + w / 2, ymin = y - h / 2, ymax = y + h / 2),
            fill = "white", colour = "black") +
  geom_text(data = boxes, aes(x = x, y = y, label = text), size = 3, lineheight = 0.95) +
  scale_x_continuous(limits = c(0, 1)) + scale_y_continuous(limits = c(0.05, 1)) +
  labs(title = "Figure 1. Trial profile",
       caption = paste0("Randomisation, allocation and LDL cholesterol counts were computed from the synthetic data.\n",
                        "*Summary numbers from the published RACING paper (Lancet 2022); they are not derived from the synthetic data,\n",
                        "use the published denominators, and are shown only to illustrate the figure format.\n", syn_note)) +
  theme_void() +
  theme(plot.title = element_text(face = "bold"), plot.caption = element_text(hjust = 0, size = 8))

plot_list <- list(`Figure 1` = fig1, `Figure 2` = fig2, `Figure 3` = fig3)

## Save: tables to Excel -------------------------------------------------------
wb <- wb_workbook()
for (nm in names(ft_list)) {
  wb$add_worksheet(nm)
  wb <- wb_add_flextable(wb, sheet = nm, ft = ft_list[[nm]])
}
wb$save(file.path(dir_results, "RACING_Tables.xlsx"))

wb_ph <- wb_workbook()$add_worksheet("PH assumption")$
  add_data(x = data.frame(Note = "Proportional hazards test for the primary endpoint Cox model: cox.zph(fit, transform = \"identity\")."))$
  add_data(x = as.data.frame(ph_tab), start_row = 3)$
  add_data(x = data.frame(Note = syn_note), start_row = 7, col_names = FALSE)
wb_ph$save(file.path(dir_results, "RACING_primary_PH_assumption.xlsx"))

## Save: figures to PowerPoint (vector graphics) -------------------------------
ppt <- read_pptx()
for (nm in names(plot_list)) {
  p <- plot_list[[nm]]
  g <- if (inherits(p, "ggplot")) dml(ggobj = p) else dml(code = grid::grid.draw(p))
  ppt <- ppt %>%
    add_slide(layout = "Blank", master = "Office Theme") %>%
    ph_with(g, location = ph_location_fullsize())
}
print(ppt, target = file.path(dir_figures, "RACING_Figures.pptx"))
