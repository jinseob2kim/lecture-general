## RACING synthetic data: read, preprocess, varlist, out, labels
## analysis.R starts with source("global.R"); out is not modified downstream.

## 1. Packages, paths ----------------------------------------------------------
library(data.table)
library(magrittr)
library(jstable)

path_csv  <- "data/RACING_synthetic_data.csv"
path_xlsx <- "data/RACING_synthetic_data.xlsx"
dir_results <- "results"
dir_figures <- "figures"
for (d in c(dir_results, dir_figures)) if (!dir.exists(d)) dir.create(d)

## 2. Read data ----------------------------------------------------------------
if (file.exists(path_csv)) {
  a <- fread(path_csv)
} else {
  a <- openxlsx2::read_xlsx(path_xlsx) %>% as.data.table()
}

## 3. Names, formats, treatment factor -----------------------------------------
setnames(a, trimws(names(a)))
a[, group := factor(trimws(group), levels = c("Combination", "Monotherapy"))]
a[, Sex := factor(trimws(Sex), levels = c("Male", "Female"))]

## 4. Structure checks ---------------------------------------------------------
stopifnot(
  nrow(a) == 3780,
  ncol(a) == 57,
  !anyDuplicated(a$ID),
  !anyNA(a$group),
  a[group == "Combination", .N] == 1894,
  a[group == "Monotherapy", .N] == 1886,
  a[, all(admend_mo >= 1 & admend_mo <= 36)],
  a[primary_event == 0, all(is.na(primary_time_mo))],
  a[primary_event == 1, all(!is.na(primary_time_mo) & primary_time_mo <= admend_mo)]
)

## 5. Derived variables: survival time, LDL targets, subgroups -----------------
## Survival time: event -> primary_time_mo, no event -> admend_mo (censored)
a[, primary_surv_mo := fifelse(primary_event == 1, primary_time_mo, admend_mo)]

## LDL-C targets; missing LDL stays NA (no imputation)
for (y in 1:3) {
  ldl <- a[[paste0("LDL_y", y)]]
  set(a, j = paste0("LDL70_y", y), value = as.integer(ldl < 70))
  set(a, j = paste0("LDL55_y", y), value = as.integer(ldl < 55))
}

## Subgroups
a[, Age60 := as.integer(Age >= 60)]
a[, BMI25 := as.integer(BMI >= 25)]
a[, Baseline_LDL_100 := as.integer(Baseline_LDL >= 100)]

## 6. varlist ------------------------------------------------------------------
varlist <- list(
  Base = c("group", "Age", "Sex", "Height", "Weight", "BMI",
           "Prior_MI", "Prior_PCI", "Prior_CABG", "ACS", "Prior_stroke",
           "CKD", "ESRD_dialysis", "PAD", "Hypertension", "Diabetes", "Diabetes_insulin",
           "Smoking", "Baseline_LDL",
           "Pre_HI_statin", "Pre_HI_statin_ezetimibe", "Pre_MI_statin",
           "Pre_MI_statin_ezetimibe", "Pre_LI_statin", "Pre_none"),
  Clinical = c("primary_event", "secondary_event", "cv_death_event", "allcause_death_event",
               "mace_event", "coronary_revasc_event", "peripheral_revasc_event",
               "cv_hosp_event", "hf_hosp_event", "nonfatal_stroke_event",
               "ischemic_stroke_event", "hemorrhagic_stroke_event"),
  LDL = c(paste0("LDL_y", 1:3), paste0("LDL70_y", 1:3), paste0("LDL55_y", 1:3)),
  Safety = c("new_diabetes", "new_diabetes_med", "muscle_ae", "myalgia", "myopathy",
             "myonecrosis", "hepatic_ae", "ck_elevation", "fasting_glucose_elevation",
             "gallbladder_ae", "major_bleeding", "cancer", "neurocognitive_disorder",
             "cataract_surgery"),
  Subgroup = c("Age60", "Sex", "BMI25", "Diabetes", "Hypertension", "CKD",
               "Prior_MI", "Prior_stroke", "PAD", "Baseline_LDL_100"),
  Event = "primary_event",
  Time = c("primary_surv_mo", "admend_mo", "primary_time_mo")
)

## 7. out ----------------------------------------------------------------------
out <- a[, .SD, .SDcols = unique(c("ID", unlist(varlist)))]

## 8. factor / numeric; 0/1 variables -> factor with levels c("0","1") ----------
var.factor <- c("group", "Sex",
                setdiff(names(out)[sapply(out, function(x) is.numeric(x) && all(x %in% c(0, 1, NA)))], "ID"))
var.numeric <- setdiff(names(out), c("ID", var.factor))

out[, (var.factor) := lapply(.SD, function(x) if (is.factor(x)) x else factor(x, levels = c("0", "1"))),
    .SDcols = var.factor]
out[, (var.numeric) := lapply(.SD, as.numeric), .SDcols = var.numeric]

## 9. out.label ----------------------------------------------------------------
var.label <- c(
  group = "Treatment group", Age = "Age, years", Sex = "Sex",
  Height = "Height, cm", Weight = "Weight, kg", BMI = "Body-mass index, kg/m²",
  Prior_MI = "Previous myocardial infarction", Prior_PCI = "Previous PCI",
  Prior_CABG = "Previous CABG", ACS = "Acute coronary syndrome",
  Prior_stroke = "Previous stroke", CKD = "Chronic kidney disease",
  ESRD_dialysis = "End-stage renal disease on dialysis",
  PAD = "Peripheral artery disease", Hypertension = "Hypertension",
  Diabetes = "Diabetes", Diabetes_insulin = "Insulin-treated diabetes",
  Smoking = "Current smoking", Baseline_LDL = "Baseline LDL cholesterol, mg/dL",
  Pre_HI_statin = "High-intensity statin",
  Pre_HI_statin_ezetimibe = "High-intensity statin + ezetimibe",
  Pre_MI_statin = "Moderate-intensity statin",
  Pre_MI_statin_ezetimibe = "Moderate-intensity statin + ezetimibe",
  Pre_LI_statin = "Low-intensity statin", Pre_none = "No lipid-lowering therapy",
  primary_event = "Primary endpoint",
  secondary_event = "Secondary endpoint",
  cv_death_event = "Cardiovascular death",
  allcause_death_event = "All-cause death",
  mace_event = "Major cardiovascular events",
  coronary_revasc_event = "Coronary revascularisation",
  peripheral_revasc_event = "Peripheral revascularisation",
  cv_hosp_event = "Hospitalisation for cardiovascular events",
  hf_hosp_event = "Hospitalisation for heart failure",
  nonfatal_stroke_event = "Non-fatal stroke",
  ischemic_stroke_event = "Ischaemic stroke",
  hemorrhagic_stroke_event = "Haemorrhagic stroke",
  LDL_y1 = "LDL cholesterol at 1 year, mg/dL",
  LDL_y2 = "LDL cholesterol at 2 years, mg/dL",
  LDL_y3 = "LDL cholesterol at 3 years, mg/dL",
  LDL70_y1 = "LDL cholesterol <70 mg/dL at 1 year",
  LDL70_y2 = "LDL cholesterol <70 mg/dL at 2 years",
  LDL70_y3 = "LDL cholesterol <70 mg/dL at 3 years",
  LDL55_y1 = "LDL cholesterol <55 mg/dL at 1 year",
  LDL55_y2 = "LDL cholesterol <55 mg/dL at 2 years",
  LDL55_y3 = "LDL cholesterol <55 mg/dL at 3 years",
  new_diabetes = "New-onset diabetes",
  new_diabetes_med = "New-onset diabetes requiring medication",
  muscle_ae = "Muscle-related adverse events", myalgia = "Myalgia",
  myopathy = "Myopathy", myonecrosis = "Myonecrosis",
  hepatic_ae = "Hepatic adverse events", ck_elevation = "Creatine kinase elevation",
  fasting_glucose_elevation = "Fasting glucose elevation",
  gallbladder_ae = "Gallbladder-related adverse events",
  major_bleeding = "Major bleeding", cancer = "New-onset cancer",
  neurocognitive_disorder = "Neurocognitive disorders",
  cataract_surgery = "Cataract surgery",
  Age60 = "Age", BMI25 = "Body-mass index", Baseline_LDL_100 = "Baseline LDL cholesterol",
  primary_surv_mo = "Time to primary endpoint or censoring, months",
  admend_mo = "Follow-up, months", primary_time_mo = "Time to primary endpoint, months"
)

out.label <- jstable::mk.lev(out)
out.label[variable %in% names(var.label), var_label := var.label[variable]]

## value labels: binary 0/1 -> No/Yes, subgroup cut-offs with ≥/<
var.binary <- setdiff(var.factor, c("group", "Sex"))
out.label[variable %in% var.binary & level == "0", val_label := "No"]
out.label[variable %in% var.binary & level == "1", val_label := "Yes"]
sub.lev <- list(
  Age60 = c("<60 years", "≥60 years"),
  BMI25 = c("<25 kg/m²", "≥25 kg/m²"),
  Baseline_LDL_100 = c("<100 mg/dL", "≥100 mg/dL")
)
for (v in names(sub.lev)) {
  out.label[variable == v & level == "0", val_label := sub.lev[[v]][1]]
  out.label[variable == v & level == "1", val_label := sub.lev[[v]][2]]
}

## 10. out.long, out.long.label (LDL at 1, 2, 3 years) -------------------------
out.long <- melt(
  out[, .SD, .SDcols = c("ID", "group", varlist$LDL)],
  id.vars = c("ID", "group"),
  measure.vars = patterns(LDL = "^LDL_y", LDL70 = "^LDL70_y", LDL55 = "^LDL55_y"),
  variable.name = "year"
)
out.long[, year := factor(year, levels = c("1", "2", "3"), labels = c("1 year", "2 years", "3 years"))]
out.long[, c("LDL70", "LDL55") := lapply(.SD, factor, levels = c("0", "1")), .SDcols = c("LDL70", "LDL55")]
setorder(out.long, ID, year)

out.long.label <- jstable::mk.lev(out.long)
out.long.label[variable == "group", var_label := "Treatment group"]
out.long.label[variable == "year", var_label := "Time point"]
out.long.label[variable == "LDL", var_label := "LDL cholesterol, mg/dL"]
out.long.label[variable == "LDL70", var_label := "LDL cholesterol <70 mg/dL"]
out.long.label[variable == "LDL55", var_label := "LDL cholesterol <55 mg/dL"]
out.long.label[variable %in% c("LDL70", "LDL55") & level == "0", val_label := "No"]
out.long.label[variable %in% c("LDL70", "LDL55") & level == "1", val_label := "Yes"]

rm(a, d, y, ldl, v, sub.lev)
