###############################################################################
# SYSTEMATIC DESCRIPTIVE SYNTHESIS OF ADSORPTION STUDIES
# Revised v28_5 (consolidated exports and reproducibility records) for: Data_10426(1).csv
#
# Included analyses:
# 1. Evidence map by metal, precursor, activation type, and water matrix
# 2. Data-completeness analysis
# 3. Dependence-reduced descriptive synthesis
# 4. Median/IQR comparison of qe, qmax, and removal
# 5. Pb versus Cd comparison
# 6. Precursor-group comparison
# 7. Kinetic and isotherm model frequency analysis
# 8. Regeneration-reporting analysis
# 9. Reproducibility/uncertainty-reporting analysis
# 10. Adsorption-specific six-domain critical appraisal workflow
# 11. Experimental-condition heterogeneity analysis
# 12. Extreme-value and water-matrix sensitivity analyses
# 13. Source-traceability and model-field validation audits
# 14. Main figures, main tables, and supplementary index
#
# Statistical stance:
# - The updated dataset contains partial replicate-count and uncertainty reporting.
# - Uncertainty is not encoded outcome-by-outcome, and many uncertainty values are
#   nonnumeric or figure-only; therefore, inverse-variance meta-analysis is not
#   performed automatically.
# - Group comparisons remain exploratory and non-parametric.
# - The preferred analytical unit is study_id x adsorbent_id x standardized metal.
###############################################################################

# 0. USER SETTINGS ------------------------------------------------------------

input_file <- "Data_10526.csv"
classification_catalogue_file <- "Table S11.csv"
CATALOGUE_ENCODING <- "UTF-8" # Uploaded catalogue; separate from the extraction encoding.
INPUT_ENCODING <- "Windows-1252" # Encoding of the supplied Data_10426(1).csv.
input_sheet <- NULL  # Used only if an Excel file is supplied instead.
# Run from a project folder containing this script and its input files.
# Use a short project path on Windows (for example D:/adsorption).
RUN_MODE <- "development" # Use "submission" to enforce documentation gates.
RANDOM_SEED <- 20261005L
SCRIPT_FILE <- NULL # Optional explicit path when pasting into an R console.
# Each run gets a new directory; previous files cannot masquerade as new exports.
# Completion of an R run is not certification of scientific submission readiness.
final_relevant_output_directory <- tempfile(
  pattern = paste0("v28_5_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_"), tmpdir = ".")
stopifnot(RUN_MODE %in% c("development", "submission"))
if (getRversion() < "4.1.0") stop("R 4.1.0 or later is required (native pipe syntax).")
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(RANDOM_SEED)
# Capture the script path for Rscript/source(). Pasted code has no recoverable file.
script_args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
if (is.null(SCRIPT_FILE)) {
  source_paths <- unlist(lapply(sys.frames(), function(frame) frame$ofile))
  if (length(source_paths)) SCRIPT_FILE <- tail(source_paths, 1)
}
if (is.null(SCRIPT_FILE) && length(script_args)) SCRIPT_FILE <- sub("^--file=", "", script_args[1])
if (!file.exists(input_file)) stop("Input file not found: ", input_file,
  ". Run from the project folder or edit input_file.")
# Work in a short, run-specific temporary directory to avoid Windows path limits.
output_directory <- tempfile(pattern = "adsorb_", tmpdir = tempdir())
install_missing_packages <- FALSE

# Publication-ready style settings adapted from the user's scientometric pipeline.
CONFIG <- list(
  EXPORT_PDF = FALSE,
  EXPORT_TIFF = FALSE,
  DPI = 300,
  TIFF_DPI = 600,
  FIGURE_BASE_SIZE = 11,
  FIGURE_FONT_FAMILY = "Arial",
  TABLE_FONT_FAMILY = "Arial",
  TABLE_FONT_SIZE = 8.5,
  WRITE_STANDALONE_LEGENDS = TRUE,
  MIN_GROUP_N_FOR_INTERPRETATION = 5L,
  MIN_GROUP_N_FOR_PAIRWISE_TEST = 5L,
  OUTLIER_IQR_MULTIPLIER = 1.5,
  PB_PRECIPITATION_CAUTION_PH = 6.0,
  CD_PRECIPITATION_CAUTION_PH = 8.0,
  TARGET_METALS = c("Pb", "Cd"),
  TARGET_PRECURSOR_LEVELS = c(
    "Rice husk",
    "Sugarcane bagasse",
    "Coconut shell"
  ),
  # Review-wide count from the prior screening flow, NOT the extraction-study count.
  # Reconcile with the current screening log before submission.
  SYSTEMATIC_REVIEW_INCLUDED_STUDIES = 51L,
  EXPORT_OPTIONAL_PH_FIGURE = FALSE,
  REVIEW_INCLUDED_STUDY_ROSTER_FILE = "review_included_study_roster.csv",
  CRITICAL_APPRAISAL_MANUAL_FILE = "critical_appraisal_manual.csv",
  REVIEWER_AGREEMENT_FILE = "critical_appraisal_reviewer_ratings.csv"
)

if (!dir.exists(output_directory)) {
  dir.create(output_directory, recursive = TRUE)
}



# Submission reporting notes ---------------------------------------------------
TABLE1_NOTE <- paste(
  "Counts use dependence-reduced study–adsorbent–metal analytical units.",
  "Adsorbents are counted as distinct study–adsorbent pairs because adsorbent identifiers are study-specific and may recur across publications.",
  "Study counts within metal and precursor categories are not mutually exclusive because individual studies may contribute to more than one category."
)

TABLE_S8_NOTE <- paste(
  "Only finite numeric regeneration-cycle observations are presented.",
  "Discussion of regeneration, desorption or adsorbent reuse in a primary article is not treated as a numeric cycle observation unless a corresponding numeric cycle value is recorded in the extraction dataset."
)

TABLE_S9_NOTE <- paste(
  "Outcome-extreme values checked against the source are classified as 'Verified unchanged' when no analytical value is altered.",
  "Interpretive source checks, including pH/precipitation review, use 'Resolved interpretation' when interpretation is clarified without changing the analytical value."
)

TABLE_S11A_NOTE <- paste(
  "A material is identified by the combination of study ID and adsorbent ID.",
  "Study-specific material counts should not be compared with counts based on adsorbent-ID strings alone."
)

# Reviewer-variable availability note -----------------------------------------
# The current extraction schema does not contain study-level fields for:
# - Langmuir/Freundlich or other model goodness-of-fit values (e.g., R2),
# - alternative-model fit comparisons linked to each qmax,
# - metal mass-balance checks,
# - explicit precipitation-control methods,
# - direct versus literature-borrowed characterisation provenance, or
# - competing-ion/salinity concentrations.
# These are therefore not inferred automatically. Add explicit extraction fields
# before performing analyses based on those reviewer-requested variables.

# 1. PACKAGES -----------------------------------------------------------------

required_packages <- c("tidyverse", "scales", "patchwork")
optional_publication_packages <- c("flextable", "officer", "gt", "writexl")

installed <- rownames(installed.packages())
missing_packages <- setdiff(required_packages, installed)

if (length(missing_packages) > 0 && install_missing_packages) {
  install.packages(missing_packages, dependencies = TRUE)
}

missing_after_install <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_after_install) > 0) {
  stop(
    "Missing required packages: ",
    paste(missing_after_install, collapse = ", "),
    "\nInstall them before running the script, or set install_missing_packages <- TRUE."
  )
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(patchwork)
})

missing_optional_publication_packages <- optional_publication_packages[
  !vapply(optional_publication_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_optional_publication_packages) > 0) {
  message(
    "Optional publication packages not installed: ",
    paste(missing_optional_publication_packages, collapse = ", "),
    ". CSV tables and PNG/PDF/TIFF figures will still be generated; DOCX/HTML tables may be skipped."
  )
}

# 2. EXPECTED SCHEMA -----------------------------------------------------------

required_columns <- c(
  "study_id",
  "adsorbent_id",
  "precursor_std",
  "base_feedstock_std",
  "additive_std",
  "activation_type_std",
  "production_route_std",
  "modification_route_std",
  "treatment_agent_std",
  "preparation_details",
  "modification_route_raw",
  "treatment_agent_raw",
  "preparation_route",
  "activation_route",
  "modification_route",
  "treatment_agent",
  "source_location",
  "activation_temp_c_mid",
  "metal",
  "element_std",
  "oxidation_state_std",
  "water_matrix",
  "c0_mg_l_mid",
  "adsorbent_dose_g_l_mid",
  "contact_time_min_mid",
  "bet_m2_g_mid",
  "removal_reported_percent_mid",
  "qe_reported_mg_g_mid",
  "qmax_reported_mg_g_mid",
  "kinetic_model_std",
  "isotherm_model_std",
  "regeneration_cycles",
  "replicates_n",
  "blanks_reported",
  "calibration_reported",
  "ph_controlled",
  "uncertainty_type",
  "uncertainty_value"
)

# Columns that should become numeric in the analytical dataset.
# uncertainty_value is intentionally kept as character because the updated
# input dataset mixes numeric values, ± notation, and other uncertainty formats.
numeric_columns <- c(
  "activation_temp_c_mid",
  "c0_mg_l_mid",
  "adsorbent_dose_g_l_mid",
  "contact_time_min_mid",
  "bet_m2_g_mid",
  "removal_reported_percent_mid",
  "qe_reported_mg_g_mid",
  "qmax_reported_mg_g_mid",
  "regeneration_cycles",
  "replicates_n"
)

categorical_columns <- setdiff(required_columns, numeric_columns)

# Preserve distinctions between "None reported", "Not reported" and "Unclear".
route_source_columns <- c("production_route_std", "modification_route_std",
  "treatment_agent_std", "preparation_details", "modification_route_raw",
  "treatment_agent_raw", "preparation_route", "activation_route",
  "modification_route", "treatment_agent", "source_location")

# 3. HELPER FUNCTIONS ----------------------------------------------------------

missing_tokens <- c(
  "", "na", "n/a", "nr", "not reported", "not reported/unclear",
  "unclear", "unknown", "none reported", "nan", "---", "--", "-"
)

normalize_missing <- function(x) {
  out <- stringr::str_squish(as.character(x))
  out[stringr::str_to_lower(out) %in% missing_tokens] <- NA_character_
  out
}

parse_numeric_strict <- function(x) {
  x_chr <- normalize_missing(x)
  x_chr <- stringr::str_replace_all(x_chr, ",", "")
  is_scalar <- stringr::str_detect(
    x_chr,
    "^[+-]?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?$"
  )
  out <- rep(NA_real_, length(x_chr))
  out[!is.na(is_scalar) & is_scalar] <- as.numeric(x_chr[!is.na(is_scalar) & is_scalar])
  out
}

# Parse fields that are explicitly stored as *_mid. The function accepts:
# - exact scalars (e.g., "250")
# - approximate values prefixed with "~" or "≈"
# - a scalar followed by a short annotation (e.g., "70 (drying)")
# - a simple two-number range (e.g., "430-550" or "1.0 to 7.5"), returned as midpoint
# It deliberately returns NA for inequalities (">90"), slash-separated vectors,
# and other multi-valued expressions to avoid inventing an exact value.
parse_numeric_mid <- function(x) {
  x_chr <- normalize_missing(x)
  x_chr <- stringr::str_replace_all(x_chr, ",", "")
  x_chr <- stringr::str_replace_all(x_chr, "[~≈]", "")
  x_chr <- stringr::str_replace(x_chr, "\\^\\s*[A-Za-z]+$", "")
  x_chr <- stringr::str_squish(x_chr)

  out <- rep(NA_real_, length(x_chr))
  if (length(x_chr) == 0) return(out)

  scalar_pat <- "^[+-]?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?(?:\\s*\\([^)]*\\))?$"
  range_pat <- "^([+-]?(?:\\d+(?:\\.\\d*)?|\\.\\d+))\\s*(?:-|–|—|to)\\s*([+-]?(?:\\d+(?:\\.\\d*)?|\\.\\d+))(?:\\s*\\([^)]*\\))?$"

  scalar_idx <- !is.na(x_chr) & stringr::str_detect(x_chr, scalar_pat)
  out[scalar_idx] <- readr::parse_number(x_chr[scalar_idx])

  range_idx <- !is.na(x_chr) & !scalar_idx & stringr::str_detect(
    stringr::str_to_lower(x_chr), range_pat
  )

  if (any(range_idx)) {
    m <- stringr::str_match(stringr::str_to_lower(x_chr[range_idx]), range_pat)
    lo <- as.numeric(m[, 2])
    hi <- as.numeric(m[, 3])
    out[range_idx] <- (lo + hi) / 2
  }

  out
}

standardize_metal <- function(x) {
  x_chr <- normalize_missing(x)
  dplyr::case_when(
    stringr::str_detect(x_chr, stringr::regex("^pb(?:\\(ii\\)|2\\+)?$", ignore_case = TRUE)) ~ "Pb",
    stringr::str_detect(x_chr, stringr::regex("^cd(?:\\(ii\\)|2\\+)?$", ignore_case = TRUE)) ~ "Cd",
    stringr::str_detect(x_chr, stringr::regex("^cu(?:\\(ii\\)|2\\+)?$", ignore_case = TRUE)) ~ "Cu",
    TRUE ~ x_chr
  )
}

standardize_uncertainty_type <- function(x) {
  x_raw <- normalize_missing(x)
  x_chr <- stringr::str_to_lower(x_raw)

  dplyr::case_when(
    is.na(x_chr) ~ NA_character_,
    stringr::str_detect(x_chr, "^sd") &
      stringr::str_detect(x_chr, "conflict.*se|se.*method") ~ "SD/SE conflict",
    x_chr %in% c("sd", "standard deviation") ~ "SD",
    x_chr %in% c("se", "standard error", "standard error of mean", "sem") ~ "SE",
    x_chr == "rsd" ~ "RSD",
    x_chr == "see" ~ "SEE",
    x_chr == "relative error" ~ "Relative error",
    stringr::str_detect(x_chr, "reported\\s*±|type\\s*nr|uncertainty type\\s*nr") ~
      "Type not specified",
    TRUE ~ x_raw
  )
}

parse_uncertainty_numeric <- function(x) {
  x_chr <- normalize_missing(x)
  x_chr <- stringr::str_replace_all(x_chr, ",", "")
  scalar_pat <- "^(?:±\\s*)?[+-]?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?%?$"
  idx <- !is.na(x_chr) & stringr::str_detect(x_chr, scalar_pat)
  out <- rep(NA_real_, length(x_chr))
  out[idx] <- readr::parse_number(x_chr[idx])
  out
}

normalize_yes_no <- function(x) {
  x_raw <- normalize_missing(x)
  x_chr <- stringr::str_to_lower(x_raw)

  dplyr::case_when(
    is.na(x_chr) ~ NA_character_,
    stringr::str_detect(x_chr, "^yes") ~ "Yes",
    stringr::str_detect(x_chr, "^no(?:$|[;,:])") ~ "No",
    TRUE ~ x_raw
  )
}

# Map the updated extraction vocabulary to the three manuscript precursor groups.
# Coconut husk/coir/peel/bark and all other biomass types remain available in the
# broad-source audit but are not silently merged into "Coconut shell".
standardize_review_precursor <- function(x) {
  x_raw <- normalize_missing(x)
  x_chr <- stringr::str_to_lower(x_raw)

  dplyr::case_when(
    x_chr == "rice husk" ~ "Rice husk",
    x_chr == "sugarcane bagasse" ~ "Sugarcane bagasse",
    x_chr == "coconut shell" ~ "Coconut shell",
    TRUE ~ NA_character_
  )
}


# Extract a pH central value from free-text control descriptions.
# The updated CSV commonly uses expressions such as:
#   "Reported maintained6±0.3;table captions6±0.2"
#   "Initial pH4.5–5.0; continuous control NR"
#   "Initial pH adjusted to6.01±0.2"
# The ± term is uncertainty, not a second pH endpoint, and is therefore removed
# before range/scalar parsing.
parse_ph_mid <- function(x) {
  x_chr <- normalize_missing(x)
  x_chr <- stringr::str_replace_all(x_chr, "\u2013|\u2014", "-")
  out <- rep(NA_real_, length(x_chr))

  for (i in seq_along(x_chr)) {
    if (is.na(x_chr[i])) next

    z <- x_chr[i]

    # Text explicitly saying the numeric pH applies elsewhere is not treated as
    # the pH of the current analytical record.
    if (stringr::str_detect(
      stringr::str_to_lower(z),
      "^nr(?:$|[;,:])|optimum elsewhere|numeric value nr|not adsorption-solution ph"
    )) {
      next
    }

    z <- stringr::str_replace_all(
      z,
      "([0-9]+(?:\\.[0-9]+)?)\\s*(?:±|\\+/-)\\s*[0-9]+(?:\\.[0-9]+)?",
      "\\1"
    )

    range_match <- stringr::str_match(
      z,
      "(?i)(?:pH\\s*)?([0-9]+(?:\\.[0-9]+)?)\\s*-\\s*([0-9]+(?:\\.[0-9]+)?)"
    )

    if (!is.na(range_match[1, 2]) && !is.na(range_match[1, 3])) {
      vals <- suppressWarnings(as.numeric(range_match[1, 2:3]))
      if (all(is.finite(vals)) && all(vals >= 0 & vals <= 14)) {
        out[i] <- mean(vals)
        next
      }
    }

    nums <- stringr::str_extract_all(
      z,
      "(?:\\d+(?:\\.\\d*)?|\\.\\d+)"
    )[[1]]
    nums <- suppressWarnings(as.numeric(nums))
    nums <- nums[is.finite(nums) & nums >= 0 & nums <= 14]

    if (length(nums) >= 1L) {
      out[i] <- nums[1]
    }
  }

  out
}

ph_reporting_flag <- function(x) {
  x_chr <- stringr::str_to_lower(normalize_missing(x))
  dplyr::case_when(
    is.na(x_chr) ~ NA_character_,
    stringr::str_detect(
      x_chr,
      "^nr(?:$|[;,:])|not adsorption-solution ph"
    ) ~ "No",
    TRUE ~ "Yes"
  )
}

classify_ph_control <- function(x) {
  x_chr <- stringr::str_to_lower(normalize_missing(x))

  dplyr::case_when(
    is.na(x_chr) ~ "Not reported",
    stringr::str_detect(
      x_chr,
      "^nr(?:$|[;,:])|not adsorption-solution ph"
    ) ~ "Not reported",
    stringr::str_detect(
      x_chr,
      "^no(?:$|[;,:])|free ph|no controlled ph reported"
    ) ~ "Reported but not controlled",
    stringr::str_detect(
      x_chr,
      "continuous(?: control)? nr|continuous nr|continuous control not reported"
    ) ~ "Initial pH only/continuous control unclear",
    stringr::str_detect(x_chr, "maintained|buffered|continuous control") ~ "Controlled",
    stringr::str_detect(x_chr, "adjusted|set to|initial ph|feed ph|desired ph") ~
      "Initial pH only/continuous control unclear",
    TRUE ~ "Reported; control status unclear"
  )
}

classify_water_matrix <- function(x) {
  x_chr <- stringr::str_to_lower(normalize_missing(x))

  dplyr::case_when(
    is.na(x_chr) ~ NA_character_,
    stringr::str_detect(
      x_chr,
      "industrial|river|real|effluent|drilling|battery|wastewater|leachate|groundwater|surface water|natural water|refinery|mud extract"
    ) ~ "Real/environmental",
    stringr::str_detect(
      x_chr,
      "synthetic|simulated|deionized|distilled|ultrapure|aqueous solution|nitrate solution|chloride solution|nacl|buffer|mixed heavy metal"
    ) ~ "Synthetic/laboratory",
    TRUE ~ "Other/unclear"
  )
}


standardize_kinetic_model_label <- function(x) {
  x_chr <- normalize_missing(x)
  x_chr <- stringr::str_squish(x_chr)

  dplyr::case_when(
    is.na(x_chr) ~ NA_character_,
    stringr::str_detect(
      x_chr,
      stringr::regex("^Elovich\\s*/\\s*Fractional power$", ignore_case = TRUE)
    ) ~ "Elovich; Fractional power",
    TRUE ~ x_chr
  )
}

standardize_isotherm_model_label <- function(x) {
  x_chr <- normalize_missing(x)
  x_chr <- stringr::str_squish(x_chr)

  dplyr::case_when(
    is.na(x_chr) ~ NA_character_,
    stringr::str_detect(
      x_chr,
      stringr::regex(
        "^(Sips|Langmuir[-–]Freundlich\\s*\\(Sips\\))$",
        ignore_case = TRUE
      )
    ) ~ "Sips (Langmuir–Freundlich)",
    TRUE ~ x_chr
  )
}

KNOWN_KINETIC_MODELS <- c(
  "Pseudo-first-order",
  "Pseudo-second-order",
  "Elovich",
  "Intraparticle diffusion",
  "Fractional power",
  "Avrami",
  "Bangham",
  "Boyd"
)

KNOWN_ISOTHERM_MODELS <- c(
  "Langmuir",
  "Freundlich",
  "Sips (Langmuir–Freundlich)",
  "Temkin",
  "Dubinin-Radushkevich",
  "Redlich-Peterson",
  "Toth",
  "Jovanovic"
)

normalize_model_token <- function(x) {
  x |>
    normalize_missing() |>
    stringr::str_squish()
}


collapse_unique_values <- function(x, sep = "; ") {
  vals <- sort(unique(stats::na.omit(as.character(x))))
  vals <- vals[vals != ""]
  if (length(vals) == 0L) NA_character_ else paste(vals, collapse = sep)
}

extract_study_year <- function(x) {
  suppressWarnings(
    as.integer(
      stringr::str_extract(
        as.character(x),
        "(?:19|20)\\d{2}"
      )
    )
  )
}

quality_domain_status <- function(proportion_met) {
  dplyr::case_when(
    is.na(proportion_met) ~ "Not assessable",
    proportion_met >= 0.80 ~ "Met",
    proportion_met > 0 ~ "Partial",
    TRUE ~ "Not met/not reported"
  )
}

quality_domain_points <- function(proportion_met) {
  dplyr::case_when(
    is.na(proportion_met) ~ NA_real_,
    proportion_met >= 0.80 ~ 1,
    proportion_met > 0 ~ 0.5,
    TRUE ~ 0
  )
}

flag_log_tukey_outlier <- function(x, multiplier = CONFIG$OUTLIER_IQR_MULTIPLIER) {
  out <- rep(FALSE, length(x))
  ok <- !is.na(x) & x > 0
  if (sum(ok) < 4L) return(out)

  lx <- log10(x[ok])
  q <- stats::quantile(lx, probs = c(0.25, 0.75), na.rm = TRUE, names = FALSE)
  spread <- q[2] - q[1]

  if (!is.finite(spread) || spread == 0) return(out)

  lower <- q[1] - multiplier * spread
  upper <- q[2] + multiplier * spread
  out[ok] <- lx < lower | lx > upper
  out
}

count_study_adsorbents <- function(study_id, adsorbent_id) {
  dplyr::n_distinct(interaction(study_id, adsorbent_id, drop = TRUE))
}

safe_group_n_flag <- function(n, threshold = CONFIG$MIN_GROUP_N_FOR_INTERPRETATION) {
  ifelse(n >= threshold, paste0("n >= ", threshold, "; descriptive summary"), "Sparse: interpret descriptively only")
}

safe_median <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) NA_real_ else median(x)
}

safe_q1 <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) NA_real_ else as.numeric(quantile(x, 0.25, names = FALSE))
}

safe_q3 <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) NA_real_ else as.numeric(quantile(x, 0.75, names = FALSE))
}

safe_iqr <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) < 2) NA_real_ else IQR(x)
}

# Formatting helpers are defined here, before any appraisal or table code uses
# them. Keeping these in the common helper section prevents order-dependent
# failures when later analysis sections are reorganized.
format_number <- function(x, digits = 2) {
  ifelse(
    is.na(x),
    NA_character_,
    formatC(as.numeric(x), format = "f", digits = digits)
  )
}

format_p_value <- function(p) {
  dplyr::case_when(
    is.na(p) ~ NA_character_,
    p < 0.001 ~ "<0.001",
    TRUE ~ formatC(as.numeric(p), format = "f", digits = 3)
  )
}

reviewer_outcome_label <- function(x) {
  dplyr::recode(
    as.character(x),
    qe_reported_mg_g_mid = "Adsorption capacity, qe (mg g^-1)",
    qmax_reported_mg_g_mid = "Model-derived maximum adsorption capacity, qmax (mg g^-1)",
    removal_reported_percent_mid = "Removal efficiency (%)",
    .default = as.character(x)
  )
}

make_median_iqr <- function(data, group_vars, outcome) {
  if (length(group_vars) == 0) {
    return(
      data |>
        summarise(
          n_nonmissing = sum(!is.na(.data[[outcome]])),
          median = safe_median(.data[[outcome]]),
          q1 = safe_q1(.data[[outcome]]),
          q3 = safe_q3(.data[[outcome]]),
          iqr = safe_iqr(.data[[outcome]]),
          min = ifelse(n_nonmissing == 0, NA_real_, min(.data[[outcome]], na.rm = TRUE)),
          max = ifelse(n_nonmissing == 0, NA_real_, max(.data[[outcome]], na.rm = TRUE))
        ) |>
        mutate(outcome = outcome, .before = 1)
    )
  }

  data |>
    group_by(across(all_of(group_vars))) |>
    summarise(
      n_nonmissing = sum(!is.na(.data[[outcome]])),
      median = safe_median(.data[[outcome]]),
      q1 = safe_q1(.data[[outcome]]),
      q3 = safe_q3(.data[[outcome]]),
      iqr = safe_iqr(.data[[outcome]]),
      min = ifelse(n_nonmissing == 0, NA_real_, min(.data[[outcome]], na.rm = TRUE)),
      max = ifelse(n_nonmissing == 0, NA_real_, max(.data[[outcome]], na.rm = TRUE)),
      .groups = "drop"
    ) |>
    mutate(outcome = outcome, .before = 1)
}

save_plot <- function(plot, filename, width = 9, height = 6) {
  ggplot2::ggsave(
    filename = file.path(output_directory, filename),
    plot = plot,
    width = width,
    height = height,
    dpi = 350,
    bg = "white"
  )
}

save_csv <- function(data, filename) {
  readr::write_csv(data, file.path(output_directory, filename))
}


safe_reorder <- function(f, x, fun = sum, missing_label = "Not reported") {
  f_chr <- as.character(f)
  f_chr[is.na(f_chr) | f_chr == ""] <- missing_label

  x_num <- suppressWarnings(as.numeric(x))
  totals <- tapply(x_num, f_chr, fun, na.rm = TRUE)

  if (length(totals) == 0 || all(is.na(totals))) {
    return(factor(f_chr))
  }

  factor(f_chr, levels = names(sort(totals)))
}

collapse_median <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) NA_real_ else median(x)
}

first_nonmissing <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) NA_character_ else as.character(x[1])
}


extract_test_value <- function(test_object, field_name) {
  if (is.list(test_object) && field_name %in% names(test_object)) {
    return(unname(test_object[[field_name]]))
  }

  if (is.atomic(test_object) && !is.null(names(test_object)) &&
      field_name %in% names(test_object)) {
    return(unname(test_object[[field_name]]))
  }

  NA_real_
}

tidy_wilcox_two_group <- function(data, outcome, group_var) {
  test_dat <- data |>
    filter(!is.na(.data[[outcome]]), !is.na(.data[[group_var]])) |>
    mutate(
      outcome_value = .data[[outcome]],
      group_value = droplevels(as.factor(.data[[group_var]]))
    ) |>
    filter(outcome_value > 0)

  group_counts <- test_dat |>
    count(group_value, name = "group_n")

  enough_groups <- nrow(group_counts) == 2 &&
    all(group_counts$group_n >= CONFIG$MIN_GROUP_N_FOR_INTERPRETATION)

  if (!enough_groups) {
    return(tibble(
      outcome = outcome,
      group_variable = group_var,
      test = "Wilcoxon rank-sum",
      n = nrow(test_dat),
      groups = n_distinct(test_dat$group_value),
      minimum_group_n = ifelse(nrow(group_counts) == 0, NA_integer_, min(group_counts$group_n)),
      statistic = NA_real_,
      p_value = NA_real_,
      note = paste0(
        "Not run: requires exactly two groups with at least ",
        CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
        " non-missing observations per group."
      )
    ))
  }

  test_result <- stats::wilcox.test(
    log10(outcome_value) ~ group_value,
    data = test_dat,
    exact = FALSE
  )

  tibble(
    outcome = outcome,
    group_variable = group_var,
    test = "Wilcoxon rank-sum on log10 outcome",
    n = nrow(test_dat),
    groups = n_distinct(test_dat$group_value),
    minimum_group_n = min(group_counts$group_n),
    statistic = extract_test_value(test_result, "statistic"),
    p_value = extract_test_value(test_result, "p.value"),
    note = paste(
      "Exploratory only; dependence-reduced data.",
      "A non-significant result is not evidence of equivalence or parity.",
      "No multiplicity adjustment is applied across the three primary outcomes."
    )
  )
}

tidy_kruskal <- function(data, outcome, group_var) {
  test_dat <- data |>
    filter(!is.na(.data[[outcome]]), !is.na(.data[[group_var]])) |>
    mutate(
      outcome_value = .data[[outcome]],
      group_value = droplevels(as.factor(.data[[group_var]]))
    ) |>
    filter(outcome_value > 0)

  eligible_groups <- test_dat |>
    count(group_value, name = "group_n") |>
    filter(group_n >= CONFIG$MIN_GROUP_N_FOR_INTERPRETATION) |>
    pull(group_value)

  test_dat_eligible <- test_dat |>
    filter(group_value %in% eligible_groups) |>
    mutate(group_value = droplevels(group_value))

  if (n_distinct(test_dat_eligible$group_value) < 2 ||
      nrow(test_dat_eligible) < 2 * CONFIG$MIN_GROUP_N_FOR_INTERPRETATION) {
    return(tibble(
      outcome = outcome,
      group_variable = group_var,
      test = "Kruskal-Wallis",
      n = nrow(test_dat_eligible),
      groups = n_distinct(test_dat_eligible$group_value),
      statistic = NA_real_,
      df = NA_real_,
      p_value = NA_real_,
      note = paste0(
        "Not run after evidence-threshold filtering: requires at least two groups with n >= ",
        CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
        ". Sparse groups remain in descriptive tables but are excluded from this inferential comparison."
      )
    ))
  }

  test_result <- stats::kruskal.test(
    log10(outcome_value) ~ group_value,
    data = test_dat_eligible
  )

  tibble(
    outcome = outcome,
    group_variable = group_var,
    test = "Kruskal-Wallis on log10 outcome",
    n = nrow(test_dat_eligible),
    groups = n_distinct(test_dat_eligible$group_value),
    statistic = extract_test_value(test_result, "statistic"),
    df = extract_test_value(test_result, "parameter"),
    p_value = extract_test_value(test_result, "p.value"),
    note = paste0(
      "Exploratory only; groups with n < ",
      CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
      " are excluded from inferential comparison but retained descriptively. ",
      "Non-significance does not establish equivalence."
    )
  )
}

tidy_pairwise_wilcox <- function(data, outcome, group_var) {
  test_dat <- data |>
    filter(!is.na(.data[[outcome]]), !is.na(.data[[group_var]])) |>
    mutate(
      outcome_value = .data[[outcome]],
      group_value = droplevels(as.factor(.data[[group_var]]))
    ) |>
    filter(outcome_value > 0)

  eligible_groups <- test_dat |>
    count(group_value, name = "group_n") |>
    filter(group_n >= CONFIG$MIN_GROUP_N_FOR_PAIRWISE_TEST) |>
    pull(group_value)

  test_dat_eligible <- test_dat |>
    filter(group_value %in% eligible_groups) |>
    mutate(group_value = droplevels(group_value))

  if (n_distinct(test_dat_eligible$group_value) < 3) {
    return(tibble(
      outcome = outcome,
      group_variable = group_var,
      group_1 = NA_character_,
      group_2 = NA_character_,
      p_value_BH = NA_real_,
      note = paste0(
        "Not run: fewer than three groups meet the prespecified pairwise threshold (n >= ",
        CONFIG$MIN_GROUP_N_FOR_PAIRWISE_TEST,
        ")."
      )
    ))
  }

  pw <- stats::pairwise.wilcox.test(
    x = log10(test_dat_eligible$outcome_value),
    g = test_dat_eligible$group_value,
    p.adjust.method = "BH",
    exact = FALSE
  )

  as.data.frame(as.table(pw$p.value)) |>
    as_tibble() |>
    filter(!is.na(Freq)) |>
    transmute(
      outcome = outcome,
      group_variable = group_var,
      group_1 = as.character(Var1),
      group_2 = as.character(Var2),
      p_value_BH = as.numeric(Freq),
      note = paste0(
        "Exploratory pairwise Wilcoxon tests on log10 outcome; BH-adjusted within outcome. ",
        "Only groups with n >= ", CONFIG$MIN_GROUP_N_FOR_PAIRWISE_TEST,
        " are included; non-significance does not establish equivalence."
      )
    )
}

# Route harmonization only removes spelling/case differences. Incompatible
# classifications remain explicit and are never silently assigned to a route.
route_label <- function(x) {
  x <- stringr::str_squish(as.character(x))
  x[is.na(x) | tolower(x) %in% c("", "nr", "na", "n/a", "not reported", "none reported")] <- NA_character_
  x <- stringr::str_replace_all(x, regex("carbonisation", ignore_case = TRUE), "carbonization")
  x <- stringr::str_replace_all(x, regex("functionalisation", ignore_case = TRUE), "functionalization")
  x
}
reconcile_route <- function(primary, secondary) {
  a <- route_label(primary); b <- route_label(secondary)
  conflict <- !is.na(a) & !is.na(b) & tolower(a) != tolower(b)
  ifelse(conflict, "Unresolved classification differences", coalesce(a, b, "Not reported"))
}
collapse_route <- function(x) {
  values <- sort(unique(as.character(x[!is.na(x) & nzchar(x)])))
  if (!length(values)) return("Not reported")
  if (length(values) == 1L) return(values)
  "Multiple classifications within analytical unit"
}

# 4. IMPORT AND BASIC CLEANING -------------------------------------------------

# Required classification catalogue. It provides documentation and comparison
# only; it never overwrites outcome values or dataset classifications.
if (!file.exists(classification_catalogue_file)) stop(
  "Classification catalogue not found: ", classification_catalogue_file,
  ". Place the classification catalogue beside the extraction CSV or edit classification_catalogue_file above.")
classification_catalogue <- readr::read_csv(classification_catalogue_file,
  locale = readr::locale(encoding = CATALOGUE_ENCODING),
  col_types = readr::cols(.default = readr::col_character()),
  na = character(), show_col_types = FALSE, name_repair = "check_unique")
catalogue_columns <- c("Study ID", "Adsorbent ID", "Precursor", "Preparation route",
  "Activation route", "Modification route", "Treatment agent", "Source location",
  "Notes on classification")
missing_catalogue_columns <- setdiff(catalogue_columns, names(classification_catalogue))
if (length(missing_catalogue_columns)) stop("Catalogue is missing: ",
  paste(missing_catalogue_columns, collapse = ", "))
classification_catalogue <- classification_catalogue |>
  mutate(across(all_of(catalogue_columns), ~ {
    value <- stringr::str_squish(as.character(.x))
    value[!is.na(value) & tolower(value) %in% c("", "null")] <- NA_character_
    value
  })) |>
  rename(study_id = `Study ID`, adsorbent_id = `Adsorbent ID`)
if (any(is.na(classification_catalogue$study_id)) ||
    any(is.na(classification_catalogue$adsorbent_id))) stop("Catalogue contains blank study or adsorbent IDs.")
if (anyDuplicated(classification_catalogue[c("study_id", "adsorbent_id")])) stop(
  "Duplicate study-adsorbent keys in the classification catalogue. Resolve them before joining.")

input_extension <- stringr::str_to_lower(tools::file_ext(input_file))

if (input_extension == "csv") {
  raw <- readr::read_csv(
    file = input_file,
    locale = readr::locale(encoding = INPUT_ENCODING),
    col_types = readr::cols(.default = readr::col_character()),
    na = character(),
    show_col_types = FALSE,
    name_repair = "unique"
  ) |>
    as_tibble()
} else if (input_extension %in% c("xlsx", "xls")) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop(
      "Excel input requires the readxl package. Install it or supply the updated CSV."
    )
  }

  raw <- readxl::read_excel(
    path = input_file,
    sheet = input_sheet,
    col_types = "text",
    na = character()
  ) |>
    as_tibble()
} else {
  stop(
    "Unsupported input extension: .", input_extension,
    ". Supply a .csv, .xlsx, or .xls file."
  )
}

# The updated CSV is a single structured extraction table. The schema now includes
# explicit base feedstock, additive, element, and oxidation-state fields. Any
# preparation and treatment classifications and source locations are retained.
# Unexpected columns are archived separately.
missing_columns <- setdiff(required_columns, names(raw))
unexpected_columns <- setdiff(names(raw), required_columns)

if (length(missing_columns) > 0) {
  stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
}

raw_with_row <- raw |>
  mutate(source_input_row = row_number() + 1L)

if (length(unexpected_columns) > 0) {
  unexpected_input_columns_audit <- raw_with_row |>
    select(source_input_row, all_of(unexpected_columns)) |>
    filter(
      if_any(
        -source_input_row,
        ~ !is.na(.x) & stringr::str_squish(as.character(.x)) != ""
      )
    )

  readr::write_csv(
    unexpected_input_columns_audit,
    file.path(output_directory, "audit_unexpected_input_columns.csv"),
    na = ""
  )

  message(
    "Detected ", length(unexpected_columns),
    " unexpected columns. They were preserved in ",
    "audit_unexpected_input_columns.csv and excluded from core analyses."
  )
}

# Preserve original input-row numbers before any filtering or expansion.
# Rows without study_id are not analytical observations and are retained in an audit.
raw_clean <- raw_with_row |>
  select(all_of(required_columns), source_input_row) |>
  mutate(across(all_of(setdiff(required_columns, route_source_columns)), normalize_missing))

nonrecord_rows <- raw_clean |>
  filter(is.na(study_id))

if (nrow(nonrecord_rows) > 0) {
  readr::write_csv(
    nonrecord_rows,
    file.path(output_directory, "audit_nonrecord_rows_excluded.csv"),
    na = ""
  )
}

raw_clean <- raw_clean |>
  filter(!is.na(study_id))

# Generic safeguard for any future slash-separated multi-metal records.
# The current updated CSV stores metals in separate records, so this section will
# normally produce a zero-row audit file. If slash-separated rows appear later,
# metal, C0, and removal are expanded only when those vectors align.
multi_metal_rows <- raw_clean |>
  filter(stringr::str_detect(metal, "\\s*/\\s*"))

single_metal_rows <- raw_clean |>
  filter(!stringr::str_detect(metal, "\\s*/\\s*") | is.na(metal))

if (nrow(multi_metal_rows) > 0) {
  multi_metal_expanded <- multi_metal_rows |>
    mutate(
      metal = stringr::str_split(metal, "\\s*/\\s*"),
      c0_mg_l_mid = stringr::str_split(c0_mg_l_mid, "\\s*/\\s*"),
      removal_reported_percent_mid = stringr::str_split(
        removal_reported_percent_mid, "\\s*/\\s*"
      )
    ) |>
    tidyr::unnest(c(metal, c0_mg_l_mid, removal_reported_percent_mid)) |>
    mutate(
      removal_reported_percent_mid = stringr::str_remove(
        removal_reported_percent_mid,
        "\\s*\\([^)]*\\)\\s*$"
      )
    )
} else {
  multi_metal_expanded <- multi_metal_rows
}

expanded_raw <- bind_rows(single_metal_rows, multi_metal_expanded) |>
  arrange(source_input_row)

save_csv(
  multi_metal_expanded,
  "audit_expanded_multimetal_rows.csv"
)

numeric_parse_audit <- expanded_raw |>
  pivot_longer(
    cols = all_of(setdiff(numeric_columns, "replicates_n")),
    names_to = "variable",
    values_to = "raw_value"
  ) |>
  mutate(
    strict_value = parse_numeric_strict(raw_value),
    parsed_mid_value = parse_numeric_mid(raw_value),
    parsing_status = case_when(
      is.na(raw_value) ~ "Missing",
      !is.na(strict_value) ~ "Exact scalar",
      !is.na(parsed_mid_value) ~ "Parsed annotation/range/approximation",
      TRUE ~ "Not converted"
    )
  ) |>
  filter(parsing_status != "Exact scalar", parsing_status != "Missing")

save_csv(numeric_parse_audit, "audit_numeric_parsing_nonstandard_values.csv")

dat <- expanded_raw |>
  mutate(
    across(
      all_of(setdiff(numeric_columns, "replicates_n")),
      parse_numeric_mid
    ),
    replicates_n = parse_numeric_strict(replicates_n),
    uncertainty_type = standardize_uncertainty_type(uncertainty_type),
    uncertainty_value_numeric = parse_uncertainty_numeric(uncertainty_value),
    kinetic_model_std = standardize_kinetic_model_label(kinetic_model_std),
    isotherm_model_std = standardize_isotherm_model_label(isotherm_model_std),
    blanks_reported = normalize_yes_no(blanks_reported),
    calibration_reported = normalize_yes_no(calibration_reported),
    ph_mid = parse_ph_mid(ph_controlled),
    ph_control_reported = ph_reporting_flag(ph_controlled),
    ph_control_detail = classify_ph_control(ph_controlled),
    water_matrix_class = classify_water_matrix(water_matrix),

    # Preserve both the reported metal label and the new structured element field.
    metal_raw = metal,
    element_raw = element_std,
    metal_from_label = standardize_metal(metal_raw),
    metal_from_element = standardize_metal(element_std),
    metal = dplyr::coalesce(metal_from_element, metal_from_label),

    # The new data separates the underlying feedstock from additives. Manuscript
    # precursor grouping therefore uses base_feedstock_std, while precursor_std
    # remains available for the full material description.
    precursor_raw = precursor_std,
    base_feedstock_raw = base_feedstock_std,
    precursor_scope_group = standardize_review_precursor(base_feedstock_std),

    preparation_group = coalesce(route_label(preparation_route), "Not reported"),
    activation_group = coalesce(route_label(activation_route), "Not reported"),
    modification_group = coalesce(route_label(modification_route), "Not reported"),
    row_id = row_number(),
    study_id = factor(study_id),
    adsorbent_id = factor(adsorbent_id),
    precursor_std = factor(precursor_std),
    base_feedstock_std = factor(base_feedstock_std),
    additive_std = factor(additive_std),
    activation_type_std = factor(activation_type_std),
    metal = factor(metal),
    water_matrix = factor(water_matrix)
  ) |>
  mutate(
    metal_element_concordant =
      is.na(metal_from_label) |
      is.na(metal_from_element) |
      metal_from_label == metal_from_element,
    oxidation_state_expected = case_when(
      as.character(metal) %in% c("Pb", "Cd", "Cu") ~ "II",
      TRUE ~ NA_character_
    ),
    oxidation_state_concordant =
      is.na(oxidation_state_std) |
      is.na(oxidation_state_expected) |
      oxidation_state_std == oxidation_state_expected,
    in_target_metal_scope = as.character(metal) %in% CONFIG$TARGET_METALS,
    in_target_precursor_scope = !is.na(precursor_scope_group),
    analysis_included =
      in_target_metal_scope &
      in_target_precursor_scope,
    scope_exclusion_reason = purrr::pmap_chr(
      list(in_target_metal_scope, in_target_precursor_scope),
      function(metal_ok, precursor_ok) {
        reasons <- character(0)

        if (!isTRUE(metal_ok)) {
          reasons <- c(reasons, "Metal outside Pb/Cd manuscript scope")
        }
        if (!isTRUE(precursor_ok)) {
          reasons <- c(
            reasons,
            "Base feedstock outside rice husk, sugarcane bagasse, or coconut shell"
          )
        }

        if (length(reasons) == 0L) "Included" else paste(reasons, collapse = "; ")
      }
    )
  )

# Structured-field audit. These flags do not automatically exclude a record;
# they identify rows requiring source/data verification.
structured_field_validation_audit <- dat |>
  filter(!metal_element_concordant | !oxidation_state_concordant) |>
  transmute(
    source_input_row,
    row_id,
    study_id,
    adsorbent_id,
    precursor_std,
    base_feedstock_std,
    additive_std,
    metal_raw,
    element_std,
    oxidation_state_std,
    standardized_metal = as.character(metal),
    metal_element_concordant,
    oxidation_state_expected,
    oxidation_state_concordant,
    validation_issue = case_when(
      !metal_element_concordant & !oxidation_state_concordant ~
        "Metal/element mismatch and oxidation-state mismatch",
      !metal_element_concordant ~ "Metal label and element field disagree",
      !oxidation_state_concordant ~ "Oxidation-state field differs from expected II",
      TRUE ~ "No issue"
    )
  )

save_csv(
  structured_field_validation_audit,
  "audit_structured_metal_fields.csv"
)


# Model-field validation audit -------------------------------------------------
# This audit flags recognized kinetic models appearing in the isotherm field,
# recognized isotherm models appearing in the kinetic field, and unrecognized
# populated labels. It does not silently recode or delete records.
model_field_validation_audit <- dat |>
  transmute(
    source_input_row,
    row_id,
    study_id,
    adsorbent_id,
    metal,
    kinetic_model_std = as.character(kinetic_model_std),
    isotherm_model_std = as.character(isotherm_model_std)
  ) |>
  mutate(
    kinetic_tokens = stringr::str_split(
      dplyr::coalesce(kinetic_model_std, ""),
      "\\s*;\\s*|\\s*\\+\\s*|\\s*,\\s*"
    ),
    isotherm_tokens = stringr::str_split(
      dplyr::coalesce(isotherm_model_std, ""),
      "\\s*;\\s*|\\s*\\+\\s*|\\s*,\\s*"
    )
  ) |>
  tidyr::unnest_longer(kinetic_tokens, values_to = "kinetic_token", keep_empty = TRUE) |>
  tidyr::unnest_longer(isotherm_tokens, values_to = "isotherm_token", keep_empty = TRUE) |>
  mutate(
    kinetic_token = normalize_model_token(kinetic_token),
    isotherm_token = normalize_model_token(isotherm_token),
    kinetic_in_isotherm_field =
      !is.na(isotherm_token) & isotherm_token %in% KNOWN_KINETIC_MODELS,
    isotherm_in_kinetic_field =
      !is.na(kinetic_token) & kinetic_token %in% KNOWN_ISOTHERM_MODELS,
    unrecognized_kinetic_label =
      !is.na(kinetic_token) &
      !(kinetic_token %in% c(KNOWN_KINETIC_MODELS, KNOWN_ISOTHERM_MODELS)),
    unrecognized_isotherm_label =
      !is.na(isotherm_token) &
      !(isotherm_token %in% c(KNOWN_ISOTHERM_MODELS, KNOWN_KINETIC_MODELS))
  ) |>
  filter(
    kinetic_in_isotherm_field |
      isotherm_in_kinetic_field |
      unrecognized_kinetic_label |
      unrecognized_isotherm_label
  ) |>
  distinct(
    source_input_row, row_id, study_id, adsorbent_id, metal,
    kinetic_model_std, isotherm_model_std,
    kinetic_token, isotherm_token,
    kinetic_in_isotherm_field, isotherm_in_kinetic_field,
    unrecognized_kinetic_label, unrecognized_isotherm_label
  )

save_csv(
  model_field_validation_audit,
  "audit_model_field_validation.csv"
)

# Physical-range validation for removal percentage ---------------------------
# Removal efficiency is a percentage and must lie between 0 and 100 inclusive.
# Values outside this range are retained in a dedicated audit output but are
# excluded from completeness summaries, descriptive statistics, tests, tables,
# and figures. No row is deleted and no other outcome is altered.
invalid_removal_percentages <- dat |>
  filter(
    !is.na(removal_reported_percent_mid),
    removal_reported_percent_mid < 0 | removal_reported_percent_mid > 100
  ) |>
  transmute(
    row_id,
    source_input_row,
    study_id,
    adsorbent_id,
    precursor_std,
    precursor_raw,
    base_feedstock_std,
    additive_std,
    precursor_scope_group,
    analysis_included,
    activation_type_std,
    metal,
    water_matrix,
    c0_mg_l_mid,
    adsorbent_dose_g_l_mid,
    contact_time_min_mid,
    ph_controlled,
    ph_mid,
    invalid_removal_percent = removal_reported_percent_mid,
    qe_reported_mg_g_mid,
    qmax_reported_mg_g_mid,
    validation_reason = "Excluded: removal percentage outside physical range 0-100%; verify the source article before assigning a cause."
  )

save_csv(
  invalid_removal_percentages,
  "audit_invalid_removal_percentages.csv"
)

dat <- dat |>
  mutate(
    removal_reported_percent_mid = if_else(
      !is.na(removal_reported_percent_mid) &
        (removal_reported_percent_mid < 0 |
           removal_reported_percent_mid > 100),
      NA_real_,
      removal_reported_percent_mid
    )
  )

# Preserve the complete validated extraction matrix for auditability, then define
# the manuscript-facing Pb/Cd + three-base-feedstock analytical corpus.
dat_all_extracted <- dat

scope_selection_audit <- dat_all_extracted |>
  transmute(
    source_input_row,
    row_id,
    study_id,
    adsorbent_id,
    precursor_raw,
    base_feedstock_raw,
    additive_std,
    precursor_scope_group,
    metal_raw,
    element_std,
    oxidation_state_std,
    metal,
    metal_element_concordant,
    oxidation_state_concordant,
    in_target_metal_scope,
    in_target_precursor_scope,
    analysis_included,
    scope_exclusion_reason
  )

save_csv(scope_selection_audit, "audit_analysis_scope_selection.csv")

# Vocabulary guard ------------------------------------------------------------
# Prevent stale manuscript labels from silently replacing the vocabulary in a
# newly updated extraction file. The target precursor labels should correspond
# directly to observed base_feedstock_std values for the current synthesis.
precursor_vocabulary_audit <- dat_all_extracted |>
  distinct(base_feedstock_std, precursor_scope_group) |>
  arrange(base_feedstock_std, precursor_scope_group)

save_csv(
  precursor_vocabulary_audit,
  "audit_precursor_source_to_analysis_labels.csv"
)

observed_base_feedstocks <- sort(unique(stats::na.omit(
  as.character(dat_all_extracted$base_feedstock_std)
)))
missing_configured_precursors <- setdiff(
  CONFIG$TARGET_PRECURSOR_LEVELS,
  observed_base_feedstocks
)

if (length(missing_configured_precursors) > 0L) {
  stop(
    "Configured target precursor label(s) are not present in base_feedstock_std: ",
    paste(missing_configured_precursors, collapse = ", "),
    ". Check for stale manuscript labels before running the synthesis."
  )
}

out_of_scope_records <- dat_all_extracted |>
  filter(!analysis_included)

save_csv(out_of_scope_records, "audit_records_not_in_primary_synthesis.csv")

dat <- dat_all_extracted |>
  filter(analysis_included) |>
  mutate(
    precursor_std = factor(
      precursor_scope_group,
      levels = CONFIG$TARGET_PRECURSOR_LEVELS
    ),
    metal = factor(as.character(metal), levels = CONFIG$TARGET_METALS)
  ) |>
  droplevels()

if (nrow(dat) == 0L) {
  stop(
    "No rows remain after applying Pb/Cd and final three-base-feedstock filters."
  )
}

analysis_scope_summary <- tibble(
  metric = c(
    "All extraction records",
    "Studies with extracted endpoints",
    "Primary-synthesis records",
    "Primary-synthesis studies",
    "Primary-synthesis study-specific adsorbents",
    "Primary-synthesis precursor groups",
    "Structured metal/oxidation rows flagged for audit"
  ),
  value = c(
    nrow(dat_all_extracted),
    n_distinct(dat_all_extracted$study_id),
    nrow(dat),
    n_distinct(dat$study_id),
    nrow(distinct(dat, study_id, adsorbent_id)),
    n_distinct(dat$precursor_std),
    nrow(structured_field_validation_audit)
  )
)

save_csv(analysis_scope_summary, "analysis_scope_summary.csv")

# Dataset snapshot for this revision. These are descriptive checks, not hard-coded
# acceptance criteria, so future data updates remain analyzable while changes are
# made explicit in the reproducibility record.
dataset_snapshot <- tibble(
  metric = c(
    "Input file",
    "Extraction rows",
    "Unique studies",
    "Unique study-specific adsorbents",
    "Primary-synthesis rows",
    "Primary-synthesis studies",
    "Primary-synthesis study-specific adsorbents",
    "Target metals represented",
    "Target precursor groups represented"
  ),
  value = c(
    basename(input_file),
    as.character(nrow(dat_all_extracted)),
    as.character(n_distinct(dat_all_extracted$study_id)),
    as.character(nrow(distinct(dat_all_extracted, study_id, adsorbent_id))),
    as.character(nrow(dat)),
    as.character(n_distinct(dat$study_id)),
    as.character(nrow(distinct(dat, study_id, adsorbent_id))),
    paste(sort(unique(as.character(dat$metal))), collapse = "; "),
    paste(sort(unique(as.character(dat$precursor_std))), collapse = "; ")
  )
)
save_csv(dataset_snapshot, "dataset_snapshot.csv")

message("Extraction records imported: ", nrow(dat_all_extracted))
message("Studies with extracted endpoints: ", n_distinct(dat_all_extracted$study_id))
message("Primary-synthesis records after scope filters: ", nrow(dat))
message("Primary-synthesis studies: ", n_distinct(dat$study_id))
message(
  "Primary-synthesis study-specific adsorbents: ",
  nrow(distinct(dat, study_id, adsorbent_id))
)
message("Primary-synthesis metals: ", paste(levels(droplevels(dat$metal)), collapse = ", "))
message(
  "Primary-synthesis precursor groups: ",
  paste(levels(droplevels(dat$precursor_std)), collapse = ", ")
)
message(
  "Structured metal/oxidation rows flagged for audit: ",
  nrow(structured_field_validation_audit)
)

# 5. DATA AUDITS ---------------------------------------------------------------

nonnumeric_audit <- expanded_raw |>
  mutate(row_id = row_number()) |>
  pivot_longer(
    cols = all_of(numeric_columns),
    names_to = "variable",
    values_to = "raw_value"
  ) |>
  mutate(
    raw_value_clean = normalize_missing(raw_value),
    parsed_value = if_else(
      variable == "replicates_n",
      parse_numeric_strict(raw_value_clean),
      parse_numeric_mid(raw_value_clean)
    )
  ) |>
  filter(!is.na(raw_value_clean), is.na(parsed_value)) |>
  select(row_id, source_input_row, study_id, adsorbent_id, metal, variable, raw_value)

save_csv(nonnumeric_audit, "audit_nonnumeric_values_in_numeric_columns.csv")

duplicate_keys <- dat |>
  count(study_id, adsorbent_id, metal, name = "rows_per_key") |>
  filter(rows_per_key > 1) |>
  arrange(desc(rows_per_key), study_id, adsorbent_id, metal)

duplicate_rows <- dat |>
  semi_join(duplicate_keys, by = c("study_id", "adsorbent_id", "metal")) |>
  arrange(study_id, adsorbent_id, metal, row_id)

save_csv(duplicate_keys, "audit_duplicate_study_adsorbent_metal_keys.csv")
save_csv(duplicate_rows, "audit_duplicate_key_rows.csv")

# 6. DATA-COMPLETENESS ANALYSIS ------------------------------------------------

# The input schema includes route documentation, but the reporting-completeness
# summary covers the core extraction fields. Use the same explicit set for
# selection and summarisation; keep strict all_of() validation for those fields.
reporting_completeness_columns <- setdiff(required_columns, route_source_columns)
data_completeness_row_level <- dat |>
  select(all_of(reporting_completeness_columns)) |>
  summarise(across(
    all_of(reporting_completeness_columns),
    list(
      reported_n = ~ sum(!is.na(.x)),
      reported_percent = ~ 100 * mean(!is.na(.x))
    ),
    .names = "{.col}_{.fn}"
  )) |>
  pivot_longer(
    everything(),
    names_to = "metric",
    values_to = "value"
  ) |>
  separate(
    metric,
    into = c("variable", "metric"),
    sep = "_(?=reported_n|reported_percent)",
    extra = "merge"
  ) |>
  pivot_wider(names_from = metric, values_from = value) |>
  mutate(
    total_rows = nrow(dat),
    missing_n = total_rows - reported_n,
    missing_percent = 100 - reported_percent
  ) |>
  select(variable, total_rows, reported_n, missing_n,
         reported_percent, missing_percent) |>
  arrange(reported_percent)

save_csv(data_completeness_row_level, "data_completeness_row_level.csv")

# 7. EVIDENCE MAPS -------------------------------------------------------------

evidence_map_metal <- dat |>
  group_by(metal) |>
  summarise(
    rows = n(),
    studies = n_distinct(study_id),
    adsorbents = count_study_adsorbents(study_id, adsorbent_id),
    precursor_groups = n_distinct(precursor_std, na.rm = TRUE),
    activation_types = n_distinct(activation_type_std, na.rm = TRUE),
    water_matrices = n_distinct(water_matrix, na.rm = TRUE),
    has_qe_rows = sum(!is.na(qe_reported_mg_g_mid)),
    has_qmax_rows = sum(!is.na(qmax_reported_mg_g_mid)),
    has_removal_rows = sum(!is.na(removal_reported_percent_mid)),
    .groups = "drop"
  ) |>
  arrange(desc(studies))

evidence_map_precursor <- dat |>
  group_by(precursor_std) |>
  summarise(
    rows = n(),
    studies = n_distinct(study_id),
    adsorbents = count_study_adsorbents(study_id, adsorbent_id),
    metals = paste(sort(unique(na.omit(as.character(metal)))), collapse = "; "),
    has_qe_rows = sum(!is.na(qe_reported_mg_g_mid)),
    has_qmax_rows = sum(!is.na(qmax_reported_mg_g_mid)),
    has_removal_rows = sum(!is.na(removal_reported_percent_mid)),
    .groups = "drop"
  ) |>
  arrange(desc(studies))

evidence_map_activation <- dat |>
  group_by(activation_type_std) |>
  summarise(
    rows = n(),
    studies = n_distinct(study_id),
    adsorbents = count_study_adsorbents(study_id, adsorbent_id),
    metals = paste(sort(unique(na.omit(as.character(metal)))), collapse = "; "),
    precursor_groups = paste(sort(unique(na.omit(as.character(precursor_std)))), collapse = "; "),
    .groups = "drop"
  ) |>
  arrange(desc(studies))

evidence_map_water <- dat |>
  group_by(water_matrix) |>
  summarise(
    rows = n(),
    studies = n_distinct(study_id),
    adsorbents = count_study_adsorbents(study_id, adsorbent_id),
    metals = paste(sort(unique(na.omit(as.character(metal)))), collapse = "; "),
    precursor_groups = paste(sort(unique(na.omit(as.character(precursor_std)))), collapse = "; "),
    .groups = "drop"
  ) |>
  arrange(desc(studies))

evidence_map_cross_precursor_metal <- dat |>
  distinct(study_id, adsorbent_id, precursor_std, metal) |>
  count(precursor_std, metal, name = "study_adsorbent_metal_units") |>
  arrange(precursor_std, metal)

evidence_map_cross_activation_metal <- dat |>
  distinct(study_id, adsorbent_id, activation_type_std, metal) |>
  count(activation_type_std, metal, name = "study_adsorbent_metal_units") |>
  arrange(activation_type_std, metal)

evidence_map_cross_water_metal <- dat |>
  distinct(study_id, adsorbent_id, water_matrix, metal) |>
  count(water_matrix, metal, name = "study_adsorbent_metal_units") |>
  arrange(water_matrix, metal)

save_csv(evidence_map_metal, "evidence_map_by_metal.csv")
save_csv(evidence_map_precursor, "evidence_map_by_precursor.csv")
save_csv(evidence_map_activation, "evidence_map_by_activation_type.csv")
save_csv(evidence_map_water, "evidence_map_by_water_matrix.csv")
save_csv(evidence_map_cross_precursor_metal, "evidence_map_precursor_by_metal.csv")
save_csv(evidence_map_cross_activation_metal, "evidence_map_activation_by_metal.csv")
save_csv(evidence_map_cross_water_metal, "evidence_map_water_matrix_by_metal.csv")

# 8. DEPENDENCE-REDUCED ANALYTICAL DATASET ------------------------------------

analysis_unit <- dat |>
  group_by(study_id, adsorbent_id, metal) |>
  summarise(
    precursor_std = first_nonmissing(precursor_std),
    precursor_raw = paste(
      sort(unique(na.omit(as.character(precursor_raw)))),
      collapse = "; "
    ),
    base_feedstock_std = first_nonmissing(base_feedstock_std),
    additive_std = paste(
      sort(unique(na.omit(as.character(additive_std)))),
      collapse = "; "
    ),
    element_std = first_nonmissing(element_std),
    oxidation_state_std = paste(
      sort(unique(na.omit(as.character(oxidation_state_std)))),
      collapse = "; "
    ),
    activation_type_std = first_nonmissing(activation_type_std),
    water_matrix = first_nonmissing(water_matrix),
    water_matrix_class = first_nonmissing(water_matrix_class),
    activation_temp_c_mid = collapse_median(activation_temp_c_mid),
    c0_mg_l_mid = collapse_median(c0_mg_l_mid),
    adsorbent_dose_g_l_mid = collapse_median(adsorbent_dose_g_l_mid),
    contact_time_min_mid = collapse_median(contact_time_min_mid),
    bet_m2_g_mid = collapse_median(bet_m2_g_mid),
    removal_reported_percent_mid = collapse_median(removal_reported_percent_mid),
    qe_reported_mg_g_mid = collapse_median(qe_reported_mg_g_mid),
    qmax_reported_mg_g_mid = collapse_median(qmax_reported_mg_g_mid),
    regeneration_cycles = collapse_median(regeneration_cycles),
    replicates_n = collapse_median(replicates_n),
    blanks_reported = first_nonmissing(blanks_reported),
    calibration_reported = first_nonmissing(calibration_reported),
    ph_controlled = first_nonmissing(ph_controlled),
    ph_mid = collapse_median(ph_mid),
    ph_control_reported = first_nonmissing(ph_control_reported),
    ph_control_detail = paste(
      sort(unique(na.omit(as.character(ph_control_detail)))),
      collapse = "; "
    ),
    uncertainty_type = paste(sort(unique(na.omit(as.character(uncertainty_type)))),
                             collapse = "; "),
    uncertainty_value = first_nonmissing(uncertainty_value),
    uncertainty_value_numeric = collapse_median(uncertainty_value_numeric),
    kinetic_model_std = paste(sort(unique(na.omit(as.character(kinetic_model_std)))),
                              collapse = "; "),
    isotherm_model_std = paste(sort(unique(na.omit(as.character(isotherm_model_std)))),
                               collapse = "; "),
    source_rows = n(),
    source_input_rows = paste(sort(unique(source_input_row)), collapse = "; "),
    .groups = "drop"
  ) |>
  mutate(
    kinetic_model_std = na_if(kinetic_model_std, ""),
    isotherm_model_std = na_if(isotherm_model_std, ""),
    uncertainty_type = na_if(uncertainty_type, ""),
    precursor_raw = na_if(precursor_raw, ""),
    additive_std = na_if(additive_std, ""),
    oxidation_state_std = na_if(oxidation_state_std, ""),
    ph_control_detail = na_if(ph_control_detail, ""),
    precursor_std = factor(precursor_std),
    activation_type_std = factor(activation_type_std),
    water_matrix = factor(water_matrix),
    water_matrix_class = factor(water_matrix_class),
    metal = factor(metal),
    precipitation_caution_flag = case_when(
      as.character(metal) == "Pb" & !is.na(ph_mid) &
        ph_mid > CONFIG$PB_PRECIPITATION_CAUTION_PH ~ TRUE,
      as.character(metal) == "Cd" & !is.na(ph_mid) &
        ph_mid > CONFIG$CD_PRECIPITATION_CAUTION_PH ~ TRUE,
      TRUE ~ FALSE
    ),
    regeneration_reported = !is.na(regeneration_cycles),
    replicates_reported = !is.na(replicates_n),
    blanks_reporting_available = !is.na(blanks_reported),
    calibration_reporting_available = !is.na(calibration_reported),
    ph_reporting_available = coalesce(ph_control_reported == "Yes", FALSE),
    uncertainty_type_reported = !is.na(uncertainty_type),
    numeric_uncertainty_reported = !is.na(uncertainty_value_numeric),
    uncertainty_outcome_linked = FALSE
  )

# Add classifications only after existing outcome aggregation. No outcome rows
# are duplicated; inconsistent labels within a unit are retained as a mixed group.
route_unit_metadata <- dat |>
  group_by(study_id, adsorbent_id, metal) |>
  summarise(across(c(preparation_group, activation_group, modification_group), collapse_route),
    across(all_of(route_source_columns), ~ paste(sort(unique(na.omit(as.character(.x)))), collapse = "; ")),
    .groups = "drop")
stopifnot(!anyDuplicated(route_unit_metadata[c("study_id", "adsorbent_id", "metal")]))
analysis_unit <- analysis_unit |>
  left_join(route_unit_metadata, by = c("study_id", "adsorbent_id", "metal"))

save_csv(analysis_unit, "analysis_unit_dependence_reduced.csv")


# Reviewer-aligned qmax extreme-value context ---------------------------------
# qmax remains a reported, model-derived quantity. These tables provide context
# for scientifically important minima/maxima without imposing an R2 threshold.
qmax_context <- analysis_unit |>
  filter(!is.na(qmax_reported_mg_g_mid)) |>
  transmute(
    study_id,
    adsorbent_id,
    metal,
    precursor_std,
    precursor_raw,
    base_feedstock_std,
    additive_std,
    preparation_group,
    activation_group,
    modification_group,
    activation_type_std,
    activation_temp_c_mid,
    water_matrix,
    water_matrix_class,
    c0_mg_l_mid,
    adsorbent_dose_g_l_mid,
    contact_time_min_mid,
    ph_mid,
    ph_control_detail,
    bet_m2_g_mid,
    qmax_reported_mg_g_mid,
    isotherm_model_std,
    precipitation_caution_flag,
    source_rows,
    source_input_rows
  )

qmax_extreme_context_overall <- bind_rows(
  qmax_context |>
    slice_min(qmax_reported_mg_g_mid, n = 5, with_ties = TRUE) |>
    mutate(extreme_type = "Lowest model-derived qmax"),
  qmax_context |>
    slice_max(qmax_reported_mg_g_mid, n = 5, with_ties = TRUE) |>
    mutate(extreme_type = "Highest model-derived qmax")
) |>
  arrange(extreme_type, qmax_reported_mg_g_mid)

qmax_extreme_context_by_metal <- bind_rows(
  qmax_context |>
    group_by(metal) |>
    slice_min(qmax_reported_mg_g_mid, n = 3, with_ties = TRUE) |>
    ungroup() |>
    mutate(extreme_type = "Lowest model-derived qmax within metal"),
  qmax_context |>
    group_by(metal) |>
    slice_max(qmax_reported_mg_g_mid, n = 3, with_ties = TRUE) |>
    ungroup() |>
    mutate(extreme_type = "Highest model-derived qmax within metal")
) |>
  arrange(metal, extreme_type, qmax_reported_mg_g_mid)

save_csv(
  qmax_extreme_context_overall,
  "qmax_model_derived_extreme_context_overall.csv"
)
save_csv(
  qmax_extreme_context_by_metal,
  "qmax_model_derived_extreme_context_by_metal.csv"
)

data_completeness_analysis_unit <- analysis_unit |>
  select(-any_of(c(route_source_columns, "preparation_group", "activation_group", "modification_group"))) |>
  select(
    -source_rows,
    -source_input_rows,
    -precipitation_caution_flag,
    -regeneration_reported,
    -replicates_reported,
    -blanks_reporting_available,
    -calibration_reporting_available,
    -ph_reporting_available,
    -uncertainty_type_reported,
    -numeric_uncertainty_reported,
    -uncertainty_outcome_linked
  ) |>
  summarise(across(
    everything(),
    list(
      reported_n = ~ sum(!is.na(.x)),
      reported_percent = ~ 100 * mean(!is.na(.x))
    ),
    .names = "{.col}_{.fn}"
  )) |>
  pivot_longer(everything(), names_to = "metric", values_to = "value") |>
  separate(
    metric,
    into = c("variable", "metric"),
    sep = "_(?=reported_n|reported_percent)",
    extra = "merge"
  ) |>
  pivot_wider(names_from = metric, values_from = value) |>
  mutate(
    total_units = nrow(analysis_unit),
    missing_n = total_units - reported_n,
    missing_percent = 100 - reported_percent
  ) |>
  select(variable, total_units, reported_n, missing_n,
         reported_percent, missing_percent) |>
  arrange(reported_percent)

save_csv(data_completeness_analysis_unit, "data_completeness_dependence_reduced.csv")

# Backward-compatible object name used by the publication-ready section.
data_completeness_dependence_reduced <- data_completeness_analysis_unit

# 9. MEDIAN/IQR DESCRIPTIVE SYNTHESIS -----------------------------------------

outcomes <- c(
  "qe_reported_mg_g_mid",
  "qmax_reported_mg_g_mid",
  "removal_reported_percent_mid"
)

median_iqr_overall <- map_dfr(
  outcomes,
  ~ make_median_iqr(analysis_unit, character(0), .x)
)

median_iqr_by_metal <- map_dfr(
  outcomes,
  ~ make_median_iqr(analysis_unit, "metal", .x)
)

median_iqr_by_precursor <- map_dfr(
  outcomes,
  ~ make_median_iqr(analysis_unit, "precursor_std", .x)
)

median_iqr_by_activation <- map_dfr(
  outcomes,
  ~ make_median_iqr(analysis_unit, "activation_type_std", .x)
)

median_iqr_by_water <- map_dfr(
  outcomes,
  ~ make_median_iqr(analysis_unit, "water_matrix", .x)
)

median_iqr_by_precursor_metal <- map_dfr(
  outcomes,
  ~ make_median_iqr(analysis_unit, c("precursor_std", "metal"), .x)
)

save_csv(median_iqr_overall, "median_iqr_overall.csv")
save_csv(median_iqr_by_metal, "median_iqr_by_metal.csv")
save_csv(median_iqr_by_precursor, "median_iqr_by_precursor.csv")
save_csv(median_iqr_by_activation, "median_iqr_by_activation_type.csv")
save_csv(median_iqr_by_water, "median_iqr_by_water_matrix.csv")
save_csv(median_iqr_by_precursor_metal, "median_iqr_by_precursor_and_metal.csv")

# 10. PB VERSUS CD COMPARISONS -------------------------------------------------

pb_cd_analysis <- analysis_unit |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS) |>
  mutate(metal = droplevels(metal))

pb_cd_tests <- map_dfr(
  outcomes,
  ~ tidy_wilcox_two_group(pb_cd_analysis, outcome = .x, group_var = "metal")
)

pb_cd_group_summaries <- median_iqr_by_metal |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS) |>
  arrange(outcome, metal)

save_csv(pb_cd_tests, "stat_tests_pb_vs_cd.csv")
save_csv(pb_cd_group_summaries, "pb_vs_cd_group_summaries.csv")

# 11. PRECURSOR-GROUP COMPARISONS ---------------------------------------------

precursor_kruskal_tests <- map_dfr(
  outcomes,
  ~ tidy_kruskal(analysis_unit, outcome = .x, group_var = "precursor_std")
)

precursor_pairwise_tests <- map_dfr(
  outcomes,
  ~ tidy_pairwise_wilcox(analysis_unit, outcome = .x, group_var = "precursor_std")
)

precursor_group_summaries <- median_iqr_by_precursor |>
  arrange(outcome, precursor_std)

save_csv(precursor_kruskal_tests, "stat_tests_precursor_kruskal.csv")
save_csv(precursor_pairwise_tests, "stat_tests_precursor_pairwise_wilcox_BH.csv")
save_csv(precursor_group_summaries, "precursor_group_summaries.csv")

# 12. KINETIC AND ISOTHERM MODEL FREQUENCIES ----------------------------------

kinetic_model_frequencies_row_level <- dat |>
  filter(!is.na(kinetic_model_std)) |>
  separate_rows(kinetic_model_std, sep = "\\s*;\\s*|\\s*\\+\\s*|\\s*,\\s*") |>
  mutate(kinetic_model_std = str_squish(kinetic_model_std)) |>
  filter(!is.na(kinetic_model_std), kinetic_model_std != "") |>
  count(metal, kinetic_model_std, name = "rows") |>
  arrange(metal, desc(rows))

isotherm_model_frequencies_row_level <- dat |>
  filter(!is.na(isotherm_model_std)) |>
  separate_rows(isotherm_model_std, sep = "\\s*;\\s*|\\s*\\+\\s*|\\s*,\\s*") |>
  mutate(isotherm_model_std = str_squish(isotherm_model_std)) |>
  filter(!is.na(isotherm_model_std), isotherm_model_std != "") |>
  count(metal, isotherm_model_std, name = "rows") |>
  arrange(metal, desc(rows))

kinetic_model_frequencies_unit_level <- analysis_unit |>
  filter(!is.na(kinetic_model_std)) |>
  separate_rows(kinetic_model_std, sep = "\\s*;\\s*|\\s*\\+\\s*|\\s*,\\s*") |>
  mutate(kinetic_model_std = str_squish(kinetic_model_std)) |>
  filter(!is.na(kinetic_model_std), kinetic_model_std != "") |>
  count(metal, kinetic_model_std, name = "study_adsorbent_metal_units") |>
  arrange(metal, desc(study_adsorbent_metal_units))

isotherm_model_frequencies_unit_level <- analysis_unit |>
  filter(!is.na(isotherm_model_std)) |>
  separate_rows(isotherm_model_std, sep = "\\s*;\\s*|\\s*\\+\\s*|\\s*,\\s*") |>
  mutate(isotherm_model_std = str_squish(isotherm_model_std)) |>
  filter(!is.na(isotherm_model_std), isotherm_model_std != "") |>
  count(metal, isotherm_model_std, name = "study_adsorbent_metal_units") |>
  arrange(metal, desc(study_adsorbent_metal_units))

save_csv(kinetic_model_frequencies_row_level, "kinetic_model_frequencies_row_level.csv")
save_csv(isotherm_model_frequencies_row_level, "isotherm_model_frequencies_row_level.csv")
save_csv(kinetic_model_frequencies_unit_level, "kinetic_model_frequencies_dependence_reduced.csv")
save_csv(isotherm_model_frequencies_unit_level, "isotherm_model_frequencies_dependence_reduced.csv")

# 13. REGENERATION-REPORTING ANALYSIS -----------------------------------------

regeneration_overall <- analysis_unit |>
  summarise(
    units = n(),
    regeneration_reported_units = sum(regeneration_reported),
    regeneration_reported_percent = 100 * mean(regeneration_reported),
    median_regeneration_cycles = safe_median(regeneration_cycles),
    q1_regeneration_cycles = safe_q1(regeneration_cycles),
    q3_regeneration_cycles = safe_q3(regeneration_cycles),
    max_regeneration_cycles = ifelse(
      all(is.na(regeneration_cycles)),
      NA_real_,
      max(regeneration_cycles, na.rm = TRUE)
    )
  )

regeneration_by_metal <- analysis_unit |>
  group_by(metal) |>
  summarise(
    units = n(),
    regeneration_reported_units = sum(regeneration_reported),
    regeneration_reported_percent = 100 * mean(regeneration_reported),
    median_regeneration_cycles = safe_median(regeneration_cycles),
    q1_regeneration_cycles = safe_q1(regeneration_cycles),
    q3_regeneration_cycles = safe_q3(regeneration_cycles),
    max_regeneration_cycles = ifelse(
      all(is.na(regeneration_cycles)),
      NA_real_,
      max(regeneration_cycles, na.rm = TRUE)
    ),
    .groups = "drop"
  )

regeneration_by_precursor <- analysis_unit |>
  group_by(precursor_std) |>
  summarise(
    units = n(),
    regeneration_reported_units = sum(regeneration_reported),
    regeneration_reported_percent = 100 * mean(regeneration_reported),
    median_regeneration_cycles = safe_median(regeneration_cycles),
    q1_regeneration_cycles = safe_q1(regeneration_cycles),
    q3_regeneration_cycles = safe_q3(regeneration_cycles),
    max_regeneration_cycles = ifelse(
      all(is.na(regeneration_cycles)),
      NA_real_,
      max(regeneration_cycles, na.rm = TRUE)
    ),
    .groups = "drop"
  )

regeneration_cross_tab_metal <- analysis_unit |>
  count(metal, regeneration_reported, name = "units") |>
  group_by(metal) |>
  mutate(percent_within_metal = 100 * units / sum(units)) |>
  ungroup()

regeneration_cross_tab_precursor <- analysis_unit |>
  count(precursor_std, regeneration_reported, name = "units") |>
  group_by(precursor_std) |>
  mutate(percent_within_precursor = 100 * units / sum(units)) |>
  ungroup()

save_csv(regeneration_overall, "regeneration_overall.csv")
save_csv(regeneration_by_metal, "regeneration_by_metal.csv")
save_csv(regeneration_by_precursor, "regeneration_by_precursor.csv")
save_csv(regeneration_cross_tab_metal, "regeneration_cross_tab_by_metal.csv")
save_csv(regeneration_cross_tab_precursor, "regeneration_cross_tab_by_precursor.csv")


# Reviewer-aligned matrix realism and practical-evidence summaries -------------
matrix_realism_unit_level <- analysis_unit |>
  transmute(
    study_id,
    adsorbent_id,
    metal,
    precursor_std,
    water_matrix,
    water_matrix_class,
    c0_mg_l_mid,
    adsorbent_dose_g_l_mid,
    contact_time_min_mid,
    ph_mid,
    regeneration_cycles,
    regeneration_reported
  )

matrix_realism_summary <- matrix_realism_unit_level |>
  group_by(water_matrix_class) |>
  summarise(
    analytical_units = n(),
    studies = n_distinct(study_id),
    adsorbents = count_study_adsorbents(study_id, adsorbent_id),
    pb_units = sum(as.character(metal) == "Pb", na.rm = TRUE),
    cd_units = sum(as.character(metal) == "Cd", na.rm = TRUE),
    regeneration_reported_units = sum(regeneration_reported, na.rm = TRUE),
    percent_of_units = 100 * n() / nrow(matrix_realism_unit_level),
    .groups = "drop"
  ) |>
  arrange(desc(analytical_units))

practical_evidence_gap_summary <- tibble(
  evidence_item = c(
    "Synthetic/laboratory water-matrix units",
    "Real/environmental water-matrix units",
    "Units with numeric regeneration cycles",
    "Units with reported pH information",
    "Units with reported replicate count",
    "Units with numeric uncertainty"
  ),
  units = c(
    sum(as.character(analysis_unit$water_matrix_class) == "Synthetic/laboratory", na.rm = TRUE),
    sum(as.character(analysis_unit$water_matrix_class) == "Real/environmental", na.rm = TRUE),
    sum(!is.na(analysis_unit$regeneration_cycles)),
    sum(analysis_unit$ph_reporting_available, na.rm = TRUE),
    sum(analysis_unit$replicates_reported, na.rm = TRUE),
    sum(analysis_unit$numeric_uncertainty_reported, na.rm = TRUE)
  ),
  total_units = nrow(analysis_unit)
) |>
  mutate(percent = 100 * units / total_units)

save_csv(matrix_realism_unit_level, "matrix_realism_unit_level.csv")
save_csv(matrix_realism_summary, "matrix_realism_summary.csv")
save_csv(practical_evidence_gap_summary, "practical_evidence_gap_summary.csv")

# 14. REPRODUCIBILITY AND UNCERTAINTY REPORTING --------------------------------

reporting_quality_overall <- analysis_unit |>
  summarise(
    analytical_units = n(),
    replicates_reported_n = sum(replicates_reported),
    replicates_reported_percent = 100 * mean(replicates_reported),
    blanks_reporting_n = sum(blanks_reporting_available),
    blanks_reporting_percent = 100 * mean(blanks_reporting_available),
    calibration_reporting_n = sum(calibration_reporting_available),
    calibration_reporting_percent = 100 * mean(calibration_reporting_available),
    ph_reporting_n = sum(ph_reporting_available),
    ph_reporting_percent = 100 * mean(ph_reporting_available),
    uncertainty_type_reported_n = sum(uncertainty_type_reported),
    uncertainty_type_reported_percent = 100 * mean(uncertainty_type_reported),
    numeric_uncertainty_reported_n = sum(numeric_uncertainty_reported),
    numeric_uncertainty_reported_percent = 100 * mean(numeric_uncertainty_reported)
  )

reporting_quality_by_metal <- analysis_unit |>
  group_by(metal) |>
  summarise(
    analytical_units = n(),
    replicates_reported_n = sum(replicates_reported),
    uncertainty_type_reported_n = sum(uncertainty_type_reported),
    numeric_uncertainty_reported_n = sum(numeric_uncertainty_reported),
    blanks_reporting_n = sum(blanks_reporting_available),
    calibration_reporting_n = sum(calibration_reporting_available),
    ph_reporting_n = sum(ph_reporting_available),
    .groups = "drop"
  )

uncertainty_type_frequencies <- analysis_unit |>
  filter(!is.na(uncertainty_type), uncertainty_type != "") |>
  separate_rows(uncertainty_type, sep = "\\s*;\\s*") |>
  count(uncertainty_type, name = "analytical_units") |>
  arrange(desc(analytical_units))

meta_analysis_eligibility_audit <- analysis_unit |>
  transmute(
    study_id,
    adsorbent_id,
    metal,
    replicates_n,
    uncertainty_type,
    uncertainty_value,
    uncertainty_value_numeric,
    has_replicates = !is.na(replicates_n),
    has_uncertainty_type = !is.na(uncertainty_type),
    has_numeric_uncertainty = !is.na(uncertainty_value_numeric),
    outcome_specific_uncertainty_link = FALSE,
    inverse_variance_meta_eligible = FALSE,
    reason = case_when(
      is.na(uncertainty_type) ~ "No uncertainty type reported.",
      is.na(uncertainty_value_numeric) ~ "Uncertainty value is absent or not directly numeric.",
      TRUE ~ paste(
        "Uncertainty exists but the input dataset does not encode which adsorption",
        "outcome the value belongs to; variance cannot be assigned safely."
      )
    )
  )

save_csv(reporting_quality_overall, "reporting_quality_overall.csv")
save_csv(reporting_quality_by_metal, "reporting_quality_by_metal.csv")
save_csv(uncertainty_type_frequencies, "uncertainty_type_frequencies.csv")
save_csv(meta_analysis_eligibility_audit, "meta_analysis_eligibility_audit.csv")



# Reviewer-aligned Results output map ------------------------------------------
results_section_output_map <- tribble(
  ~results_section, ~scientific_focus, ~principal_outputs,
  "3.1", "Evidence base, reporting completeness, study characteristics, and methodological quality",
  "analysis_scope_summary.csv; data_completeness_dependence_reduced.csv; evidence_map_by_metal.csv; evidence_map_by_precursor.csv; critical-appraisal outputs; route_classification_text_differences.csv",
  "3.2", "Dependence-reduced adsorption performance",
  "analysis_unit_dependence_reduced.csv; median_iqr_overall.csv; median_iqr_by_metal.csv",
  "3.3", "Comparisons by metal and precursor group",
  "stat_tests_pb_vs_cd.csv; pb_vs_cd_group_summaries.csv; stat_tests_precursor_kruskal.csv; stat_tests_precursor_pairwise_wilcox_BH.csv; precursor_group_summaries.csv",
  "3.4", "Model-derived qmax: model support, extreme values, and sensitivity",
  "qmax_model_derived_extreme_context_overall.csv; qmax_model_derived_extreme_context_by_metal.csv; existing extreme-value, water-matrix, precipitation-caution, aggregation, and leave-one-study-out sensitivity outputs",
  "3.5", "Model reporting, characterisation, and methodological safeguards",
  "kinetic_model_frequencies_dependence_reduced.csv; isotherm_model_frequencies_dependence_reduced.csv; audit_model_field_validation.csv; critical-appraisal outputs",
  "3.6", "Matrix realism, regeneration, and practical evidence gaps",
  "matrix_realism_unit_level.csv; matrix_realism_summary.csv; practical_evidence_gap_summary.csv; regeneration outputs"
)

save_csv(results_section_output_map, "results_section_output_map.csv")

# 15. REVIEWER-RESPONSE ANALYSES ------------------------------------------------
#
# These analyses address reviewer requests for:
# - a dedicated study-level quality/reporting assessment,
# - distributions of experimental conditions by precursor and metal,
# - explicit minimum-evidence thresholds for subgroup interpretation,
# - sensitivity to extreme values and water-matrix restrictions,
# - traceability from input records to dependence-reduced units,
# - tracing minima/maxima and physically invalid removal values,
# - pH-based precipitation-caution screening, and
# - audits for possible kinetic/isotherm field misclassification.
#
# IMPORTANT:
# Critical appraisal is domain-based and adsorption-specific. The extraction
# dataset only pre-seeds evidence; final judgments require article-level source
# verification. Missing reporting is not automatically treated as poor practice,
# and no summed quality score or percentage is calculated. Realistic-water
# applicability is assessed separately from internal validity.


# 15.1 Adsorption-specific domain-based critical appraisal ---------------------
#
# The extraction matrix is used only to PRE-SEED evidence for appraisal.
# Missing extraction fields are not treated as demonstrated poor practice.
# Final domain judgments require article-level verification and should be entered
# in CONFIG$CRITICAL_APPRAISAL_MANUAL_FILE with a short explanation and source
# page/table reference.
#
# Allowed final ratings:
#   Adequate | Concerns | Unclear | Not applicable
#
# No summed score, percentage, or "high-quality" label is calculated.

critical_appraisal_domains <- c(
  "Experimental replication",
  "Blanks and controls",
  "Analytical validity",
  "pH and solution chemistry",
  "Adsorbent preparation and characterization",
  "Outcome measurement and reporting"
)

allowed_appraisal_ratings <- c(
  "Adequate",
  "Concerns",
  "Unclear",
  "Not applicable"
)

# Optional full 51-study roster. If absent, the code can only seed appraisal
# records for studies represented in the current endpoint extraction dataset.
if (file.exists(CONFIG$REVIEW_INCLUDED_STUDY_ROSTER_FILE)) {
  review_included_roster <- readr::read_csv(
    CONFIG$REVIEW_INCLUDED_STUDY_ROSTER_FILE,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  if (!"study_id" %in% names(review_included_roster)) {
    stop(
      "The review-included study roster must contain a 'study_id' column: ",
      CONFIG$REVIEW_INCLUDED_STUDY_ROSTER_FILE
    )
  }

  review_included_roster <- review_included_roster |>
    mutate(study_id = stringr::str_squish(study_id)) |>
    filter(!is.na(study_id), study_id != "") |>
    distinct(study_id, .keep_all = TRUE) |>
    mutate(roster_source = "Author-supplied review-included roster")

  if (nrow(review_included_roster) != CONFIG$SYSTEMATIC_REVIEW_INCLUDED_STUDIES) {
    warning(
      "The supplied review-included roster contains ",
      nrow(review_included_roster),
      " unique study IDs; the PRISMA configuration states ",
      CONFIG$SYSTEMATIC_REVIEW_INCLUDED_STUDIES,
      ". Reconcile this before submission."
    )
  }
} else {
  review_included_roster <- dat_all_extracted |>
    distinct(study_id) |>
    transmute(
      study_id = as.character(study_id),
      roster_source = "Current endpoint extraction dataset only"
    )

  warning(
    "No full review-included study roster was found at '",
    CONFIG$REVIEW_INCLUDED_STUDY_ROSTER_FILE,
    "'. Critical-appraisal seeding is therefore limited to the ",
    nrow(review_included_roster),
    " studies represented in the current endpoint extraction dataset. ",
    "Provide the 51-study roster to complete appraisal coverage."
  )
}

critical_appraisal_roster_gap <- tibble(
  expected_review_included_studies = CONFIG$SYSTEMATIC_REVIEW_INCLUDED_STUDIES,
  study_ids_currently_available_for_appraisal = nrow(review_included_roster),
  missing_study_ids = max(
    0L,
    CONFIG$SYSTEMATIC_REVIEW_INCLUDED_STUDIES - nrow(review_included_roster)
  ),
  action_required = ifelse(
    nrow(review_included_roster) < CONFIG$SYSTEMATIC_REVIEW_INCLUDED_STUDIES,
    paste(
      "Provide review_included_study_roster.csv with all review-included study IDs",
      "before claiming that critical appraisal covers the complete review."
    ),
    "Roster count reconciled; verify identifiers against the screening log."
  )
)

save_csv(
  critical_appraisal_roster_gap,
  "critical_appraisal_roster_coverage_audit.csv"
)

invalid_removal_by_study <- invalid_removal_percentages |>
  count(study_id, name = "invalid_removal_rows") |>
  mutate(study_id = as.character(study_id))

study_appraisal_evidence <- dat_all_extracted |>
  mutate(
    study_id_chr = as.character(study_id),
    primary_synthesis_contributor =
      study_id_chr %in% as.character(unique(dat$study_id))
  ) |>
  group_by(study_id_chr) |>
  summarise(
    endpoint_records = n(),
    primary_synthesis_contributor = any(primary_synthesis_contributor),

    replicate_values = collapse_unique_values(replicates_n),
    has_replicates_ge2 = any(!is.na(replicates_n) & replicates_n >= 2),
    explicit_single_run_only =
      any(!is.na(replicates_n)) &&
      all(replicates_n[!is.na(replicates_n)] < 2),

    blanks_values = collapse_unique_values(blanks_reported),
    blanks_yes = any(blanks_reported == "Yes", na.rm = TRUE),
    blanks_no = any(blanks_reported == "No", na.rm = TRUE),

    calibration_values = collapse_unique_values(calibration_reported),
    calibration_yes = any(calibration_reported == "Yes", na.rm = TRUE),
    calibration_no = any(calibration_reported == "No", na.rm = TRUE),

    ph_detail = collapse_unique_values(ph_control_detail),
    ph_reported = any(!is.na(ph_mid)),
    ph_min = ifelse(
      all(is.na(ph_mid)),
      NA_real_,
      min(ph_mid, na.rm = TRUE)
    ),
    ph_max = ifelse(
      all(is.na(ph_mid)),
      NA_real_,
      max(ph_mid, na.rm = TRUE)
    ),
    water_matrix_classes = collapse_unique_values(water_matrix_class),

    preparation_reported = any(
      !is.na(activation_type_std) |
        !is.na(activation_temp_c_mid) |
        !is.na(additive_std)
    ),
    characterization_reported = any(!is.na(bet_m2_g_mid)),
    activation_types = collapse_unique_values(activation_type_std),
    additives = collapse_unique_values(additive_std),

    qe_n = sum(!is.na(qe_reported_mg_g_mid)),
    qmax_n = sum(!is.na(qmax_reported_mg_g_mid)),
    removal_n = sum(!is.na(removal_reported_percent_mid)),
    uncertainty_reported = any(
      !is.na(uncertainty_type) |
        !is.na(uncertainty_value_numeric)
    ),

    real_environmental_evidence =
      any(water_matrix_class == "Real/environmental", na.rm = TRUE),
    synthetic_laboratory_evidence =
      any(water_matrix_class == "Synthetic/laboratory", na.rm = TRUE),

    .groups = "drop"
  ) |>
  rename(study_id = study_id_chr) |>
  left_join(invalid_removal_by_study, by = "study_id") |>
  mutate(
    invalid_removal_rows = tidyr::replace_na(invalid_removal_rows, 0L),
    realistic_water_applicability = case_when(
      real_environmental_evidence ~ "Real/environmental matrix evidence present",
      synthetic_laboratory_evidence ~ "Synthetic/laboratory evidence only",
      TRUE ~ "Water-matrix applicability unclear from extraction"
    )
  )

appraisal_roster_evidence <- review_included_roster |>
  select(study_id, roster_source) |>
  left_join(study_appraisal_evidence, by = "study_id") |>
  mutate(
    endpoint_records = tidyr::replace_na(endpoint_records, 0L),
    primary_synthesis_contributor =
      tidyr::replace_na(primary_synthesis_contributor, FALSE),
    missing_from_endpoint_extraction = endpoint_records == 0L
  )

# One row per study per appraisal domain. These are evidence seeds only.
critical_appraisal_seed <- bind_rows(
  appraisal_roster_evidence |>
    transmute(
      study_id,
      roster_source,
      primary_synthesis_contributor,
      missing_from_endpoint_extraction,
      domain = "Experimental replication",
      provisional_signal = case_when(
        missing_from_endpoint_extraction ~ "Insufficient extracted evidence",
        has_replicates_ge2 ~ "Positive evidence present",
        explicit_single_run_only ~ "Potential concern flagged",
        TRUE ~ "Insufficient extracted evidence"
      ),
      dataset_evidence = paste0(
        "Extracted replicate values: ",
        dplyr::coalesce(replicate_values, "not reported"),
        "; uncertainty information present: ",
        dplyr::coalesce(as.character(uncertainty_reported), "unknown"),
        ". Verify independence of replicates and treatment of variability in the article."
      )
    ),

  appraisal_roster_evidence |>
    transmute(
      study_id,
      roster_source,
      primary_synthesis_contributor,
      missing_from_endpoint_extraction,
      domain = "Blanks and controls",
      provisional_signal = case_when(
        missing_from_endpoint_extraction ~ "Insufficient extracted evidence",
        blanks_yes ~ "Positive evidence present",
        blanks_no ~ "Potential concern flagged",
        TRUE ~ "Insufficient extracted evidence"
      ),
      dataset_evidence = paste0(
        "Extracted blank/control field: ",
        dplyr::coalesce(blanks_values, "not reported"),
        ". Verify controls for contamination, vessel losses, precipitation, ",
        "and other non-adsorptive removal in the article."
      )
    ),

  appraisal_roster_evidence |>
    transmute(
      study_id,
      roster_source,
      primary_synthesis_contributor,
      missing_from_endpoint_extraction,
      domain = "Analytical validity",
      provisional_signal = case_when(
        missing_from_endpoint_extraction ~ "Insufficient extracted evidence",
        calibration_yes ~ "Positive evidence present",
        calibration_no ~ "Potential concern flagged",
        TRUE ~ "Insufficient extracted evidence"
      ),
      dataset_evidence = paste0(
        "Extracted calibration field: ",
        dplyr::coalesce(calibration_values, "not reported"),
        ". Instrument method, calibration range, standards, detection limits, ",
        "and other analytical QC require article-level verification."
      )
    ),

  appraisal_roster_evidence |>
    transmute(
      study_id,
      roster_source,
      primary_synthesis_contributor,
      missing_from_endpoint_extraction,
      domain = "pH and solution chemistry",
      provisional_signal = case_when(
        missing_from_endpoint_extraction ~ "Insufficient extracted evidence",
        ph_reported ~ "Positive evidence present",
        TRUE ~ "Insufficient extracted evidence"
      ),
      dataset_evidence = paste0(
        "Extracted pH/control detail: ",
        dplyr::coalesce(ph_detail, "not reported"),
        "; pH range from parsed values: ",
        ifelse(is.na(ph_min), "NA", format_number(ph_min, 2)),
        " to ",
        ifelse(is.na(ph_max), "NA", format_number(ph_max, 2)),
        "; water-matrix class(es): ",
        dplyr::coalesce(water_matrix_classes, "not reported"),
        ". Verify competing constituents and precipitation precautions."
      )
    ),

  appraisal_roster_evidence |>
    transmute(
      study_id,
      roster_source,
      primary_synthesis_contributor,
      missing_from_endpoint_extraction,
      domain = "Adsorbent preparation and characterization",
      provisional_signal = case_when(
        missing_from_endpoint_extraction ~ "Insufficient extracted evidence",
        preparation_reported & characterization_reported ~
          "Positive evidence present",
        preparation_reported | characterization_reported ~
          "Partial extracted evidence",
        TRUE ~ "Insufficient extracted evidence"
      ),
      dataset_evidence = paste0(
        "Preparation information present: ",
        dplyr::coalesce(as.character(preparation_reported), "unknown"),
        "; activation type(s): ",
        dplyr::coalesce(activation_types, "not reported"),
        "; additive(s): ",
        dplyr::coalesce(additives, "none/not reported"),
        "; BET reported: ",
        dplyr::coalesce(as.character(characterization_reported), "unknown"),
        ". Verify reproducibility and characterization relevant to uptake."
      )
    ),

  appraisal_roster_evidence |>
    transmute(
      study_id,
      roster_source,
      primary_synthesis_contributor,
      missing_from_endpoint_extraction,
      domain = "Outcome measurement and reporting",
      provisional_signal = case_when(
        missing_from_endpoint_extraction ~ "Insufficient extracted evidence",
        invalid_removal_rows > 0 ~ "Potential concern flagged",
        qe_n + qmax_n + removal_n > 0 ~ "Positive evidence present",
        TRUE ~ "Insufficient extracted evidence"
      ),
      dataset_evidence = paste0(
        "Extracted endpoint counts: qe=", dplyr::coalesce(qe_n, 0L),
        ", qmax=", dplyr::coalesce(qmax_n, 0L),
        ", removal=", dplyr::coalesce(removal_n, 0L),
        "; invalid removal rows=", dplyr::coalesce(invalid_removal_rows, 0L),
        ". Verify units, measured versus fitted capacities, mass balance, ",
        "and model-fitting justification in the article."
      )
    )
) |>
  mutate(
    domain = factor(domain, levels = critical_appraisal_domains),
    provisional_signal = dplyr::coalesce(
      provisional_signal,
      "Insufficient extracted evidence"
    )
  ) |>
  arrange(study_id, domain)

critical_appraisal_manual_template <- critical_appraisal_seed |>
  mutate(
    final_rating = NA_character_,
    explanation = NA_character_,
    page_table_reference = NA_character_,
    appraiser = NA_character_
  )

save_csv(
  critical_appraisal_manual_template,
  "critical_appraisal_manual_template.csv"
)

# If an author-completed appraisal file exists, merge it; otherwise leave final
# ratings blank. This prevents automatic extraction completeness from being
# mislabeled as study validity.
if (file.exists(CONFIG$CRITICAL_APPRAISAL_MANUAL_FILE)) {
  manual_appraisal <- readr::read_csv(
    CONFIG$CRITICAL_APPRAISAL_MANUAL_FILE,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  required_appraisal_columns <- c(
    "study_id",
    "domain",
    "final_rating",
    "explanation",
    "page_table_reference"
  )

  missing_appraisal_columns <- setdiff(
    required_appraisal_columns,
    names(manual_appraisal)
  )

  if (length(missing_appraisal_columns) > 0L) {
    stop(
      "Critical-appraisal file is missing columns: ",
      paste(missing_appraisal_columns, collapse = ", ")
    )
  }

  manual_appraisal <- manual_appraisal |>
    mutate(
      study_id = stringr::str_squish(study_id),
      domain = stringr::str_squish(domain),
      final_rating = stringr::str_squish(final_rating),
      final_rating = na_if(final_rating, ""),
      explanation = normalize_missing(explanation),
      page_table_reference = normalize_missing(page_table_reference)
    )

  invalid_ratings <- manual_appraisal |>
    filter(
      !is.na(final_rating),
      !final_rating %in% allowed_appraisal_ratings
    )

  if (nrow(invalid_ratings) > 0L) {
    stop(
      "Critical-appraisal file contains invalid ratings. Allowed values are: ",
      paste(allowed_appraisal_ratings, collapse = ", ")
    )
  }

  duplicate_appraisals <- manual_appraisal |>
    count(study_id, domain, name = "n") |>
    filter(n > 1)

  if (nrow(duplicate_appraisals) > 0L) {
    stop(
      "Critical-appraisal file contains duplicate study/domain rows. ",
      "Each study must have one row per appraisal domain."
    )
  }

  critical_appraisal <- critical_appraisal_seed |>
    left_join(
      manual_appraisal |>
        select(
          study_id,
          domain,
          final_rating,
          explanation,
          page_table_reference,
          any_of("appraiser")
        ),
      by = c("study_id", "domain")
    )
} else {
  critical_appraisal <- critical_appraisal_seed |>
    mutate(
      final_rating = NA_character_,
      explanation = NA_character_,
      page_table_reference = NA_character_,
      appraiser = NA_character_
    )
}

critical_appraisal <- critical_appraisal |>
  mutate(
    appraisal_complete =
      !is.na(final_rating) &
      !is.na(explanation) &
      !is.na(page_table_reference),
    completion_status = if_else(
      appraisal_complete,
      "Complete",
      "Pending source verification"
    )
  )

critical_appraisal_domain_summary <- critical_appraisal |>
  mutate(
    summary_rating = if_else(
      appraisal_complete,
      final_rating,
      "Pending source verification"
    )
  ) |>
  count(domain, summary_rating, name = "studies") |>
  group_by(domain) |>
  mutate(percent_within_domain = 100 * studies / sum(studies)) |>
  ungroup()

save_csv(
  critical_appraisal,
  "critical_appraisal_domain_based.csv"
)
save_csv(
  critical_appraisal_domain_summary,
  "critical_appraisal_domain_summary.csv"
)

# Realistic-water applicability is deliberately kept separate from internal
# validity/critical appraisal.
realistic_water_applicability_by_study <- appraisal_roster_evidence |>
  transmute(
    study_id,
    primary_synthesis_contributor,
    endpoint_records,
    realistic_water_applicability = dplyr::coalesce(
      realistic_water_applicability,
      "No endpoint extraction data available"
    )
  )

save_csv(
  realistic_water_applicability_by_study,
  "realistic_water_applicability_by_study.csv"
)

# Reviewer agreement is produced only if actual independent reviewer ratings
# are supplied. No empty agreement table is created.
reviewer_agreement_summary <- NULL

if (file.exists(CONFIG$REVIEWER_AGREEMENT_FILE)) {
  reviewer_ratings <- readr::read_csv(
    CONFIG$REVIEWER_AGREEMENT_FILE,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  required_reviewer_columns <- c(
    "study_id",
    "domain",
    "reviewer_1_rating",
    "reviewer_2_rating"
  )

  missing_reviewer_columns <- setdiff(
    required_reviewer_columns,
    names(reviewer_ratings)
  )

  if (length(missing_reviewer_columns) > 0L) {
    stop(
      "Reviewer-agreement file is missing columns: ",
      paste(missing_reviewer_columns, collapse = ", ")
    )
  }

  reviewer_ratings <- reviewer_ratings |>
    mutate(
      across(
        c(reviewer_1_rating, reviewer_2_rating),
        ~ na_if(stringr::str_squish(.x), "")
      )
    ) |>
    filter(
      !is.na(reviewer_1_rating),
      !is.na(reviewer_2_rating)
    )

  invalid_reviewer_rating <- reviewer_ratings |>
    filter(
      !reviewer_1_rating %in% allowed_appraisal_ratings |
        !reviewer_2_rating %in% allowed_appraisal_ratings
    )

  if (nrow(invalid_reviewer_rating) > 0L) {
    stop(
      "Reviewer-agreement file contains ratings outside the allowed appraisal categories."
    )
  }

  reviewer_agreement_detail <- reviewer_ratings |>
    mutate(agreement = reviewer_1_rating == reviewer_2_rating)

  reviewer_agreement_summary <- reviewer_agreement_detail |>
    summarise(
      independently_double_rated_domains = n(),
      agreements = sum(agreement),
      percent_agreement = 100 * mean(agreement)
    )

  save_csv(
    reviewer_agreement_detail,
    "critical_appraisal_reviewer_agreement_detail.csv"
  )
  save_csv(
    reviewer_agreement_summary,
    "critical_appraisal_reviewer_agreement_summary.csv"
  )
}


# 15.2 Record-to-analysis-unit crosswalk ---------------------------------------

record_to_analysis_unit_crosswalk <- dat |>
  mutate(
    analysis_unit_id = paste(
      as.character(study_id),
      as.character(adsorbent_id),
      as.character(metal),
      sep = " | "
    )
  ) |>
  select(
    source_input_row,
    row_id,
    analysis_unit_id,
    study_id,
    adsorbent_id,
    precursor_std,
    base_feedstock_std,
    additive_std,
    element_std,
    oxidation_state_std,
    activation_type_std,
    activation_temp_c_mid,
    metal_raw,
    metal,
    water_matrix,
    water_matrix_class,
    c0_mg_l_mid,
    adsorbent_dose_g_l_mid,
    contact_time_min_mid,
    bet_m2_g_mid,
    ph_controlled,
    ph_mid,
    removal_reported_percent_mid,
    qe_reported_mg_g_mid,
    qmax_reported_mg_g_mid,
    kinetic_model_std,
    isotherm_model_std,
    regeneration_cycles,
    replicates_n,
    blanks_reported,
    calibration_reported,
    uncertainty_type,
    uncertainty_value
  ) |>
  arrange(study_id, adsorbent_id, metal, source_input_row)

save_csv(
  record_to_analysis_unit_crosswalk,
  "supplement_record_to_analysis_unit_crosswalk.csv"
)

# 15.3 Experimental-condition heterogeneity -----------------------------------

condition_variables <- c(
  "activation_temp_c_mid",
  "c0_mg_l_mid",
  "adsorbent_dose_g_l_mid",
  "contact_time_min_mid",
  "bet_m2_g_mid",
  "ph_mid"
)

condition_labels <- c(
  activation_temp_c_mid = "Activation temperature (deg C)",
  c0_mg_l_mid = "Initial concentration (mg/L)",
  adsorbent_dose_g_l_mid = "Adsorbent dose (g/L)",
  contact_time_min_mid = "Contact time (min)",
  bet_m2_g_mid = "BET surface area (m2/g)",
  ph_mid = "Reported pH midpoint"
)

condition_summary_by_precursor <- purrr::map_dfr(
  condition_variables,
  ~ make_median_iqr(analysis_unit, "precursor_std", .x)
) |>
  mutate(
    condition = recode(outcome, !!!condition_labels),
    evidence_flag = safe_group_n_flag(n_nonmissing)
  ) |>
  select(condition, precursor_std, everything(), -outcome)

condition_summary_by_metal <- purrr::map_dfr(
  condition_variables,
  ~ make_median_iqr(analysis_unit, "metal", .x)
) |>
  mutate(
    condition = recode(outcome, !!!condition_labels),
    evidence_flag = safe_group_n_flag(n_nonmissing)
  ) |>
  select(condition, metal, everything(), -outcome)

condition_kruskal_by_precursor <- purrr::map_dfr(
  condition_variables,
  ~ tidy_kruskal(analysis_unit, outcome = .x, group_var = "precursor_std")
) |>
  mutate(
    condition = recode(outcome, !!!condition_labels),
    interpretation_note = paste(
      "Exploratory only. Differences indicate heterogeneity of study conditions,",
      "not causal effects of precursor."
    )
  )

save_csv(
  condition_summary_by_precursor,
  "experimental_conditions_by_precursor.csv"
)
save_csv(
  condition_summary_by_metal,
  "experimental_conditions_by_metal.csv"
)
save_csv(
  condition_kruskal_by_precursor,
  "experimental_conditions_kruskal_by_precursor.csv"
)

condition_long_for_plot <- analysis_unit |>
  select(precursor_std, all_of(setdiff(condition_variables, "ph_mid"))) |>
  pivot_longer(
    cols = all_of(setdiff(condition_variables, "ph_mid")),
    names_to = "condition",
    values_to = "value"
  ) |>
  filter(!is.na(value), value > 0) |>
  mutate(condition = recode(condition, !!!condition_labels))

figure_experimental_conditions_precursor <- condition_long_for_plot |>
  ggplot(aes(x = precursor_std, y = value)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.45, size = 1.3) +
  scale_y_log10(labels = label_number()) +
  coord_flip() +
  facet_wrap(~ condition, scales = "free_y", ncol = 2) +
  labs(
    x = NULL,
    y = "Reported value (log10 scale)",
    title = "Experimental-condition heterogeneity across precursor groups",
    subtitle = paste0(
      "Dependence-reduced units; sparse groups (<",
      CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
      ") should be interpreted descriptively."
    )
  ) +
  theme_minimal(base_size = 11)

save_plot(
  figure_experimental_conditions_precursor,
  "figure_experimental_conditions_by_precursor.png",
  width = 11,
  height = 9
)

figure_ph_precursor <- analysis_unit |>
  filter(!is.na(ph_mid)) |>
  ggplot(aes(x = precursor_std, y = ph_mid)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.55, size = 1.5) +
  coord_flip() +
  labs(
    x = NULL,
    y = "Reported pH midpoint",
    title = "Reported pH across precursor groups",
    subtitle = "pH midpoints were parsed from the free-text pH-control field when numeric values were available."
  ) +
  theme_minimal(base_size = 11)

save_plot(
  figure_ph_precursor,
  "figure_reported_pH_by_precursor.png",
  width = 8,
  height = 6
)

# 15.4 Evidence thresholds for subgroup interpretation -------------------------

outcomes <- c(
  "qe_reported_mg_g_mid",
  "qmax_reported_mg_g_mid",
  "removal_reported_percent_mid"
)

evidence_adequacy_precursor <- analysis_unit |>
  select(precursor_std, all_of(outcomes)) |>
  pivot_longer(
    cols = all_of(outcomes),
    names_to = "outcome",
    values_to = "value"
  ) |>
  group_by(outcome, precursor_std) |>
  summarise(n_nonmissing = sum(!is.na(value)), .groups = "drop") |>
  mutate(
    threshold = CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
    evidence_flag = safe_group_n_flag(n_nonmissing),
    include_in_interpretive_comparison =
      n_nonmissing >= CONFIG$MIN_GROUP_N_FOR_INTERPRETATION
  )

evidence_adequacy_metal <- analysis_unit |>
  select(metal, all_of(outcomes)) |>
  pivot_longer(
    cols = all_of(outcomes),
    names_to = "outcome",
    values_to = "value"
  ) |>
  group_by(outcome, metal) |>
  summarise(n_nonmissing = sum(!is.na(value)), .groups = "drop") |>
  mutate(
    threshold = CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
    evidence_flag = safe_group_n_flag(n_nonmissing),
    include_in_interpretive_comparison =
      n_nonmissing >= CONFIG$MIN_GROUP_N_FOR_INTERPRETATION
  )

save_csv(evidence_adequacy_precursor, "evidence_adequacy_by_precursor_and_outcome.csv")
save_csv(evidence_adequacy_metal, "evidence_adequacy_by_metal_and_outcome.csv")

# 15.5 Extreme-value identification and source tracing -------------------------

analysis_unit_sensitivity <- analysis_unit |>
  mutate(
    qe_extreme = flag_log_tukey_outlier(qe_reported_mg_g_mid),
    qmax_extreme = flag_log_tukey_outlier(qmax_reported_mg_g_mid),
    removal_extreme = flag_log_tukey_outlier(removal_reported_percent_mid)
  )

outcome_long_trace <- analysis_unit_sensitivity |>
  select(
    study_id, adsorbent_id, precursor_std, base_feedstock_std, additive_std,
    activation_type_std,
    activation_temp_c_mid, metal, water_matrix, water_matrix_class,
    c0_mg_l_mid, adsorbent_dose_g_l_mid, contact_time_min_mid,
    bet_m2_g_mid, ph_controlled, ph_mid, precipitation_caution_flag,
    source_rows, source_input_rows,
    qe_reported_mg_g_mid, qmax_reported_mg_g_mid,
    removal_reported_percent_mid,
    qe_extreme, qmax_extreme, removal_extreme
  ) |>
  pivot_longer(
    cols = all_of(outcomes),
    names_to = "outcome",
    values_to = "value"
  ) |>
  mutate(
    tukey_extreme = case_when(
      outcome == "qe_reported_mg_g_mid" ~ qe_extreme,
      outcome == "qmax_reported_mg_g_mid" ~ qmax_extreme,
      outcome == "removal_reported_percent_mid" ~ removal_extreme,
      TRUE ~ FALSE
    )
  ) |>
  select(-qe_extreme, -qmax_extreme, -removal_extreme)

minimum_trace <- outcome_long_trace |>
  filter(!is.na(value)) |>
  group_by(outcome) |>
  slice_min(value, n = 1, with_ties = TRUE) |>
  ungroup() |>
  mutate(extreme_position = "Minimum")

maximum_trace <- outcome_long_trace |>
  filter(!is.na(value)) |>
  group_by(outcome) |>
  slice_max(value, n = 1, with_ties = TRUE) |>
  ungroup() |>
  mutate(extreme_position = "Maximum")

outcome_minimum_maximum_source_trace <- bind_rows(minimum_trace, maximum_trace) |>
  arrange(outcome, extreme_position)

tukey_extreme_source_trace <- outcome_long_trace |>
  filter(tukey_extreme) |>
  arrange(outcome, desc(value))

top_outcomes_source_trace <- outcome_long_trace |>
  filter(!is.na(value)) |>
  group_by(outcome) |>
  slice_max(value, n = 5, with_ties = TRUE) |>
  ungroup() |>
  arrange(outcome, desc(value))

save_csv(
  outcome_minimum_maximum_source_trace,
  "outcome_minimum_maximum_source_trace.csv"
)
save_csv(
  tukey_extreme_source_trace,
  "outcome_log_tukey_extreme_source_trace.csv"
)
save_csv(
  top_outcomes_source_trace,
  "outcome_top5_source_trace.csv"
)

# 15.6 pH / precipitation-caution audit ----------------------------------------
#
# These flags implement the reviewer-provided screening boundaries (>6 for Pb
# and >8 for Cd). They are NOT proof that precipitation occurred. They identify
# observations that should be checked against speciation, experimental methods,
# and the original paper before adsorption is interpreted mechanistically.

precipitation_caution_units <- analysis_unit_sensitivity |>
  filter(precipitation_caution_flag) |>
  mutate(
    reviewer_screening_threshold = case_when(
      as.character(metal) == "Pb" ~ paste0(
        "pH > ", CONFIG$PB_PRECIPITATION_CAUTION_PH
      ),
      as.character(metal) == "Cd" ~ paste0(
        "pH > ", CONFIG$CD_PRECIPITATION_CAUTION_PH
      ),
      TRUE ~ NA_character_
    ),
    caution = paste(
      "Reviewer-threshold screening flag only;",
      "verify precipitation/speciation in the source study."
    )
  ) |>
  select(
    study_id, adsorbent_id, precursor_std, base_feedstock_std, additive_std,
    activation_type_std, metal,
    water_matrix, ph_controlled, ph_mid, reviewer_screening_threshold,
    qe_reported_mg_g_mid, qmax_reported_mg_g_mid,
    removal_reported_percent_mid, source_input_rows, caution
  )

save_csv(
  precipitation_caution_units,
  "audit_pH_precipitation_caution_units.csv"
)

# 15.7 Water-matrix and extreme-value sensitivity analyses ---------------------

make_sensitivity_scenario <- function(data, outcome, scenario) {
  out <- data

  if (scenario == "All valid units") {
    return(out)
  }

  if (scenario == "Exclude log-Tukey extremes") {
    flag_col <- dplyr::case_when(
      outcome == "qe_reported_mg_g_mid" ~ "qe_extreme",
      outcome == "qmax_reported_mg_g_mid" ~ "qmax_extreme",
      TRUE ~ "removal_extreme"
    )
    return(out |> filter(!.data[[flag_col]]))
  }

  if (scenario == "Synthetic/laboratory matrices only") {
    return(out |> filter(as.character(water_matrix_class) == "Synthetic/laboratory"))
  }

  if (scenario == "Real/environmental matrices only") {
    return(out |> filter(as.character(water_matrix_class) == "Real/environmental"))
  }

  if (scenario == "Exclude pH precipitation-caution units") {
    return(out |> filter(!precipitation_caution_flag))
  }

  stop("Unknown sensitivity scenario: ", scenario)
}

sensitivity_scenarios <- c(
  "All valid units",
  "Exclude log-Tukey extremes",
  "Synthetic/laboratory matrices only",
  "Real/environmental matrices only",
  "Exclude pH precipitation-caution units"
)

sensitivity_by_metal <- purrr::map_dfr(
  outcomes,
  function(outcome_name) {
    purrr::map_dfr(
      sensitivity_scenarios,
      function(scenario_name) {
        scenario_data <- make_sensitivity_scenario(
          analysis_unit_sensitivity,
          outcome_name,
          scenario_name
        )

        make_median_iqr(
          scenario_data,
          "metal",
          outcome_name
        ) |>
          mutate(
            scenario = scenario_name,
            evidence_flag = safe_group_n_flag(n_nonmissing),
            .before = 1
          )
      }
    )
  }
)

sensitivity_by_precursor <- purrr::map_dfr(
  outcomes,
  function(outcome_name) {
    purrr::map_dfr(
      sensitivity_scenarios,
      function(scenario_name) {
        scenario_data <- make_sensitivity_scenario(
          analysis_unit_sensitivity,
          outcome_name,
          scenario_name
        )

        make_median_iqr(
          scenario_data,
          "precursor_std",
          outcome_name
        ) |>
          mutate(
            scenario = scenario_name,
            evidence_flag = safe_group_n_flag(n_nonmissing),
            .before = 1
          )
      }
    )
  }
)

sensitivity_pb_cd_tests <- purrr::map_dfr(
  outcomes,
  function(outcome_name) {
    purrr::map_dfr(
      sensitivity_scenarios,
      function(scenario_name) {
        scenario_data <- make_sensitivity_scenario(
          analysis_unit_sensitivity,
          outcome_name,
          scenario_name
        ) |>
          filter(as.character(metal) %in% CONFIG$TARGET_METALS) |>
          droplevels()

        tidy_wilcox_two_group(
          scenario_data,
          outcome = outcome_name,
          group_var = "metal"
        ) |>
          mutate(scenario = scenario_name, .before = 1)
      }
    )
  }
)

sensitivity_precursor_tests <- purrr::map_dfr(
  outcomes,
  function(outcome_name) {
    purrr::map_dfr(
      sensitivity_scenarios,
      function(scenario_name) {
        scenario_data <- make_sensitivity_scenario(
          analysis_unit_sensitivity,
          outcome_name,
          scenario_name
        )

        tidy_kruskal(
          scenario_data,
          outcome = outcome_name,
          group_var = "precursor_std"
        ) |>
          mutate(scenario = scenario_name, .before = 1)
      }
    )
  }
)

save_csv(sensitivity_by_metal, "sensitivity_outcomes_by_metal.csv")
save_csv(sensitivity_by_precursor, "sensitivity_outcomes_by_precursor.csv")
save_csv(sensitivity_pb_cd_tests, "sensitivity_tests_pb_vs_cd.csv")
save_csv(sensitivity_precursor_tests, "sensitivity_tests_precursor_kruskal.csv")

# 15.8 Water-matrix class summaries --------------------------------------------

water_matrix_class_summary <- analysis_unit_sensitivity |>
  group_by(water_matrix_class) |>
  summarise(
    analytical_units = n(),
    studies = n_distinct(study_id),
    adsorbents = count_study_adsorbents(study_id, adsorbent_id),
    qe_n = sum(!is.na(qe_reported_mg_g_mid)),
    qmax_n = sum(!is.na(qmax_reported_mg_g_mid)),
    removal_n = sum(!is.na(removal_reported_percent_mid)),
    .groups = "drop"
  )

outcomes_by_water_matrix_class <- purrr::map_dfr(
  outcomes,
  ~ make_median_iqr(
    analysis_unit_sensitivity,
    "water_matrix_class",
    .x
  )
) |>
  mutate(evidence_flag = safe_group_n_flag(n_nonmissing))

save_csv(water_matrix_class_summary, "water_matrix_class_summary.csv")
save_csv(
  outcomes_by_water_matrix_class,
  "outcomes_by_water_matrix_class.csv"
)

# 15.9 Possible model-field misclassification audit ----------------------------
#
# This is a conservative text-screening audit, not source-paper verification.
# Every flagged entry must be checked against the original article before the
# extraction is changed.

kinetic_name_pattern <- stringr::regex(
  "pseudo[- ]?first|pseudo[- ]?second|elovich|intraparticle|weber|morris|thomas|yoon|nelson",
  ignore_case = TRUE
)

isotherm_name_pattern <- stringr::regex(
  "langmuir|freundlich|sips|temkin|redlich|peterson|dubinin|radushkevich|toth",
  ignore_case = TRUE
)

possible_model_field_misclassification <- bind_rows(
  dat |>
    filter(
      !is.na(kinetic_model_std),
      stringr::str_detect(as.character(kinetic_model_std), isotherm_name_pattern)
    ) |>
    transmute(
      source_input_row,
      study_id,
      adsorbent_id,
      metal,
      field = "kinetic_model_std",
      value = as.character(kinetic_model_std),
      reason = "Contains terminology more commonly associated with equilibrium/isotherm models.",
      action = "Verify against the original paper; do not auto-correct."
    ),
  dat |>
    filter(
      !is.na(isotherm_model_std),
      stringr::str_detect(as.character(isotherm_model_std), kinetic_name_pattern)
    ) |>
    transmute(
      source_input_row,
      study_id,
      adsorbent_id,
      metal,
      field = "isotherm_model_std",
      value = as.character(isotherm_model_std),
      reason = "Contains terminology more commonly associated with kinetic/breakthrough models.",
      action = "Verify against the original paper; do not auto-correct."
    )
) |>
  distinct() |>
  arrange(study_id, source_input_row, field)

save_csv(
  possible_model_field_misclassification,
  "audit_possible_model_field_misclassification.csv"
)

# 15.10 Reviewer-response analysis manifest ------------------------------------

reviewer_response_analysis_manifest <- tibble(
  reviewer_request = c(
    "Adsorption-specific critical appraisal",
    "Record-to-final-unit traceability",
    "Experimental-condition distributions by precursor and metal",
    "Minimum evidence threshold for subgroup interpretation",
    "Trace maximum/minimum outcomes to source records",
    "Extreme-value sensitivity analysis",
    "Water-matrix sensitivity analysis",
    "pH / precipitation-boundary screening",
    "Check kinetic/isotherm extraction fields"
  ),
  code_output = c(
    "critical_appraisal_domain_based.csv; critical_appraisal_manual_template.csv",
    "supplement_record_to_analysis_unit_crosswalk.csv",
    "experimental_conditions_by_precursor.csv; experimental_conditions_by_metal.csv",
    "evidence_adequacy_by_precursor_and_outcome.csv",
    "outcome_minimum_maximum_source_trace.csv",
    "sensitivity_outcomes_by_metal.csv; sensitivity_outcomes_by_precursor.csv",
    "water_matrix_class_summary.csv; sensitivity_outcomes_by_metal.csv",
    "audit_pH_precipitation_caution_units.csv",
    "audit_possible_model_field_misclassification.csv"
  ),
  limitation = c(
    paste(
      "Six domains use Adequate/Concerns/Unclear/Not applicable only after",
      "article-level verification with explanation and page/table reference.",
      "Missing information is not scored as poor practice and no total score is used."
    ),
    "Links each input row to the standardized study-adsorbent-metal analytical unit.",
    "Descriptive heterogeneity does not establish confounding causally.",
    paste0(
      "Threshold is prespecified at n >= ",
      CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
      " and can be changed in CONFIG."
    ),
    "Source rows identify extremes but the original papers must be checked before interpretation.",
    "Extreme exclusion is a sensitivity scenario, not automatic data deletion.",
    "Real/environmental subsets may be sparse; sample sizes are reported explicitly.",
    "pH thresholds are caution screens only and do not prove precipitation.",
    "Text screening flags possible field problems; correction requires verification against the original paper."
  )
)

save_csv(
  reviewer_response_analysis_manifest,
  "reviewer_response_analysis_manifest.csv"
)


# 16. SHARED PRESENTATION HELPERS ---------------------------------------------
# One publication export workflow is used below.
publication_directory <- file.path(output_directory, "publication")
dir.create(publication_directory, recursive = TRUE, showWarnings = FALSE)

publication_theme <- function(base_size = CONFIG$FIGURE_BASE_SIZE) {
  ggplot2::theme_bw(
    base_size = base_size,
    base_family = CONFIG$FIGURE_FONT_FAMILY
  ) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(
        face = "bold",
        hjust = 0,
        size = base_size + 2,
        margin = ggplot2::margin(b = 5)
      ),
      plot.subtitle = ggplot2::element_text(
        hjust = 0,
        size = base_size,
        margin = ggplot2::margin(b = 8)
      ),
      plot.caption = ggplot2::element_text(
        hjust = 0,
        size = max(7.5, base_size - 2),
        colour = "grey30",
        margin = ggplot2::margin(t = 8)
      ),
      axis.title = ggplot2::element_text(face = "bold"),
      axis.text = ggplot2::element_text(colour = "black"),
      legend.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom",
      strip.background = ggplot2::element_rect(
        fill = "grey95",
        colour = NA
      ),
      strip.text = ggplot2::element_text(face = "bold"),
      plot.margin = ggplot2::margin(10, 12, 10, 10)
    )
}

make_publication_flextable <- function(
    data,
    caption,
    left_columns = 1L,
    font_size = CONFIG$TABLE_FONT_SIZE,
    footnote = NULL
) {
  if (!requireNamespace("flextable", quietly = TRUE)) {
    return(NULL)
  }

  data <- as.data.frame(data)

  ft <- flextable::flextable(data) |>
    flextable::set_caption(caption = caption) |>
    flextable::theme_booktabs() |>
    flextable::font(
      fontname = CONFIG$TABLE_FONT_FAMILY,
      part = "all"
    ) |>
    flextable::fontsize(
      size = font_size,
      part = "all"
    ) |>
    flextable::bold(part = "header") |>
    flextable::align(
      align = "center",
      part = "all"
    )

  if (length(left_columns) > 0L) {
    valid_left <- left_columns[left_columns <= ncol(data)]
    if (length(valid_left) > 0L) {
      ft <- flextable::align(
        ft,
        j = valid_left,
        align = "left",
        part = "all"
      )
    }
  }

  ft <- flextable::valign(ft, valign = "center", part = "all") |>
    flextable::autofit() |>
    flextable::set_table_properties(
      layout = "autofit",
      width = 1
    )

  if (!is.null(footnote) && nzchar(footnote)) {
    ft <- flextable::add_footer_lines(ft, values = footnote) |>
      flextable::fontsize(
        size = max(7, font_size - 1),
        part = "footer"
      ) |>
      flextable::align(
        align = "left",
        part = "footer"
      )
  }

  ft
}

key_completeness_variables <- c(
  "qe_reported_mg_g_mid",
  "qmax_reported_mg_g_mid",
  "removal_reported_percent_mid",
  "bet_m2_g_mid",
  "activation_temp_c_mid",
  "c0_mg_l_mid",
  "adsorbent_dose_g_l_mid",
  "contact_time_min_mid",
  "regeneration_cycles",
  "kinetic_model_std",
  "isotherm_model_std",
  "replicates_n",
  "blanks_reported",
  "calibration_reported",
  "ph_controlled",
  "uncertainty_type",
  "uncertainty_value"
)

pretty_variable_names <- c(
  qe_reported_mg_g_mid = "qe",
  qmax_reported_mg_g_mid = "qmax",
  removal_reported_percent_mid = "Removal (%)",
  bet_m2_g_mid = "BET",
  activation_temp_c_mid = "Activation temperature",
  c0_mg_l_mid = "Initial concentration",
  adsorbent_dose_g_l_mid = "Adsorbent dose",
  contact_time_min_mid = "Contact time",
  regeneration_cycles = "Numeric cycle entry",
  kinetic_model_std = "Kinetic model",
  isotherm_model_std = "Isotherm model",
  replicates_n = "Replicate count",
  blanks_reported = "Blanks reporting",
  calibration_reported = "Calibration reporting",
  ph_controlled = "pH information recorded",
  uncertainty_type = "Uncertainty type",
  uncertainty_value = "Uncertainty value"
)

top_kinetic_models <- kinetic_model_frequencies_unit_level |>
  group_by(kinetic_model_std) |>
  summarise(total_units = sum(study_adsorbent_metal_units), .groups = "drop") |>
  slice_max(total_units, n = 8, with_ties = FALSE) |>
  pull(kinetic_model_std)

top_isotherm_models <- isotherm_model_frequencies_unit_level |>
  group_by(isotherm_model_std) |>
  summarise(total_units = sum(study_adsorbent_metal_units), .groups = "drop") |>
  slice_max(total_units, n = 8, with_ties = FALSE) |>
  pull(isotherm_model_std)


# 19. FINAL FIGURE AND TABLE EXPORT WORKFLOW ----------------------------------
# Main Figures 1-5; combined model Figure S1 and sensitivity Figures S2-S3.
# Optional pH caution figure is controlled by CONFIG. Tables S1-S10 are curated
# below; incomplete appraisal/audit documents are routed to author_work.
# PRISMA screening counts below are author-supplied, not independently verified.
# Arithmetic checks establish consistency only, not screening provenance.

submission_directory <- file.path(publication_directory, "submission_ready")
submission_main_figures_directory <- file.path(submission_directory, "main_figures")
submission_main_tables_directory <- file.path(submission_directory, "main_tables")
submission_supp_figures_directory <- file.path(submission_directory, "supplementary_figures")
submission_supp_tables_directory <- file.path(submission_directory, "supplementary_tables")
submission_supp_data_directory <- file.path(submission_directory, "supplementary_data")
submission_notes_directory <- file.path(submission_directory, "notes")

purrr::walk(
  c(
    submission_directory,
    submission_main_figures_directory,
    submission_main_tables_directory,
    submission_supp_figures_directory,
    submission_supp_tables_directory,
    submission_supp_data_directory,
    submission_notes_directory
  ),
  ~ dir.create(.x, showWarnings = FALSE, recursive = TRUE)
)

save_submission_figure <- function(
    plot,
    filename_stub,
    directory,
    width = 9,
    height = 6
) {
  png_file <- file.path(directory, paste0(filename_stub, ".png"))

  tryCatch(
    {
      ggplot2::ggsave(
        filename = png_file,
        plot = plot,
        width = width,
        height = height,
        units = "in",
        dpi = CONFIG$DPI,
        bg = "white"
      )

      if (isTRUE(CONFIG$EXPORT_PDF)) {
        ggplot2::ggsave(
          filename = file.path(directory, paste0(filename_stub, ".pdf")),
          plot = plot,
          width = width,
          height = height,
          units = "in",
          device = grDevices::cairo_pdf,
          bg = "white"
        )
      }

      if (isTRUE(CONFIG$EXPORT_TIFF)) {
        ggplot2::ggsave(
          filename = file.path(directory, paste0(filename_stub, ".tiff")),
          plot = plot,
          width = width,
          height = height,
          units = "in",
          dpi = CONFIG$TIFF_DPI,
          device = "tiff",
          compression = "lzw",
          bg = "white"
        )
      }

      TRUE
    },
    error = function(e) {
      stop(
        "Could not save required submission figure ",
        filename_stub,
        ": ",
        conditionMessage(e)
      )
      FALSE
    }
  )
}

save_submission_table <- function(
    data,
    filename_stub,
    directory,
    title = NULL,
    subtitle = NULL,
    left_columns = 1L,
    footnote = NULL
) {
  data <- as.data.frame(data)

  tryCatch(
    readr::write_csv(
      data,
      file.path(directory, paste0(filename_stub, ".csv")),
      na = ""
    ),
    error = function(e) {
      stop("Could not save required submission CSV ", filename_stub, ": ", conditionMessage(e), call. = FALSE)
    }
  )

  caption <- paste(
    c(title, subtitle),
    collapse = ifelse(is.null(subtitle), "", " ")
  )

  if (requireNamespace("flextable", quietly = TRUE)) {
    tryCatch(
      {
        ft <- make_publication_flextable(
          data = data,
          caption = ifelse(nzchar(caption), caption, filename_stub),
          left_columns = left_columns,
          font_size = CONFIG$TABLE_FONT_SIZE,
          footnote = footnote
        )

        if (!is.null(ft)) {
          flextable::save_as_docx(
            ft,
            path = file.path(directory, paste0(filename_stub, ".docx"))
          )
        }
      },
      error = function(e) {
        unlink(file.path(directory, paste0(filename_stub, ".docx")))
        warning("Could not save submission DOCX; CSV retained for ", filename_stub, ": ", conditionMessage(e))
      }
    )
  }

  if (requireNamespace("gt", quietly = TRUE)) {
    tryCatch(
      {
        gt_table <- gt::gt(data)

        if (!is.null(title) || !is.null(subtitle)) {
          gt_table <- gt::tab_header(
            gt_table,
            title = if (!is.null(title)) title else "",
            subtitle = if (!is.null(subtitle)) subtitle else ""
          )
        }

        gt::gtsave(
          gt_table,
          filename = file.path(directory, paste0(filename_stub, ".html"))
        )
      },
      error = function(e) {
        warning("Could not save submission HTML ", filename_stub, ": ", conditionMessage(e))
      }
    )
  }

  invisible(TRUE)
}

# Restrict the submission-facing comparative synthesis to the stated review
# scope: Pb and Cd. Other standardized metals remain in audit/evidence outputs
# but do not enter the Pb/Cd manuscript performance figures and tables.
submission_analysis_unit <- analysis_unit |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS) |>
  droplevels()

submission_analysis_unit_sensitivity <- analysis_unit_sensitivity |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS) |>
  droplevels()

# Current dataset-derived counts are calculated rather than hard-coded. These are
# intentionally separate from the author-supplied literature-search PRISMA counts.
updated_dataset_counts <- list(
  studies_with_endpoints = n_distinct(dat_all_extracted$study_id),
  all_extraction_records = nrow(dat_all_extracted),
  analysis_scope_studies = n_distinct(dat$study_id),
  analysis_scope_study_adsorbents = nrow(distinct(dat, study_id, adsorbent_id)),
  analysis_scope_records = nrow(dat),
  dependence_reduced_units = nrow(analysis_unit)
)

updated_dataset_counts_table <- tibble(
  Stage = c(
    "Studies with extracted endpoints in updated CSV",
    "All extraction records in updated CSV",
    "Studies in primary Pb/Cd + three-precursor synthesis",
    "Study-specific adsorbents in primary synthesis",
    "Records in primary synthesis",
    "Dependence-reduced analytical units"
  ),
  Count = unlist(updated_dataset_counts, use.names = FALSE)
)

save_csv(updated_dataset_counts_table, "updated_dataset_counts_audit.csv")


# Publication-year audit -------------------------------------------------------
# Study IDs encode years in the current extraction system. These derived years
# support a Results description only; they do not replace the search-eligibility
# period stated in Methods and should be verified against article metadata.

primary_synthesis_publication_years <- dat |>
  distinct(study_id) |>
  transmute(
    study_id = as.character(study_id),
    publication_year_from_study_id = extract_study_year(study_id)
  ) |>
  arrange(publication_year_from_study_id, study_id)

primary_synthesis_year_range <- primary_synthesis_publication_years |>
  summarise(
    studies = n(),
    studies_with_parsed_year = sum(!is.na(publication_year_from_study_id)),
    earliest_year = ifelse(
      all(is.na(publication_year_from_study_id)),
      NA_integer_,
      min(publication_year_from_study_id, na.rm = TRUE)
    ),
    latest_year = ifelse(
      all(is.na(publication_year_from_study_id)),
      NA_integer_,
      max(publication_year_from_study_id, na.rm = TRUE)
    ),
    note = paste(
      "Year is parsed from study_id and must be verified against article metadata;",
      "do not use this range to redefine the search eligibility period."
    )
  )

save_csv(
  primary_synthesis_publication_years,
  "primary_synthesis_publication_years_audit.csv"
)
save_csv(
  primary_synthesis_year_range,
  "primary_synthesis_publication_year_range.csv"
)


# 19.1 Figure 1: PRISMA flow diagram ------------------------------------------
#
# The PRISMA figure distinguishes three downstream study counts:
#   - 51 studies included in the systematic-review screening log;
#   - studies represented by endpoint records in the current extraction dataset;
#   - studies meeting the primary Pb/Cd + three-feedstock synthesis scope.
# The latter two counts are calculated directly from the current dataset.
# No reason is inferred for review-included studies absent from the updated
# extraction dataset; that transition is shown only as an accounting stage.
#
# PRISMA flow diagram generated from author-supplied screening counts.
# Their provenance must be checked against original screening records. These values reproduce the flowchart
# used for the manuscript and are deliberately stored in one editable object so
# that any later correction to the screening log can be made in one place.
#
# Internal arithmetic checks:
#   2,740 + 547 + 183 = 3,470 records identified
#   3,470 - 583 = 2,887 records screened
#   2,887 - 2,287 = 600 full-text articles sought
#   600 - 18 = 582 full-text articles assessed
#   582 - 450 = 132 studies meeting broad eligibility
#   132 - 81 = 51 studies in the final systematic-review dataset

prisma_counts <- list(
  wos = 2740L,
  scopus = 547L,
  google_scholar = 183L,
  total_identified = 3470L,
  duplicates_removed = 583L,
  records_screened = 2887L,
  title_abstract_excluded = 2287L,
  full_text_sought = 600L,
  full_text_not_retrieved = 18L,
  full_text_assessed = 582L,
  full_text_excluded = 450L,
  broad_eligibility = 132L,
  final_refinement_excluded = 81L,
  final_studies = CONFIG$SYSTEMATIC_REVIEW_INCLUDED_STUDIES,
  studies_with_endpoints = updated_dataset_counts$studies_with_endpoints,
  all_extraction_records = updated_dataset_counts$all_extraction_records,
  analysis_scope_studies = updated_dataset_counts$analysis_scope_studies,
  analysis_scope_study_adsorbents =
    updated_dataset_counts$analysis_scope_study_adsorbents,
  analysis_scope_records = updated_dataset_counts$analysis_scope_records,
  dependence_reduced_units = updated_dataset_counts$dependence_reduced_units,
  studies_not_in_updated_extraction =
    CONFIG$SYSTEMATIC_REVIEW_INCLUDED_STUDIES -
    updated_dataset_counts$studies_with_endpoints,
  studies_outside_primary_synthesis =
    updated_dataset_counts$studies_with_endpoints -
    updated_dataset_counts$analysis_scope_studies
)

# Fail early if a future edit makes the PRISMA counts internally inconsistent.
stopifnot(
  prisma_counts$wos +
    prisma_counts$scopus +
    prisma_counts$google_scholar ==
    prisma_counts$total_identified,
  prisma_counts$total_identified -
    prisma_counts$duplicates_removed ==
    prisma_counts$records_screened,
  prisma_counts$records_screened -
    prisma_counts$title_abstract_excluded ==
    prisma_counts$full_text_sought,
  prisma_counts$full_text_sought -
    prisma_counts$full_text_not_retrieved ==
    prisma_counts$full_text_assessed,
  prisma_counts$full_text_assessed -
    prisma_counts$full_text_excluded ==
    prisma_counts$broad_eligibility,
  prisma_counts$broad_eligibility -
    prisma_counts$final_refinement_excluded ==
    prisma_counts$final_studies,
  prisma_counts$studies_not_in_updated_extraction >= 0,
  prisma_counts$studies_outside_primary_synthesis >= 0,
  prisma_counts$final_studies -
    prisma_counts$studies_not_in_updated_extraction ==
    prisma_counts$studies_with_endpoints,
  prisma_counts$studies_with_endpoints -
    prisma_counts$studies_outside_primary_synthesis ==
    prisma_counts$analysis_scope_studies
)

format_prisma_n <- function(x) {
  format(as.integer(x), big.mark = ",", scientific = FALSE, trim = TRUE)
}


wrap_prisma <- function(x, width = 42) {
  paste(strwrap(x, width = width), collapse = "\n")
}

prisma_box_df <- function(
    xc, yc, w, h, label, fill_group,
    text_size = 3.15, fontface = "plain"
) {
  tibble::tibble(
    xmin = xc - w / 2,
    xmax = xc + w / 2,
    ymin = yc - h / 2,
    ymax = yc + h / 2,
    xc = xc,
    yc = yc,
    label = label,
    fill_group = fill_group,
    text_size = text_size,
    fontface = fontface
  )
}

build_prisma_flowchart <- function() {
  # ---------------------------------------------------------------------------
  # Geometry
  # ---------------------------------------------------------------------------
  x_mid <- 4.30
  x_right <- 9.25

  w_main <- 4.85
  w_side <- 4.25

  h_std <- 1.25
  h_identified <- 2.05
  h_refinement <- 1.75
  h_primary <- 1.85

  y_identified <- 19.10
  y_duplicates <- 16.85
  y_screened <- 14.65
  y_sought <- 12.45
  y_assessed <- 10.25
  y_broad <- 8.05
  y_review_included <- 5.85
  y_extraction <- 3.70
  y_primary <- 1.35

  # ---------------------------------------------------------------------------
  # Labels
  # ---------------------------------------------------------------------------
  label_identified <- paste0(
    "Records identified (n = ", format_prisma_n(prisma_counts$total_identified), ")\n\n",
    "Web of Science Core Collection (n = ", format_prisma_n(prisma_counts$wos), ")\n",
    "Scopus (n = ", format_prisma_n(prisma_counts$scopus), ")\n",
    "Google Scholar (n = ", format_prisma_n(prisma_counts$google_scholar), ")"
  )

  label_duplicates <- paste0(
    "Duplicate records removed before screening\n",
    "(n = ", format_prisma_n(prisma_counts$duplicates_removed), ")"
  )

  label_screened <- paste0(
    "Records screened by title and abstract\n",
    "(n = ", format_prisma_n(prisma_counts$records_screened), ")"
  )

  label_title_excluded <- paste0(
    "Records excluded after title/abstract screening\n",
    "(n = ", format_prisma_n(prisma_counts$title_abstract_excluded), ")"
  )

  label_sought <- paste0(
    "Full-text articles sought for retrieval\n",
    "(n = ", format_prisma_n(prisma_counts$full_text_sought), ")"
  )

  label_not_retrieved <- paste0(
    "Full-text articles not retrieved\n",
    "(n = ", format_prisma_n(prisma_counts$full_text_not_retrieved), ")"
  )

  label_assessed <- paste0(
    "Full-text articles assessed for eligibility\n",
    "(n = ", format_prisma_n(prisma_counts$full_text_assessed), ")"
  )

  label_fulltext_excluded <- paste0(
    "Full-text articles excluded\n",
    "(n = ", format_prisma_n(prisma_counts$full_text_excluded), ")"
  )

  label_broad <- paste0(
    "Studies meeting broad eligibility criteria\n",
    "(n = ", format_prisma_n(prisma_counts$broad_eligibility), ")"
  )

  label_refinement_excluded <- paste0(
    "Studies excluded during final review-scope refinement\n",
    "(n = ", format_prisma_n(prisma_counts$final_refinement_excluded), ")\n\n",
    "Reasons included:\n",
    "\u2022 precursor outside the final three review groups\n",
    "\u2022 insufficient standardized extractable data"
  )

  label_review_included <- paste0(
    "Studies included in the systematic review\n",
    "(n = ", format_prisma_n(prisma_counts$final_studies), ")"
  )

  label_not_extracted <- paste0(
    "Review-included studies not represented by an endpoint\n",
    "record in the updated extraction dataset\n",
    "(n = ", format_prisma_n(prisma_counts$studies_not_in_updated_extraction), ")"
  )

  label_extraction <- paste0(
    "Studies represented in the updated extraction dataset\n",
    "(n = ", format_prisma_n(prisma_counts$studies_with_endpoints), ")\n",
    "Extraction records (n = ", format_prisma_n(prisma_counts$all_extraction_records), ")"
  )

  label_outside_primary <- paste0(
    "Extracted studies outside the primary Pb/Cd +\n",
    "three-precursor synthesis scope\n",
    "(n = ", format_prisma_n(prisma_counts$studies_outside_primary_synthesis), ")"
  )

  label_primary <- paste0(
    "Studies included in the primary descriptive synthesis\n",
    "(n = ", format_prisma_n(prisma_counts$analysis_scope_studies), ")\n\n",
    "Study-specific adsorbents (n = ",
    format_prisma_n(prisma_counts$analysis_scope_study_adsorbents), ")\n",
    "Records (n = ", format_prisma_n(prisma_counts$analysis_scope_records), ")\n",
    "Dependence-reduced analytical units (n = ",
    format_prisma_n(prisma_counts$dependence_reduced_units), ")"
  )

  # ---------------------------------------------------------------------------
  # Nodes
  # ---------------------------------------------------------------------------
  boxes <- dplyr::bind_rows(
    prisma_box_df(
      x_mid, y_identified, w_main, h_identified,
      label_identified, "Identification", text_size = 3.20
    ),
    prisma_box_df(
      x_mid, y_duplicates, w_main, h_std,
      label_duplicates, "Duplicate removal", text_size = 3.15
    ),
    prisma_box_df(
      x_mid, y_screened, w_main, h_std,
      label_screened, "Screening", text_size = 3.15
    ),
    prisma_box_df(
      x_right, y_screened, w_side, h_std,
      label_title_excluded, "Exclusion", text_size = 3.00
    ),
    prisma_box_df(
      x_mid, y_sought, w_main, h_std,
      label_sought, "Screening", text_size = 3.15
    ),
    prisma_box_df(
      x_right, y_sought, w_side, h_std,
      label_not_retrieved, "Exclusion", text_size = 3.00
    ),
    prisma_box_df(
      x_mid, y_assessed, w_main, h_std,
      label_assessed, "Eligibility", text_size = 3.15
    ),
    prisma_box_df(
      x_right, y_assessed, w_side, h_std,
      label_fulltext_excluded, "Exclusion", text_size = 3.00
    ),
    prisma_box_df(
      x_mid, y_broad, w_main, h_std,
      label_broad, "Eligibility", text_size = 3.10
    ),
    prisma_box_df(
      x_right, y_broad, w_side, h_refinement,
      label_refinement_excluded, "Exclusion", text_size = 2.65
    ),
    prisma_box_df(
      x_mid, y_review_included, w_main, h_std,
      label_review_included, "Included", text_size = 3.20
    ),
    prisma_box_df(
      x_right, y_review_included, w_side, h_std + 0.25,
      label_not_extracted, "Exclusion", text_size = 2.75
    ),
    prisma_box_df(
      x_mid, y_extraction, w_main, h_std + 0.15,
      label_extraction, "Data", text_size = 3.00
    ),
    prisma_box_df(
      x_right, y_extraction, w_side, h_std + 0.15,
      label_outside_primary, "Exclusion", text_size = 2.75
    ),
    prisma_box_df(
      x_mid, y_primary, w_main, h_primary,
      label_primary, "Included", text_size = 2.85
    )
  )

  # ---------------------------------------------------------------------------
  # Stage headings
  # ---------------------------------------------------------------------------
  stage_labels <- tibble::tibble(
    xc = 0.55,
    yc = c(20.65, 15.90, 11.05, 6.95),
    label = c("Identification", "Screening", "Eligibility", "Included")
  )

  # ---------------------------------------------------------------------------
  # Connectors
  # ---------------------------------------------------------------------------
  edge_top <- function(y, h) y + h / 2
  edge_bottom <- function(y, h) y - h / 2
  edge_left <- function(x, w) x - w / 2
  edge_right <- function(x, w) x + w / 2

  down <- tibble::tibble(
    x = rep(x_mid, 8),
    y = c(
      edge_bottom(y_identified, h_identified),
      edge_bottom(y_duplicates, h_std),
      edge_bottom(y_screened, h_std),
      edge_bottom(y_sought, h_std),
      edge_bottom(y_assessed, h_std),
      edge_bottom(y_broad, h_std),
      edge_bottom(y_review_included, h_std),
      edge_bottom(y_extraction, h_std + 0.15)
    ),
    xend = rep(x_mid, 8),
    yend = c(
      edge_top(y_duplicates, h_std),
      edge_top(y_screened, h_std),
      edge_top(y_sought, h_std),
      edge_top(y_assessed, h_std),
      edge_top(y_broad, h_std),
      edge_top(y_review_included, h_std),
      edge_top(y_extraction, h_std + 0.15),
      edge_top(y_primary, h_primary)
    )
  )

  side <- tibble::tibble(
    x = rep(edge_right(x_mid, w_main) + 0.06, 5),
    y = c(
      y_screened,
      y_sought,
      y_assessed,
      y_broad,
      y_review_included
    ),
    xend = rep(edge_left(x_right, w_side) - 0.06, 5),
    yend = c(
      y_screened,
      y_sought,
      y_assessed,
      y_broad,
      y_review_included
    )
  )

  side_primary <- tibble::tibble(
    x = edge_right(x_mid, w_main) + 0.06,
    y = y_extraction,
    xend = edge_left(x_right, w_side) - 0.06,
    yend = y_extraction
  )

  # ---------------------------------------------------------------------------
  # Palette
  # ---------------------------------------------------------------------------
  prisma_palette <- c(
    "Identification" = "#DCE8F5",
    "Duplicate removal" = "#EFD4C3",
    "Screening" = "#E9E3F3",
    "Eligibility" = "#E9E3F3",
    "Exclusion" = "#F4E4DA",
    "Included" = "#DDEEE4",
    "Data" = "#E8F0F7"
  )

  stroke <- "#4F4F4F"
  arrow_colour <- "#404040"

  # ---------------------------------------------------------------------------
  # Plot
  # ---------------------------------------------------------------------------
  p <- ggplot2::ggplot() +
    ggplot2::theme_void(base_family = CONFIG$FIGURE_FONT_FAMILY) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      plot.margin = ggplot2::margin(28, 42, 28, 42, "pt"),
      legend.position = "none"
    ) +
    ggplot2::geom_rect(
      data = boxes,
      ggplot2::aes(
        xmin = xmin, xmax = xmax,
        ymin = ymin, ymax = ymax,
        fill = fill_group
      ),
      colour = stroke,
      linewidth = 0.75,
      linejoin = "round"
    ) +
    ggplot2::geom_text(
      data = boxes,
      ggplot2::aes(
        x = xc,
        y = yc,
        label = label,
        size = text_size,
        fontface = fontface
      ),
      family = CONFIG$FIGURE_FONT_FAMILY,
      lineheight = 0.95,
      colour = "#1A1A1A",
      show.legend = FALSE
    ) +
    ggplot2::scale_size_identity() +
    ggplot2::geom_segment(
      data = down,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      arrow = grid::arrow(
        length = grid::unit(0.24, "cm"),
        type = "closed",
        angle = 22
      ),
      linewidth = 0.82,
      colour = arrow_colour,
      lineend = "round"
    ) +
    ggplot2::geom_segment(
      data = side,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      arrow = grid::arrow(
        length = grid::unit(0.24, "cm"),
        type = "closed",
        angle = 22
      ),
      linewidth = 0.82,
      colour = arrow_colour,
      lineend = "round"
    ) +
    ggplot2::geom_segment(
      data = side_primary,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      arrow = grid::arrow(
        length = grid::unit(0.24, "cm"),
        type = "closed",
        angle = 22
      ),
      linewidth = 0.82,
      colour = arrow_colour,
      lineend = "round"
    ) +
    ggplot2::geom_text(
      data = stage_labels,
      ggplot2::aes(x = xc, y = yc, label = label),
      family = CONFIG$FIGURE_FONT_FAMILY,
      fontface = "bold",
      hjust = 0,
      size = 4.10,
      colour = "#1A1A1A"
    ) +
    ggplot2::annotate(
      "text",
      x = 5.98,
      y = 21.55,
      label = "PRISMA 2020 Flow Diagram",
      family = CONFIG$FIGURE_FONT_FAMILY,
      fontface = "bold",
      size = 5.0,
      colour = "#1A1A1A"
    ) +
    ggplot2::coord_cartesian(
      xlim = c(0.3, 11.65),
      ylim = c(0.10, 21.95),
      expand = FALSE,
      clip = "off"
    ) +
    ggplot2::scale_fill_manual(values = prisma_palette)

  p
}

save_prisma_flowchart <- function(
    directory = submission_main_figures_directory,
    filename_stub = "Figure_1_PRISMA",
    width = 9.5,
    height = 16.5
) {
  p <- build_prisma_flowchart()

  png_file <- file.path(directory, paste0(filename_stub, ".png"))

  tryCatch(
    {
      ggplot2::ggsave(
        filename = png_file,
        plot = p,
        width = width,
        height = height,
        units = "in",
        dpi = CONFIG$TIFF_DPI,
        bg = "white"
      )

      if (isTRUE(CONFIG$EXPORT_PDF)) {
        ggplot2::ggsave(
          filename = file.path(directory, paste0(filename_stub, ".pdf")),
          plot = p,
          width = width,
          height = height,
          units = "in",
          device = grDevices::cairo_pdf,
          bg = "white"
        )
      }

      if (isTRUE(CONFIG$EXPORT_TIFF)) {
        ggplot2::ggsave(
          filename = file.path(directory, paste0(filename_stub, ".tiff")),
          plot = p,
          width = width,
          height = height,
          units = "in",
          dpi = CONFIG$TIFF_DPI,
          device = "tiff",
          compression = "lzw",
          bg = "white"
        )
      }

      TRUE
    },
    error = function(e) {
      stop(
        "Could not save required PRISMA flow diagram: ",
        conditionMessage(e)
      )
      FALSE
    }
  )
}

prisma_export_ok <- save_prisma_flowchart()

# Export the screening counts as a machine-readable audit table.
prisma_screening_counts <- tibble::tribble(
  ~Stage, ~Count,
  "Web of Science Core Collection", prisma_counts$wos,
  "Scopus", prisma_counts$scopus,
  "Google Scholar", prisma_counts$google_scholar,
  "Records identified", prisma_counts$total_identified,
  "Duplicate records removed before screening", prisma_counts$duplicates_removed,
  "Records screened by title and abstract", prisma_counts$records_screened,
  "Records excluded after title/abstract screening", prisma_counts$title_abstract_excluded,
  "Full-text articles sought for retrieval", prisma_counts$full_text_sought,
  "Full-text articles not retrieved", prisma_counts$full_text_not_retrieved,
  "Full-text articles assessed for eligibility", prisma_counts$full_text_assessed,
  "Full-text articles excluded", prisma_counts$full_text_excluded,
  "Studies meeting broad eligibility criteria", prisma_counts$broad_eligibility,
  "Studies excluded during final analysis-ready refinement", prisma_counts$final_refinement_excluded,
  "Studies included in systematic review", prisma_counts$final_studies,
  "Review-included studies not represented in updated extraction dataset",
    prisma_counts$studies_not_in_updated_extraction,
  "Studies with extracted endpoints in updated CSV", prisma_counts$studies_with_endpoints,
  "All extraction records in updated CSV", prisma_counts$all_extraction_records,
  "Extracted studies outside primary Pb/Cd + three-precursor synthesis",
    prisma_counts$studies_outside_primary_synthesis,
  "Studies in primary Pb/Cd + three-precursor synthesis", prisma_counts$analysis_scope_studies,
  "Study-specific adsorbents in primary synthesis", prisma_counts$analysis_scope_study_adsorbents,
  "Records in primary synthesis", prisma_counts$analysis_scope_records,
  "Dependence-reduced analytical units", prisma_counts$dependence_reduced_units
)

readr::write_csv(
  prisma_screening_counts,
  file.path(
    submission_notes_directory,
    "PRISMA_screening_counts_audit.csv"
  )
)

# 19.2 Figure 2: Reporting completeness ---------------------------------------
# Recalculate completeness for the Pb/Cd submission-facing analytical corpus.

submission_completeness <- submission_analysis_unit |>
  select(-source_rows, -source_input_rows) |>
  summarise(across(
    everything(),
    list(
      reported_n = ~ sum(!is.na(.x)),
      reported_percent = ~ 100 * mean(!is.na(.x))
    ),
    .names = "{.col}_{.fn}"
  )) |>
  pivot_longer(everything(), names_to = "metric", values_to = "value") |>
  separate(
    metric,
    into = c("variable", "metric"),
    sep = "_(?=reported_n|reported_percent)",
    extra = "merge"
  ) |>
  pivot_wider(names_from = metric, values_from = value) |>
  mutate(
    total_units = nrow(submission_analysis_unit),
    missing_n = total_units - reported_n,
    missing_percent = 100 - reported_percent
  )

submission_key_completeness <- submission_completeness |>
  filter(variable %in% key_completeness_variables) |>
  mutate(
    variable_label = recode(variable, !!!pretty_variable_names),
    variable_label = factor(
      variable_label,
      levels = rev(pretty_variable_names[key_completeness_variables])
    )
  )

submission_figure_2 <- submission_key_completeness |>
  ggplot(aes(x = variable_label, y = reported_percent)) +
  geom_col(width = 0.75) +
  geom_text(
    data = submission_key_completeness |> filter(reported_n == 0),
    aes(label = "0.0%"),
    y = 1.5,
    hjust = 0,
    size = 3.5
  ) +
  coord_flip() +
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    labels = scales::label_percent(scale = 1)
  ) +
  labs(
    x = NULL,
    y = "Reported Pb/Cd analytical units",
    title = "Figure 2. Completeness of key variables",
    subtitle = "Completeness is calculated using dependence-reduced study–adsorbent–metal units."
  ) +
  publication_theme()

save_submission_figure(
  submission_figure_2,
  "Figure_2_data_completeness",
  submission_main_figures_directory,
  width = 9,
  height = 6.5
)

# 19.3 Figure 3: Dependence-reduced adsorption performance by metal ------------

submission_fig3a <- submission_analysis_unit |>
  filter(!is.na(qe_reported_mg_g_mid), qe_reported_mg_g_mid > 0) |>
  ggplot(aes(x = metal, y = qe_reported_mg_g_mid)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.55, size = 1.7) +
  scale_y_log10(labels = label_number()) +
  labs(
    x = NULL,
    y = expression(q[e]~"(mg g"^{-1}*")"),
    title = "A. q[e]"
  ) +
  publication_theme()

submission_fig3b <- submission_analysis_unit |>
  filter(!is.na(qmax_reported_mg_g_mid), qmax_reported_mg_g_mid > 0) |>
  ggplot(aes(x = metal, y = qmax_reported_mg_g_mid)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.55, size = 1.7) +
  scale_y_log10(labels = label_number()) +
  labs(
    x = NULL,
    y = expression(q[max]~"(mg g"^{-1}*")"),
    title = "B. q[max]"
  ) +
  publication_theme()

submission_fig3c <- submission_analysis_unit |>
  filter(!is.na(removal_reported_percent_mid)) |>
  ggplot(aes(x = metal, y = removal_reported_percent_mid)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.55, size = 1.7) +
  coord_cartesian(ylim = c(0, 100)) +
  labs(
    x = NULL,
    y = "Removal (%)",
    title = "C. Removal"
  ) +
  publication_theme()

submission_figure_3 <- (submission_fig3a | submission_fig3b | submission_fig3c) +
  plot_annotation(
    title = "Figure 3. Dependence-reduced adsorption performance by target metal",
    subtitle = paste(
      "Each point is one study–adsorbent–metal unit.",
      "q[e] and q[max] use log10 scales; exploratory tests do not establish equivalence."
    )
  )

save_submission_figure(
  submission_figure_3,
  "Figure_3_adsorption_performance_by_metal",
  submission_main_figures_directory,
  width = 13,
  height = 5
)

# 19.4 Figure 4: Adsorption outcomes by precursor ------------------------------

submission_fig4a <- submission_analysis_unit |>
  filter(!is.na(qe_reported_mg_g_mid), qe_reported_mg_g_mid > 0) |>
  ggplot(aes(x = precursor_std, y = qe_reported_mg_g_mid)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.55, size = 1.6) +
  scale_y_log10(labels = label_number()) +
  coord_flip() +
  labs(
    x = NULL,
    y = expression(q[e]~"(mg g"^{-1}*")"),
    title = "A. q[e]"
  ) +
  publication_theme()

submission_fig4b <- submission_analysis_unit |>
  filter(!is.na(qmax_reported_mg_g_mid), qmax_reported_mg_g_mid > 0) |>
  ggplot(aes(x = precursor_std, y = qmax_reported_mg_g_mid)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.55, size = 1.6) +
  scale_y_log10(labels = label_number()) +
  coord_flip() +
  labs(
    x = NULL,
    y = expression(q[max]~"(mg g"^{-1}*")"),
    title = "B. q[max]"
  ) +
  publication_theme()

submission_fig4c <- submission_analysis_unit |>
  filter(!is.na(removal_reported_percent_mid)) |>
  ggplot(aes(x = precursor_std, y = removal_reported_percent_mid)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.55, size = 1.6) +
  coord_flip() +
  coord_cartesian(ylim = c(0, 100)) +
  labs(
    x = NULL,
    y = "Removal (%)",
    title = "C. Removal"
  ) +
  publication_theme()

submission_figure_4 <- submission_fig4a / submission_fig4b / submission_fig4c +
  plot_annotation(
    title = "Figure 4. Dependence-reduced adsorption outcomes by precursor group",
    subtitle = paste(
      "Pb/Cd analytical units only.",
      "Comparisons are exploratory because experimental conditions are heterogeneous."
    )
  )

save_submission_figure(
  submission_figure_4,
  "Figure_4_adsorption_performance_by_precursor",
  submission_main_figures_directory,
  width = 9,
  height = 11
)

# 19.5 Figure 5: Experimental-condition heterogeneity --------------------------
# This figure is promoted to the main manuscript because Reviewer 4 specifically
# questioned comparability of precursor groups across different operating
# conditions.

submission_condition_long <- submission_analysis_unit |>
  select(
    precursor_std,
    activation_temp_c_mid,
    c0_mg_l_mid,
    adsorbent_dose_g_l_mid,
    contact_time_min_mid,
    bet_m2_g_mid
  ) |>
  pivot_longer(
    cols = -precursor_std,
    names_to = "condition",
    values_to = "value"
  ) |>
  filter(!is.na(value), value > 0) |>
  mutate(condition = recode(condition, !!!condition_labels))

submission_condition_nonph <- submission_condition_long |>
  ggplot(aes(x = precursor_std, y = value)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.45, size = 1.25) +
  scale_y_log10(labels = label_number()) +
  coord_flip() +
  facet_wrap(~ condition, scales = "free_y", ncol = 2) +
  labs(
    x = NULL,
    y = "Reported value (log10 scale)",
    title = "A. Experimental conditions other than pH"
  ) +
  publication_theme(base_size = 10)

submission_condition_ph <- submission_analysis_unit |>
  filter(!is.na(ph_mid)) |>
  ggplot(aes(x = precursor_std, y = ph_mid)) +
  geom_boxplot(outlier.shape = NA, width = 0.55) +
  geom_point(position = position_jitter(width = 0.10, height = 0, seed = RANDOM_SEED), alpha = 0.55, size = 1.4) +
  coord_flip() +
  labs(
    x = NULL,
    y = "Reported pH midpoint",
    title = "B. Reported pH"
  ) +
  publication_theme(base_size = 10)

submission_figure_5 <- submission_condition_nonph / submission_condition_ph +
  plot_layout(heights = c(3, 1.25)) +
  plot_annotation(
    title = "Figure 5. Experimental-condition heterogeneity across precursor groups",
    subtitle = paste0(
      "Dependence-reduced Pb/Cd analytical units.\n",
      "Differences in study conditions limit causal interpretation of precursor-group comparisons; ",
      "groups with n < ", CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
      " remain descriptive."
    )
  )

save_submission_figure(
  submission_figure_5,
  "Figure_5_experimental_condition_heterogeneity",
  submission_main_figures_directory,
  width = 11,
  height = 11
)


# 19.6 Supplementary Figure S1: combined model reporting -----------------------
# Kinetic and isotherm reporting are combined into one two-panel figure.
# Obvious duplicate Sips/Langmuir-Freundlich labels are standardized during
# cleaning. The figure describes reporting frequency only; it is not evidence of
# model validity or adsorption mechanism.

submission_fig_s1a <- kinetic_model_frequencies_unit_level |>
  filter(
    as.character(metal) %in% CONFIG$TARGET_METALS,
    kinetic_model_std %in% top_kinetic_models
  ) |>
  ggplot(aes(
    x = safe_reorder(kinetic_model_std, study_adsorbent_metal_units, sum),
    y = study_adsorbent_metal_units,
    fill = metal
  )) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  coord_flip() +
  labs(
    x = NULL,
    y = "Pb/Cd analytical units",
    fill = "Metal",
    title = "A. Kinetic models"
  ) +
  publication_theme(base_size = 10)

submission_fig_s1b <- isotherm_model_frequencies_unit_level |>
  filter(
    as.character(metal) %in% CONFIG$TARGET_METALS,
    isotherm_model_std %in% top_isotherm_models
  ) |>
  ggplot(aes(
    x = safe_reorder(isotherm_model_std, study_adsorbent_metal_units, sum),
    y = study_adsorbent_metal_units,
    fill = metal
  )) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  coord_flip() +
  labs(
    x = NULL,
    y = "Pb/Cd analytical units",
    fill = "Metal",
    title = "B. Isotherm models"
  ) +
  publication_theme(base_size = 10)

submission_figure_s1 <- submission_fig_s1a / submission_fig_s1b +
  plot_annotation(
    title = "Figure S1. Reported kinetic and isotherm models",
    subtitle = paste(
      "Counts describe model reporting across dependence-reduced analytical units.",
      "Model frequency is not evidence of fit quality or mechanism."
    )
  )

save_submission_figure(
  submission_figure_s1,
  "Figure_S1_combined_model_reporting",
  submission_supp_figures_directory,
  width = 10,
  height = 10
)

# Preserve underlying model-frequency data separately rather than duplicating
# the combined figure as formatted supplementary tables.
submission_kinetic_frequency_data <- kinetic_model_frequencies_unit_level |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS)

submission_isotherm_frequency_data <- isotherm_model_frequencies_unit_level |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS)

readr::write_csv(
  submission_kinetic_frequency_data,
  file.path(
    submission_supp_data_directory,
    "underlying_kinetic_model_frequencies.csv"
  )
)

readr::write_csv(
  submission_isotherm_frequency_data,
  file.path(
    submission_supp_data_directory,
    "underlying_isotherm_model_frequencies.csv"
  )
)

# 19.7 Supplementary Figure S2: extreme-value sensitivity ----------------------
submission_extreme_sensitivity <- sensitivity_by_metal |>
  filter(
    as.character(metal) %in% CONFIG$TARGET_METALS,
    scenario %in% c("All valid units", "Exclude log-Tukey extremes")
  ) |>
  mutate(
    Outcome = recode(
      outcome,
      qe_reported_mg_g_mid = "q[e] (mg/g)",
      qmax_reported_mg_g_mid = "q[max] (mg/g)",
      removal_reported_percent_mid = "Removal (%)"
    )
  )

submission_figure_s2 <- submission_extreme_sensitivity |>
  ggplot(aes(
    x = scenario,
    y = median,
    ymin = q1,
    ymax = q3,
    shape = metal
  )) +
  geom_pointrange(
    position = position_dodge(width = 0.45),
    na.rm = TRUE
  ) +
  coord_flip() +
  facet_wrap(~ Outcome, scales = "free_x") +
  labs(
    x = NULL,
    y = "Median with interquartile range",
    shape = "Metal",
    title = "Figure S2. Extreme-value sensitivity of adsorption summaries",
    subtitle = paste(
      "Extreme observations are defined by outcome-specific log10 Tukey fences;",
      "exclusion is a sensitivity analysis, not a declaration that values are erroneous."
    )
  ) +
  publication_theme(base_size = 10)

save_submission_figure(
  submission_figure_s2,
  "Figure_S2_extreme_value_sensitivity",
  submission_supp_figures_directory,
  width = 11,
  height = 5.5
)

# 19.8 Supplementary Figure S3: water-matrix sensitivity -----------------------
# Sample sizes are printed next to each point because the realistic-water
# subsets are sparse and should not be interpreted without their n values.

submission_water_sensitivity <- sensitivity_by_metal |>
  filter(
    as.character(metal) %in% CONFIG$TARGET_METALS,
    scenario %in% c(
      "All valid units",
      "Synthetic/laboratory matrices only",
      "Real/environmental matrices only"
    )
  ) |>
  mutate(
    Outcome = recode(
      outcome,
      qe_reported_mg_g_mid = "q[e] (mg/g)",
      qmax_reported_mg_g_mid = "q[max] (mg/g)",
      removal_reported_percent_mid = "Removal (%)"
    ),
    n_label = paste0("n=", n_nonmissing)
  )

submission_figure_s3 <- submission_water_sensitivity |>
  ggplot(aes(
    x = scenario,
    y = median,
    ymin = q1,
    ymax = q3,
    shape = metal,
    group = metal
  )) +
  geom_pointrange(
    position = position_dodge(width = 0.45),
    na.rm = TRUE
  ) +
  geom_text(
    aes(label = n_label),
    position = position_dodge(width = 0.45),
    vjust = -0.8,
    size = 2.7,
    na.rm = TRUE
  ) +
  coord_flip(clip = "off") +
  facet_wrap(~ Outcome, scales = "free_x") +
  labs(
    x = NULL,
    y = "Median with interquartile range",
    shape = "Metal",
    title = "Figure S3. Water-matrix sensitivity of adsorption summaries",
    subtitle = paste(
      "Labels show outcome-specific subgroup sample sizes.",
      "Real/environmental subsets are descriptive when sparse."
    )
  ) +
  publication_theme(base_size = 10) +
  theme(plot.margin = margin(10, 28, 10, 10))

save_submission_figure(
  submission_figure_s3,
  "Figure_S3_water_matrix_sensitivity",
  submission_supp_figures_directory,
  width = 11,
  height = 6
)

# 19.9 Optional Supplementary Figure S4: pH / precipitation caution ------------
# The appraisal recommendation treats this figure as optional. By default the
# code retains the pH caution information in the source-verification audit only.
# Set CONFIG$EXPORT_OPTIONAL_PH_FIGURE = TRUE if the manuscript discusses this
# analysis substantively and the screening thresholds are explicitly justified.

if (isTRUE(CONFIG$EXPORT_OPTIONAL_PH_FIGURE)) {
  submission_ph_plot_data <- submission_analysis_unit_sensitivity |>
    filter(
      !is.na(ph_mid),
      !is.na(qe_reported_mg_g_mid),
      qe_reported_mg_g_mid > 0
    )

  submission_figure_s4 <- submission_ph_plot_data |>
    ggplot(aes(
      x = ph_mid,
      y = qe_reported_mg_g_mid,
      shape = precipitation_caution_flag
    )) +
    geom_point(alpha = 0.70, size = 2) +
    scale_y_log10(labels = label_number()) +
    facet_wrap(~ metal, scales = "free_x") +
    geom_vline(
      data = tibble(
        metal = factor(
          c("Pb", "Cd"),
          levels = levels(submission_ph_plot_data$metal)
        ),
        threshold = c(
          CONFIG$PB_PRECIPITATION_CAUTION_PH,
          CONFIG$CD_PRECIPITATION_CAUTION_PH
        )
      ),
      aes(xintercept = threshold),
      linetype = 2,
      inherit.aes = FALSE
    ) +
    labs(
      x = "Reported pH midpoint",
      y = expression(q[e]~"(mg g"^{-1}*")"),
      shape = "Caution flag",
      title = "Figure S4. Reported pH and q[e] with precipitation-caution thresholds",
      subtitle = paste(
        "Dashed lines are screening thresholds only;",
        "they do not demonstrate that precipitation occurred."
      )
    ) +
    publication_theme(base_size = 10)

  save_submission_figure(
    submission_figure_s4,
    "Figure_S4_optional_pH_precipitation_caution",
    submission_supp_figures_directory,
    width = 9,
    height = 5.5
  )
}


# 19.12 Main Table 1: evidence-base characteristics ---------------------------

submission_table1_metal <- submission_analysis_unit |>
  group_by(metal) |>
  summarise(
    Studies = n_distinct(study_id),
    Adsorbents = count_study_adsorbents(study_id, adsorbent_id),
    Analytical_units = n(),
    .groups = "drop"
  ) |>
  transmute(
    Domain = "Metal",
    Category = as.character(metal),
    Studies,
    Adsorbents,
    Analytical_units
  )

submission_table1_precursor <- submission_analysis_unit |>
  group_by(precursor_std) |>
  summarise(
    Studies = n_distinct(study_id),
    Adsorbents = count_study_adsorbents(study_id, adsorbent_id),
    Analytical_units = n(),
    .groups = "drop"
  ) |>
  transmute(
    Domain = "Precursor",
    Category = replace_na(as.character(precursor_std), "Not reported"),
    Studies,
    Adsorbents,
    Analytical_units
  )

submission_table1_matrix <- submission_analysis_unit |>
  mutate(
    matrix_display = replace_na(
      as.character(water_matrix_class),
      "Not reported/unclear"
    )
  ) |>
  group_by(matrix_display) |>
  summarise(
    Studies = n_distinct(study_id),
    Adsorbents = count_study_adsorbents(study_id, adsorbent_id),
    Analytical_units = n(),
    .groups = "drop"
  ) |>
  transmute(
    Domain = "Water matrix class",
    Category = matrix_display,
    Studies,
    Adsorbents,
    Analytical_units
  )

submission_main_table_1 <- bind_rows(
  submission_table1_metal,
  submission_table1_precursor,
  submission_table1_matrix
) |>
  arrange(Domain, desc(Studies), Category)

save_submission_table(
  submission_main_table_1,
  "Table_1_evidence_base_characteristics",
  submission_main_tables_directory,
  title = "Table 1. Characteristics of the Pb/Cd evidence base.",
  subtitle = "Counts use dependence-reduced study–adsorbent–metal analytical units.",
  left_columns = c(1, 2)
)

# 19.13 Main Table 2: dependence-reduced outcomes -----------------------------

submission_median_overall <- purrr::map_dfr(
  outcomes,
  ~ make_median_iqr(submission_analysis_unit, character(0), .x)
)

submission_median_by_metal <- purrr::map_dfr(
  outcomes,
  ~ make_median_iqr(submission_analysis_unit, "metal", .x)
)

submission_main_table_2 <- bind_rows(
  submission_median_overall |>
    mutate(Grouping = "Overall", Group = "Overall"),
  submission_median_by_metal |>
    mutate(Grouping = "Metal", Group = as.character(metal)) |>
    select(-metal)
) |>
  mutate(
    Outcome = recode(
      outcome,
      qe_reported_mg_g_mid = "qₑ (mg g⁻¹)",
      qmax_reported_mg_g_mid = "Model-derived maximum adsorption capacity, qmax (mg g⁻¹)",
      removal_reported_percent_mid = "Removal (%)"
    )
  ) |>
  transmute(
    Outcome,
    Grouping,
    Group,
    n = n_nonmissing,
    Median = format_number(median, 2),
    Q1 = format_number(q1, 2),
    Q3 = format_number(q3, 2),
    IQR = format_number(iqr, 2),
    Minimum = format_number(min, 2),
    Maximum = format_number(max, 2)
  )

save_submission_table(
  submission_main_table_2,
  "Table_2_dependence_reduced_adsorption_outcomes",
  submission_main_tables_directory,
  title = "Table 2. Dependence-reduced adsorption outcomes overall and by target metal.",
  subtitle = "Repeated observations are collapsed to one median per study–adsorbent–metal analytical unit.",
  left_columns = c(1, 2, 3)
)

# 19.14 Main Table 3: exploratory comparisons ---------------------------------

submission_pb_cd_tests <- purrr::map_dfr(
  outcomes,
  ~ tidy_wilcox_two_group(
    submission_analysis_unit,
    outcome = .x,
    group_var = "metal"
  )
)

submission_precursor_tests <- purrr::map_dfr(
  outcomes,
  ~ tidy_kruskal(
    submission_analysis_unit,
    outcome = .x,
    group_var = "precursor_std"
  )
)

submission_main_table_3 <- bind_rows(
  submission_pb_cd_tests |>
    mutate(Comparison = "Pb vs Cd"),
  submission_precursor_tests |>
    mutate(Comparison = "Precursor group")
) |>
  mutate(
    Outcome = recode(
      outcome,
      qe_reported_mg_g_mid = "qₑ (mg g⁻¹)",
      qmax_reported_mg_g_mid = "Model-derived maximum adsorption capacity, qmax (mg g⁻¹)",
      removal_reported_percent_mid = "Removal (%)"
    ),
    Interpretation = "Exploratory; within-study dependence is not modeled; non-significance does not establish equivalence."
  ) |>
  transmute(
    Comparison,
    Outcome,
    Test = test,
    n,
    Groups = groups,
    Statistic = format_number(statistic, 2),
    p_value = format_p_value(p_value),
    Interpretation
  )

save_submission_table(
  submission_main_table_3,
  "Table_3_exploratory_comparisons",
  submission_main_tables_directory,
  title = "Table 3. Exploratory comparisons by target metal and precursor group.",
  subtitle = paste0(
    "Sparse-group safeguards use the prespecified minimum n = ",
    CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
    "; non-significant results do not establish equivalence."
  ),
  left_columns = c(1, 2, 3, 8)
)


# 19.15 Main Table 4: six-domain critical-appraisal summary --------------------
# No summed quality score is used. Missing information remains "Pending source
# verification" until an article-level domain judgment, explanation, and
# page/table reference are entered in the manual appraisal file.

submission_main_table_4 <- critical_appraisal_domain_summary |>
  mutate(
    Domain = as.character(domain),
    Rating = summary_rating,
    Percent = paste0(format_number(percent_within_domain, 1), "%")
  ) |>
  transmute(
    Domain,
    Rating,
    Studies = studies,
    Percent
  ) |>
  arrange(
    factor(Domain, levels = critical_appraisal_domains),
    factor(
      Rating,
      levels = c(
        "Adequate",
        "Concerns",
        "Unclear",
        "Not applicable",
        "Pending source verification"
      )
    )
  )

save_submission_table(
  submission_main_table_4,
  "Table_4_critical_appraisal_summary",
  submission_main_tables_directory,
  title = "Table 4. Summary of adsorption-specific critical-appraisal domains.",
  subtitle = paste0(
    "Six domains are rated Adequate, Concerns, Unclear, or Not applicable after ",
    "article-level verification. Missing information is not treated as poor practice, ",
    "and no summed quality score is calculated. Current appraisal roster: ",
    n_distinct(critical_appraisal$study_id),
    " study IDs; PRISMA review inclusion count: ",
    prisma_counts$final_studies,
    "."
  ),
  left_columns = c(1, 2)
)

# 19.16 Supplementary Table S1: study characteristics and eligibility ----------
study_characteristics_from_extraction <- dat_all_extracted |>
  mutate(
    study_id_chr = as.character(study_id),
    year_from_id = extract_study_year(study_id_chr)
  ) |>
  group_by(study_id_chr) |>
  summarise(
    Publication_year_from_ID = first(stats::na.omit(year_from_id), default = NA_integer_),
    Extraction_records = n(),
    Base_feedstocks = collapse_unique_values(base_feedstock_std),
    Materials = collapse_unique_values(precursor_std),
    Metals = collapse_unique_values(metal),
    Water_matrix_classes = collapse_unique_values(water_matrix_class),
    .groups = "drop"
  ) |>
  rename(study_id = study_id_chr)

submission_s1 <- review_included_roster |>
  select(study_id, roster_source) |>
  left_join(study_characteristics_from_extraction, by = "study_id") |>
  mutate(
    Has_endpoint_record = !is.na(Extraction_records),
    Primary_synthesis_contributor =
      study_id %in% as.character(unique(dat$study_id)),
    Extraction_records = tidyr::replace_na(Extraction_records, 0L),
    Eligibility_accounting = case_when(
      Primary_synthesis_contributor ~
        "Included in primary Pb/Cd + three-precursor synthesis",
      Has_endpoint_record ~
        "Review/extraction study outside primary synthesis scope",
      TRUE ~
        "Review-included roster study without endpoint record in current extraction dataset"
    )
  ) |>
  transmute(
    Study = study_id,
    Publication_year_from_ID,
    Has_endpoint_record,
    Primary_synthesis_contributor,
    Extraction_records,
    Base_feedstocks,
    Materials,
    Metals,
    Water_matrix_classes,
    Eligibility_accounting,
    Roster_source = roster_source
  ) |>
  arrange(desc(Primary_synthesis_contributor), Publication_year_from_ID, Study)



# 19.17 Supplementary Table S2: search and exclusion accounting ----------------
submission_s2 <- tibble::tribble(
  ~Section, ~Stage, ~Count, ~Detail,
  "Identification", "Web of Science Core Collection", prisma_counts$wos,
  "Database-specific identified records.",
  "Identification", "Scopus", prisma_counts$scopus,
  "Database-specific identified records.",
  "Identification", "Google Scholar", prisma_counts$google_scholar,
  "Database-specific identified records.",
  "Identification", "Total records identified", prisma_counts$total_identified,
  "Sum of the three search sources.",
  "Deduplication", "Duplicate records removed before screening",
  prisma_counts$duplicates_removed,
  "Count supplied in PRISMA configuration; reconcile with the original screening log.",
  "Screening", "Records screened by title and abstract",
  prisma_counts$records_screened,
  "Count supplied in PRISMA configuration; reconcile with the original screening log.",
  "Screening", "Records excluded after title/abstract screening",
  prisma_counts$title_abstract_excluded,
  "Detailed title/abstract exclusion categories are not encoded in the analytical dataset.",
  "Eligibility", "Full-text articles sought for retrieval",
  prisma_counts$full_text_sought,
  "Count supplied in PRISMA configuration; reconcile with the original screening log.",
  "Eligibility", "Full-text articles not retrieved",
  prisma_counts$full_text_not_retrieved,
  "Count supplied in PRISMA configuration; reconcile with the original screening log.",
  "Eligibility", "Full-text articles assessed",
  prisma_counts$full_text_assessed,
  "Count supplied in PRISMA configuration; reconcile with the original screening log.",
  "Eligibility", "Full-text articles excluded",
  prisma_counts$full_text_excluded,
  "Detailed full-text exclusion reasons must come from the screening log; they are not inferred here.",
  "Eligibility", "Studies meeting broad eligibility criteria",
  prisma_counts$broad_eligibility,
  "Count supplied in PRISMA configuration; reconcile with the original screening log.",
  "Scope refinement", "Studies excluded during final review-scope refinement",
  prisma_counts$final_refinement_excluded,
  "Reported reasons include precursor outside the final three groups or insufficient standardized extractable data; verify study-level reasons against the screening log.",
  "Included", "Studies included in systematic review",
  prisma_counts$final_studies,
  "PRISMA review-level count.",
  "Extraction", "Studies represented in updated endpoint extraction dataset",
  prisma_counts$studies_with_endpoints,
  paste0("Count derived from ", basename(input_file), "."),
  "Primary synthesis", "Studies in primary Pb/Cd + three-precursor synthesis",
  prisma_counts$analysis_scope_studies,
  paste0("Count derived from ", basename(input_file), ".")
)

save_submission_table(
  submission_s2,
  "Table_S2_database_search_and_exclusion_accounting",
  submission_supp_tables_directory,
  title = "Table S2A. Database-specific search counts and exclusion accounting.",
  subtitle = "Detailed study-level exclusion reasons must be reconciled with the screening log and are not inferred from the analysis dataset.",
  left_columns = c(1, 2, 4)
)

# 19.18 Supplementary Table S3: domain-based critical appraisal ----------------
submission_s3 <- critical_appraisal |>
  transmute(
    Study = study_id,
    Primary_synthesis_contributor = primary_synthesis_contributor,
    Domain = as.character(domain),
    Provisional_dataset_signal = provisional_signal,
    Dataset_evidence = dataset_evidence,
    Final_rating = final_rating,
    Explanation = explanation,
    Source_page_or_table = page_table_reference,
    Completion_status = completion_status
  )

save_submission_table(
  submission_s3,
  "Table_S3_domain_based_critical_appraisal",
  submission_supp_tables_directory,
  title = "Table S3. Adsorption-specific domain-based critical appraisal.",
  subtitle = paste(
    "Domains are Experimental replication; Blanks and controls; Analytical validity;",
    "pH and solution chemistry; Adsorbent preparation and characterization;",
    "and Outcome measurement and reporting. Final ratings require source verification.",
    "Missing reporting is not automatically classified as poor practice."
  ),
  left_columns = c(1, 3:9)
)

# Also preserve a fillable CSV version for article-level appraisal work.
readr::write_csv(
  critical_appraisal_manual_template,
  file.path(
    submission_supp_data_directory,
    "critical_appraisal_manual_template.csv"
  ),
  na = ""
)

# 19.19 Supplementary Table S4: concise reporting completeness -----------------
submission_s4 <- submission_completeness |>
  filter(variable %in% key_completeness_variables) |>
  mutate(
    Variable = recode(variable, !!!pretty_variable_names)
  ) |>
  arrange(reported_percent) |>
  transmute(
    Variable,
    Analytical_units = total_units,
    Reported_n = reported_n,
    Missing_n = missing_n,
    Reported_percent = paste0(format_number(reported_percent, 1), "%"),
    Missing_percent = paste0(format_number(missing_percent, 1), "%")
  )



# 19.20 Supplementary Table S5: record-to-analysis-unit crosswalk --------------
# Export as CSV and, when writexl is available, XLSX. It is deliberately not
# rendered as a wide Word/HTML table.

submission_crosswalk <- record_to_analysis_unit_crosswalk |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS)

readr::write_csv(
  submission_crosswalk,
  file.path(
    submission_supp_data_directory,
    "Table_S5_record_to_analysis_unit_crosswalk.csv"
  ),
  na = ""
)

if (requireNamespace("writexl", quietly = TRUE)) {
  writexl::write_xlsx(
    list(record_to_analysis_unit_crosswalk = as.data.frame(submission_crosswalk)),
    path = file.path(
      submission_supp_data_directory,
      "Table_S5_record_to_analysis_unit_crosswalk.xlsx"
    )
  )
}

# 19.21 Supplementary Table S6: experimental conditions ------------------------
submission_condition_by_precursor <- purrr::map_dfr(
  condition_variables,
  ~ make_median_iqr(submission_analysis_unit, "precursor_std", .x)
) |>
  mutate(
    Section = "A. By precursor group",
    Condition = recode(outcome, !!!condition_labels),
    Group = as.character(precursor_std),
    Evidence = safe_group_n_flag(n_nonmissing)
  ) |>
  transmute(
    Section,
    Condition,
    Group,
    n = n_nonmissing,
    Median = format_number(median, 2),
    Q1 = format_number(q1, 2),
    Q3 = format_number(q3, 2),
    Minimum = format_number(min, 2),
    Maximum = format_number(max, 2),
    Evidence
  )

submission_condition_by_metal <- purrr::map_dfr(
  condition_variables,
  ~ make_median_iqr(submission_analysis_unit, "metal", .x)
) |>
  mutate(
    Section = "B. By target metal",
    Condition = recode(outcome, !!!condition_labels),
    Group = as.character(metal),
    Evidence = safe_group_n_flag(n_nonmissing)
  ) |>
  transmute(
    Section,
    Condition,
    Group,
    n = n_nonmissing,
    Median = format_number(median, 2),
    Q1 = format_number(q1, 2),
    Q3 = format_number(q3, 2),
    Minimum = format_number(min, 2),
    Maximum = format_number(max, 2),
    Evidence
  )

submission_s6 <- bind_rows(
  submission_condition_by_precursor,
  submission_condition_by_metal
)

save_submission_table(
  submission_s6,
  "Table_S6_experimental_conditions_by_precursor_and_metal",
  submission_supp_tables_directory,
  title = "Table S6. Experimental-condition distributions by precursor group and target metal.",
  subtitle = "Sections A and B document heterogeneity of study conditions; these summaries are descriptive rather than causal.",
  left_columns = c(1, 2, 3, 10)
)

# 19.22 Supplementary Table S7: sensitivity and matrix-specific summaries ------
submission_sensitivity_metal <- sensitivity_by_metal |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS) |>
  mutate(
    Section = "A. Sensitivity by metal",
    Scenario_or_matrix = scenario,
    Outcome = recode(
      outcome,
      qe_reported_mg_g_mid = "qₑ (mg g⁻¹)",
      qmax_reported_mg_g_mid = "Model-derived maximum adsorption capacity, qmax (mg g⁻¹)",
      removal_reported_percent_mid = "Removal (%)"
    ),
    Group = as.character(metal)
  ) |>
  transmute(
    Section,
    Scenario_or_matrix,
    Outcome,
    Group,
    n = n_nonmissing,
    Median = format_number(median, 2),
    Q1 = format_number(q1, 2),
    Q3 = format_number(q3, 2),
    Evidence = evidence_flag
  )

submission_sensitivity_precursor <- sensitivity_by_precursor |>
  mutate(
    Section = "B. Sensitivity by precursor",
    Scenario_or_matrix = scenario,
    Outcome = recode(
      outcome,
      qe_reported_mg_g_mid = "qₑ (mg g⁻¹)",
      qmax_reported_mg_g_mid = "Model-derived maximum adsorption capacity, qmax (mg g⁻¹)",
      removal_reported_percent_mid = "Removal (%)"
    ),
    Group = as.character(precursor_std)
  ) |>
  transmute(
    Section,
    Scenario_or_matrix,
    Outcome,
    Group,
    n = n_nonmissing,
    Median = format_number(median, 2),
    Q1 = format_number(q1, 2),
    Q3 = format_number(q3, 2),
    Evidence = evidence_flag
  )

submission_water_summary <- purrr::map_dfr(
  outcomes,
  ~ make_median_iqr(
    submission_analysis_unit_sensitivity,
    "water_matrix_class",
    .x
  )
) |>
  mutate(
    Section = "C. Water-matrix-specific summaries",
    Scenario_or_matrix = as.character(water_matrix_class),
    Outcome = recode(
      outcome,
      qe_reported_mg_g_mid = "qₑ (mg g⁻¹)",
      qmax_reported_mg_g_mid = "Model-derived maximum adsorption capacity, qmax (mg g⁻¹)",
      removal_reported_percent_mid = "Removal (%)"
    ),
    Group = "All target units",
    Evidence = safe_group_n_flag(n_nonmissing)
  ) |>
  transmute(
    Section,
    Scenario_or_matrix,
    Outcome,
    Group,
    n = n_nonmissing,
    Median = format_number(median, 2),
    Q1 = format_number(q1, 2),
    Q3 = format_number(q3, 2),
    Evidence
  )

submission_s7 <- bind_rows(
  submission_sensitivity_metal,
  submission_sensitivity_precursor,
  submission_water_summary
)

save_submission_table(
  submission_s7,
  "Table_S7_sensitivity_and_water_matrix_summaries",
  submission_supp_tables_directory,
  title = "Table S7. Sensitivity analyses and water-matrix-specific adsorption summaries.",
  subtitle = paste(
    "Extreme-value and matrix restrictions are sensitivity analyses only.",
    "Sparse subgroups remain descriptive and are reported with sample sizes."
  ),
  left_columns = c(1:4, 9)
)

# 19.23 Supplementary Table S8: actual regeneration observations ---------------
submission_s8 <- submission_analysis_unit |>
  filter(!is.na(regeneration_cycles), is.finite(regeneration_cycles)) |>
  transmute(
    Study = as.character(study_id),
    Adsorbent = as.character(adsorbent_id),
    Precursor = as.character(precursor_std),
    Metal = as.character(metal),
    Regeneration_cycles = regeneration_cycles,
    Water_matrix = as.character(water_matrix),
    Source_input_rows = source_input_rows
  ) |>
  arrange(Precursor, Metal, Study)



# 19.24 Supplementary Table S9: consolidated source-verification audit ----------
audit_extremes <- outcome_minimum_maximum_source_trace |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS) |>
  transmute(
    Audit_type = "Outcome extreme source trace",
    Study = as.character(study_id),
    Adsorbent = as.character(adsorbent_id),
    Metal = as.character(metal),
    Source_row = as.character(source_input_rows),
    Field = outcome,
    Observed_value = as.character(value),
    Issue = paste("Verify", extreme_position, "reported outcome against source."),
    Resolution_status = "Source verification required",
    Verified_value = NA_character_,
    Source_page_or_table = NA_character_,
    Resolution_note = NA_character_
  )

audit_invalid_removal <- invalid_removal_percentages |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS | is.na(metal)) |>
  transmute(
    Audit_type = "Invalid removal percentage",
    Study = as.character(study_id),
    Adsorbent = as.character(adsorbent_id),
    Metal = as.character(metal),
    Source_row = as.character(source_input_row),
    Field = "removal_reported_percent_mid",
    Observed_value = as.character(invalid_removal_percent),
    Issue = validation_reason,
    Resolution_status = "Source verification required",
    Verified_value = NA_character_,
    Source_page_or_table = NA_character_,
    Resolution_note = NA_character_
  )

audit_model_classification <- possible_model_field_misclassification |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS) |>
  transmute(
    Audit_type = "Model-field classification",
    Study = as.character(study_id),
    Adsorbent = as.character(adsorbent_id),
    Metal = as.character(metal),
    Source_row = as.character(source_input_row),
    Field = field,
    Observed_value = value,
    Issue = reason,
    Resolution_status = "Source verification required",
    Verified_value = NA_character_,
    Source_page_or_table = NA_character_,
    Resolution_note = NA_character_
  )

audit_structured_fields <- structured_field_validation_audit |>
  filter(
    standardized_metal %in% CONFIG$TARGET_METALS |
      is.na(standardized_metal)
  ) |>
  transmute(
    Audit_type = "Structured metal coding",
    Study = as.character(study_id),
    Adsorbent = as.character(adsorbent_id),
    Metal = standardized_metal,
    Source_row = as.character(source_input_row),
    Field = "metal / element / oxidation_state",
    Observed_value = paste(
      "metal=", metal_raw,
      "; element=", element_std,
      "; oxidation=", oxidation_state_std
    ),
    Issue = validation_issue,
    Resolution_status = "Source/data verification required",
    Verified_value = NA_character_,
    Source_page_or_table = NA_character_,
    Resolution_note = NA_character_
  )

audit_ph_caution <- precipitation_caution_units |>
  filter(as.character(metal) %in% CONFIG$TARGET_METALS) |>
  transmute(
    Audit_type = "pH / precipitation caution",
    Study = as.character(study_id),
    Adsorbent = as.character(adsorbent_id),
    Metal = as.character(metal),
    Source_row = as.character(source_input_rows),
    Field = "pH",
    Observed_value = as.character(ph_mid),
    Issue = paste(
      reviewer_screening_threshold,
      "- screening flag only; confirm speciation/precipitation treatment in source."
    ),
    Resolution_status = "Source interpretation required",
    Verified_value = NA_character_,
    Source_page_or_table = NA_character_,
    Resolution_note = NA_character_
  )

submission_s9 <- bind_rows(
  audit_extremes,
  audit_invalid_removal,
  audit_model_classification,
  audit_structured_fields,
  audit_ph_caution
) |>
  arrange(Audit_type, Study, Adsorbent, Source_row)



# Preserve the consolidated audit as an editable data file.
readr::write_csv(
  submission_s9,
  file.path(
    submission_supp_data_directory,
    "source_verification_audit_editable.csv"
  ),
  na = ""
)

# Reviewer agreement is copied into the submission package only when actual
# independent reviewer records were supplied and processed.
if (!is.null(reviewer_agreement_summary)) {
  readr::write_csv(
    reviewer_agreement_summary,
    file.path(
      submission_supp_data_directory,
      "critical_appraisal_reviewer_agreement_summary.csv"
    ),
    na = ""
  )
}


# 19.24 STUDY-LEVEL SENSITIVITY AND LEAVE-ONE-STUDY-OUT ------------------------
# Descriptive checks only. No independent-sample tests are added.
# Main estimates weight analytical units equally; aggregated estimates give each
# study equal representation within each outcome/metal or precursor stratum.

study_sensitivity_directory <- file.path(output_directory, "study_sensitivity")
dir.create(study_sensitivity_directory, recursive = TRUE, showWarnings = FALSE)

study_sensitivity_outcomes <- c(
  "qe_reported_mg_g_mid", "qmax_reported_mg_g_mid",
  "removal_reported_percent_mid"
)
study_sensitivity_labels <- c(
  qe_reported_mg_g_mid = "Equilibrium capacity (mg/g)",
  qmax_reported_mg_g_mid = "Maximum capacity (mg/g)",
  removal_reported_percent_mid = "Removal (%)"
)

# Validate the existing analytical-unit object before further aggregation.
required_sensitivity_columns <- c(
  "study_id", "adsorbent_id", "metal", "precursor_std",
  study_sensitivity_outcomes
)
missing_sensitivity_columns <- setdiff(
  required_sensitivity_columns, names(submission_analysis_unit)
)
if (length(missing_sensitivity_columns) > 0L) {
  stop("Missing study-sensitivity columns: ",
       paste(missing_sensitivity_columns, collapse = ", "))
}
if (anyDuplicated(submission_analysis_unit[c("study_id", "adsorbent_id", "metal")])) {
  stop("Study sensitivity requires one row per study-adsorbent-metal unit.")
}
if (any(is.na(submission_analysis_unit$study_id) |
        trimws(as.character(submission_analysis_unit$study_id)) == "")) {
  stop("Study sensitivity requires nonmissing study identifiers.")
}
if (!all(vapply(submission_analysis_unit[study_sensitivity_outcomes],
                is.numeric, logical(1)))) {
  stop("Study-sensitivity outcome fields must already be numeric.")
}

study_sensitivity_unit_long <- submission_analysis_unit |>
  select(all_of(required_sensitivity_columns)) |>
  mutate(across(c(study_id, adsorbent_id, metal, precursor_std), as.character)) |>
  pivot_longer(cols = all_of(study_sensitivity_outcomes),
               names_to = "outcome", values_to = "value") |>
  filter(is.finite(value)) |>
  filter(outcome != "removal_reported_percent_mid" | between(value, 0, 100))

study_sensitivity_metal_values <- study_sensitivity_unit_long |>
  group_by(study_id, metal, outcome) |>
  summarise(value = median(value), contributing_units = n(), .groups = "drop")
study_sensitivity_precursor_values <- study_sensitivity_unit_long |>
  group_by(study_id, precursor_std, metal, outcome) |>
  summarise(value = median(value), contributing_units = n(), .groups = "drop")

study_sensitivity_summarise <- function(data, group_columns) {
  data |>
    group_by(across(all_of(group_columns))) |>
    summarise(n_values = n(), n_studies = n_distinct(study_id),
              median = median(value),
              q1 = quantile(value, 0.25, names = FALSE),
              q3 = quantile(value, 0.75, names = FALSE), .groups = "drop")
}
study_sensitivity_compare <- function(main, aggregated, strata) {
  combined <- bind_rows(
    main |> mutate(analysis = "Main analytical units"),
    aggregated |> mutate(analysis = "One median per study")
  )
  summaries <- study_sensitivity_summarise(combined, c("analysis", strata))
  reference <- summaries |>
    filter(analysis == "Main analytical units") |>
    select(all_of(strata), main_median = median)
  summaries |>
    left_join(reference, by = strata) |>
    mutate(median_change = median - main_median,
           median_change_percent = if_else(
             main_median != 0, 100 * median_change / main_median, NA_real_
           ))
}
study_sensitivity_metal_summary <- study_sensitivity_compare(
  study_sensitivity_unit_long, study_sensitivity_metal_values,
  c("metal", "outcome")
)
study_sensitivity_precursor_summary <- study_sensitivity_compare(
  study_sensitivity_unit_long, study_sensitivity_precursor_values,
  c("precursor_std", "metal", "outcome")
)

# Study contributions diagnose unequal representation without deleting studies.
study_sensitivity_contributions <- study_sensitivity_unit_long |>
  count(outcome, metal, study_id, name = "n_analytical_units") |>
  group_by(outcome, metal) |>
  mutate(unit_share_percent = 100 * n_analytical_units / sum(n_analytical_units)) |>
  ungroup() |>
  arrange(outcome, metal, desc(n_analytical_units))

# Delete every contribution of one study at a time. Repeat for BOTH estimators.
# Entire strata disappearing after omission are retained explicitly as NA.
study_sensitivity_loo <- function(data, strata, estimator) {
  template <- study_sensitivity_summarise(data, strata) |>
    rename(full_median = median, full_n_values = n_values,
           full_n_studies = n_studies, full_q1 = q1, full_q3 = q3)
  ids <- sort(unique(data$study_id))
  if (length(ids) == 0L) return(tibble())
  pieces <- lapply(ids, function(omitted_id) {
    reduced <- data |> filter(study_id != omitted_id)
    estimates <- study_sensitivity_summarise(reduced, strata)
    template |>
      left_join(estimates, by = strata) |>
      mutate(omitted_study = omitted_id, estimator = estimator,
             omitted_study_contributed = n_studies < full_n_studies | is.na(n_studies),
             n_values = coalesce(n_values, 0L),
             n_studies = coalesce(n_studies, 0L),
             median_change = median - full_median,
             absolute_median_change = abs(median_change),
             median_change_percent = if_else(
               full_median != 0, 100 * median_change / full_median, NA_real_
             ))
  })
  bind_rows(pieces)
}
study_sensitivity_loo_metal <- bind_rows(
  study_sensitivity_loo(study_sensitivity_unit_long, c("metal", "outcome"),
                        "Main analytical units"),
  study_sensitivity_loo(study_sensitivity_metal_values, c("metal", "outcome"),
                        "One median per study")
)
study_sensitivity_loo_precursor <- bind_rows(
  study_sensitivity_loo(study_sensitivity_unit_long,
                        c("precursor_std", "metal", "outcome"),
                        "Main analytical units"),
  study_sensitivity_loo(study_sensitivity_precursor_values,
                        c("precursor_std", "metal", "outcome"),
                        "One median per study")
)
study_sensitivity_loo_largest_changes <- study_sensitivity_loo_metal |>
  filter(omitted_study_contributed, is.finite(absolute_median_change)) |>
  group_by(estimator, metal, outcome) |>
  slice_max(absolute_median_change, n = 1, with_ties = TRUE) |>
  ungroup()

study_sensitivity_exports <- list(
  study_level_metal_values = study_sensitivity_metal_values,
  study_level_precursor_metal_values = study_sensitivity_precursor_values,
  study_level_comparison_by_metal = study_sensitivity_metal_summary,
  study_level_comparison_by_precursor_and_metal = study_sensitivity_precursor_summary,
  study_contributions_by_outcome_and_metal = study_sensitivity_contributions,
  leave_one_study_out_by_metal = study_sensitivity_loo_metal,
  leave_one_study_out_by_precursor_and_metal = study_sensitivity_loo_precursor,
  leave_one_study_out_largest_median_changes = study_sensitivity_loo_largest_changes
)
for (export_name in names(study_sensitivity_exports)) {
  readr::write_csv(study_sensitivity_exports[[export_name]],
                   file.path(study_sensitivity_directory, paste0(export_name, ".csv")),
                   na = "")
}

if (nrow(study_sensitivity_metal_summary) > 0L) {
  study_sensitivity_figure <- study_sensitivity_metal_summary |>
    mutate(outcome_label = unname(study_sensitivity_labels[outcome])) |>
    ggplot(aes(x = median, y = analysis, colour = metal, group = metal)) +
    geom_errorbar(aes(xmin = q1, xmax = q3), orientation = "y",
                  width = 0.18, position = position_dodge(width = 0.5)) +
    geom_point(position = position_dodge(width = 0.5), size = 2.5) +
    facet_wrap(~ outcome_label, scales = "free_x", ncol = 3) +
    labs(title = "Study-level aggregation sensitivity",
         subtitle = "Points are medians; bars are interquartile ranges, not confidence intervals.",
         x = "Median with interquartile range", y = NULL, colour = "Metal") +
    theme_bw(base_size = CONFIG$FIGURE_BASE_SIZE) +
    theme(legend.position = "bottom", plot.title.position = "plot")
  ggsave(file.path(study_sensitivity_directory, "study_level_sensitivity.png"),
         study_sensitivity_figure, width = 12, height = 5,
         dpi = CONFIG$DPI, bg = "white")
}

writeLines(c(
  "STUDY-LEVEL SENSITIVITY ANALYSIS",
  "Input: validated final study-adsorbent-metal analytical units.",
  "Metal analysis: one median per study, metal and outcome.",
  "Precursor analysis: one median per study, precursor, metal and outcome.",
  "The aggregated estimates are medians of unit medians, not original-row medians.",
  "Leave-one-study-out removes all contributions from each omitted study.",
  "Both the main-unit and study-aggregated estimators are checked.",
  "Compare median changes, IQRs, subgroup sample sizes and group ordering.",
  "Sparse or disappearing strata cannot establish robustness.",
  "IQRs describe distributions; they are not confidence intervals.",
  "Study aggregation does not remove between-study confounding or pairing.",
  "No independent-sample tests, equivalence claims or automatic robustness labels are added.",
  "These analyses do not correct unverified outcome definitions or extraction errors.",
  "METHODS TEXT:",
  paste("To assess unequal study representation, we repeated the descriptive",
        "synthesis using one median per study and target metal for each outcome.",
        "Precursor summaries used one median per study, precursor and metal.",
        "We also omitted each contributing study in turn and recalculated",
        "both analytical-unit and study-level summaries. Changes in medians,",
        "interquartile ranges, sample sizes and group ordering were examined.")
), file.path(study_sensitivity_directory, "README_study_level_sensitivity.txt"))
message("Study-level and leave-one-study-out outputs: ", study_sensitivity_directory)

# 19.25 TABLE SELECTION AND COMPLETION CHECKS ---------------------------------
# Completion checks concern supplied documentation, not independent authentication.
# They never invent study identities, reviewer decisions or source-verification results.
table_work_directory <- file.path(output_directory, "author_work")
dir.create(table_work_directory, recursive = TRUE, showWarnings = FALSE)
nonblank_table <- function(x) !is.na(x) & nzchar(trimws(as.character(x)))

roster_count_matches <- n_distinct(submission_s1$Study) == prisma_counts$final_studies
roster_supplied <- file.exists(CONFIG$REVIEW_INCLUDED_STUDY_ROSTER_FILE)
appraisal_table_complete <- nrow(critical_appraisal) > 0L &&
  all(nonblank_table(critical_appraisal$final_rating)) &&
  all(nonblank_table(critical_appraisal$explanation)) &&
  all(nonblank_table(critical_appraisal$page_table_reference))

# S1: retain the available roster honestly; parsed years are not verified metadata.
submission_s1 <- submission_s1 |>
  mutate(Publication_year_from_ID = as.character(Publication_year_from_ID),
         Has_endpoint_record = if_else(Has_endpoint_record, "Yes", "No"),
         Primary_synthesis_contributor = if_else(Primary_synthesis_contributor, "Yes", "No"))
save_submission_table(
  submission_s1, "Table_S1_included_study_characteristics_and_eligibility",
  submission_supp_tables_directory,
  title = if (roster_supplied && roster_count_matches)
    "Table S1. Characteristics and synthesis eligibility of the supplied review roster."
  else "Table S1. Characteristics of studies represented in the available extraction roster.",
  subtitle = paste0("Available roster: ", nrow(submission_s1),
                    " studies; stated review inclusion: ", prisma_counts$final_studies,
                    ". Years are parsed from study IDs and require bibliographic verification.",
                    " A matching count alone does not verify eligibility or roster completeness."),
  left_columns = c(1, 6:11)
)

# S2: write blank AUTHOR templates when actual search/exclusion records are absent.
# Optional completed input files must be in the working directory beside the input CSV.
search_columns <- c("Database", "Search_date", "Search_fields", "Full_search_string",
                    "Limits", "Records_identified", "Screening_approach")
exclusion_columns <- c("Study_or_report_ID", "Citation", "Stage", "Primary_reason",
                       "Source_log_reference")
read_table_input <- function(filename, columns) {
  if (!file.exists(filename)) {
    template <- as_tibble(setNames(rep(list(character()), length(columns)), columns))
    readr::write_csv(template, file.path(table_work_directory, filename))
    return(NULL)
  }
  x <- readr::read_csv(filename, col_types = readr::cols(.default = readr::col_character()),
                       show_col_types = FALSE)
  missing <- setdiff(columns, names(x))
  if (length(missing)) stop(filename, " is missing: ", paste(missing, collapse = ", "))
  x
}
search_details <- read_table_input("database_search_details.csv", search_columns)
exclusion_details <- read_table_input("full_text_exclusion_log.csv", exclusion_columns)
if (!is.null(search_details) && nrow(search_details) > 0L) {
  save_submission_table(search_details, "Table_S2B_database_search_strategies",
                         submission_supp_tables_directory,
                         title = "Table S2B. Author-supplied database search strategies.",
                         left_columns = seq_along(search_columns))
}
if (!is.null(exclusion_details) && nrow(exclusion_details) > 0L) {
  save_submission_table(exclusion_details, "Table_S2C_study_level_exclusions",
                         submission_supp_tables_directory,
                         title = "Table S2C. Author-supplied study-level exclusions.",
                         subtitle = "Reconcile counts by exclusion stage with Table S2A and PRISMA.",
                         left_columns = seq_along(exclusion_columns))
}

# S4: pH recorded is not proof that pH was controlled. Numeric cycle reporting
# includes a zero if present; actual reuse evidence is handled separately in S8.
submission_s4 <- submission_s4 |>
  mutate(Variable = case_when(
    Variable == "pH control/reporting" ~ "pH information recorded (control not established)",
    Variable == "Regeneration cycles" ~ "Numeric cycle entry (including zero)",
    TRUE ~ Variable))
save_submission_table(submission_s4, "Table_S4_reporting_completeness",
  submission_supp_tables_directory,
  title = "Table S4. Reporting completeness across primary analytical units.",
  subtitle = "Entries describe extracted information. They do not establish methodological adequacy or successful regeneration.",
  left_columns = 1)

# S8: preserve every numeric observation; do not silently interpret zero as reuse.
submission_s8 <- submission_s8 |>
  mutate(Interpretation = case_when(
    Regeneration_cycles > 0 ~ "Positive cycle entry; verify testing and retained performance in source",
    Regeneration_cycles == 0 ~ "Zero-cycle entry; does not demonstrate reuse and requires source clarification",
    TRUE ~ "Invalid negative cycle entry; source correction required"))
save_submission_table(submission_s8, "Table_S8_regeneration_observations",
  submission_supp_tables_directory,
  title = "Table S8. Recorded regeneration-cycle observations requiring contextual interpretation.",
  subtitle = "Positive entries, zero entries and demonstrated retained performance must not be conflated.",
  left_columns = c(1:4, 6:8))

# S9: optional completed audit. All original fields must match the current audit
# to prevent stale verification being applied after extraction changes.
source_audit_input <- "source_verification_completed.csv"
source_audit_complete <- FALSE
if (file.exists(source_audit_input)) {
  supplied_audit <- readr::read_csv(source_audit_input,
    col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
  audit_columns <- names(submission_s9)
  if (!all(audit_columns %in% names(supplied_audit))) {
    stop("source_verification_completed.csv must preserve all current audit columns.")
  }
  audit_keys <- c("Audit_type", "Study", "Adsorbent", "Metal", "Source_row", "Field",
                  "Observed_value", "Issue")
  if (anyDuplicated(supplied_audit[audit_keys])) stop("Duplicate keys in completed source audit.")
  current_keys <- submission_s9 |> select(all_of(audit_keys))
  if (nrow(anti_join(current_keys, supplied_audit, by = audit_keys)) > 0L ||
      nrow(anti_join(supplied_audit, current_keys, by = audit_keys)) > 0L) {
    stop("Completed source audit does not match the current extraction; reconcile it before rerunning.")
  }
  allowed_audit_status <- c("Verified unchanged", "Corrected in input data", "Resolved interpretation")
  source_audit_complete <- nrow(supplied_audit) > 0L &&
    all(supplied_audit$Resolution_status %in% allowed_audit_status) &&
    all(nonblank_table(supplied_audit$Verified_value)) &&
    all(nonblank_table(supplied_audit$Source_page_or_table)) &&
    all(nonblank_table(supplied_audit$Resolution_note))
  submission_s9 <- supplied_audit |> select(all_of(audit_columns))
}
readr::write_csv(submission_s9,
  file.path(table_work_directory, "source_verification_completed.csv"), na = "")
{
  save_submission_table(submission_s9, "Table_S9_source_verification_audit",
    submission_supp_tables_directory,
    title = if (source_audit_complete) "Table S9. Author-completed source-verification audit." else "Working source-verification audit: unresolved entries remain.",
    subtitle = "Source corrections must also be applied to the extraction input and analyses rerun; completing this audit does not change analytical data.",
    left_columns = seq_len(ncol(submission_s9)))
}

# S10: concise study-level aggregation and leave-one-study-out summary.
# Full per-omission values remain in the machine-readable data supplement.
submission_s10a <- bind_rows(
  study_sensitivity_metal_summary |> mutate(Precursor = "All precursors"),
  study_sensitivity_precursor_summary |> rename(Precursor = precursor_std)
) |>
  transmute(Section = "A. Study-level aggregation", Precursor, Metal = metal,
            Outcome = outcome, Estimator = analysis, Studies = n_studies,
            Values = n_values, Median = median, Q1 = q1, Q3 = q3,
            Median_change = median_change)
submission_s10b <- study_sensitivity_loo_largest_changes |>
  transmute(Section = "B. Largest leave-one-study-out changes by metal",
            Precursor = "All precursors", Metal = metal, Outcome = outcome,
            Estimator = estimator, Omitted_study = omitted_study,
            Studies = n_studies, Values = n_values, Median = median,
            Q1 = q1, Q3 = q3, Median_change = median_change)
submission_s10 <- bind_rows(submission_s10a, submission_s10b)
save_submission_table(submission_s10, "Table_S10_study_level_sensitivity",
  submission_supp_tables_directory,
  title = "Table S10. Study-level aggregation and leave-one-study-out sensitivity.",
  subtitle = "IQRs describe distributions, not confidence intervals. All tied maximum absolute median changes are shown. Strata disappearing after omission are recorded in the full data supplement.",
  left_columns = c(1:5, ncol(submission_s10)))

table_release_status <- tibble::tribble(
  ~Table, ~Decision, ~Reason,
  "S1", "Retain with explicit roster scope", "Reconcile available extraction roster with review inclusion and verify metadata.",
  "S2", "Retain accounting; add supplied search and exclusion records", "Search strings and individual exclusions cannot be inferred from extracted outcomes.",
  "S3 and main Table 4", if (appraisal_table_complete) "Retain completed appraisal" else "Author working files only", "All ratings, explanations and source references are required; review-wide coverage must still be checked.",
  "S4", "Retain", "Reporting completeness is separate from critical appraisal.",
  "S5", "Retain spreadsheet", "Record-to-analysis-unit crosswalk.",
  "S6", "Retain", "Descriptive experimental-condition heterogeneity.",
  "S7", "Retain", "Extreme-value, matrix and pH-screen sensitivity summaries.",
  "S8", "Retain with explicit interpretation", "Zero cycles do not demonstrate reuse; verify source context.",
  "S9", if (source_audit_complete) "Retain author-completed audit" else "Author working files only", "Unresolved audit entries are not completed verification results.",
  "S10", "Retain", "Study aggregation and concise leave-one-study-out summary."
)
readr::write_csv(table_release_status, file.path(table_work_directory, "table_selection_status.csv"))
writeLines(c(
  "AUTHOR ACTIONS BEFORE SUBMISSION",
  "Complete the review roster and verify publication years against article metadata.",
  "Supply database_search_details.csv and full_text_exclusion_log.csv in the working directory.",
  "Complete critical_appraisal_manual.csv using the existing appraisal template.",
  "Complete source_verification_completed.csv with exact source references and resolution notes.",
  "Apply actual extraction corrections to the input dataset, rerun analysis, and reconcile the audit with the updated values.",
  "Appraisal and audit completion checks assess populated fields, not the truth of judgments.",
  "Old eight-item percentage scores and reconstructed screening agreement are not submission outputs.",
  "Numeric cycle entries alone do not establish regeneration testing or successful reuse."
), file.path(table_work_directory, "AUTHOR_ACTIONS.txt"))

# 19.25A CLASSIFICATION CATALOGUE: TABLE S11A -------------------------------
# Match exact study/material identifiers after trimming whitespace. No fuzzy
# matches, row expansion, or automatic replacement of extraction values.
catalogue_dataset_keys <- raw_with_row |>
  transmute(study_id = stringr::str_squish(as.character(study_id)),
    adsorbent_id = stringr::str_squish(as.character(adsorbent_id))) |>
  filter(!is.na(study_id), nzchar(study_id)) |>
  distinct()
if (any(is.na(catalogue_dataset_keys$adsorbent_id) |
        !nzchar(catalogue_dataset_keys$adsorbent_id))) stop("Extraction contains blank adsorbent IDs.")
catalogue_unmatched <- anti_join(catalogue_dataset_keys, classification_catalogue,
  by = c("study_id", "adsorbent_id"))
catalogue_unused <- anti_join(classification_catalogue, catalogue_dataset_keys,
  by = c("study_id", "adsorbent_id"))
catalogue_matched <- semi_join(classification_catalogue, catalogue_dataset_keys,
  by = c("study_id", "adsorbent_id")) |>
  arrange(study_id, adsorbent_id)
readr::write_csv(catalogue_unmatched,
  file.path(table_work_directory, "catalogue_unmatched_dataset_materials.csv"), na = "")
readr::write_csv(catalogue_unused,
  file.path(table_work_directory, "catalogue_materials_outside_current_dataset.csv"), na = "")
catalogue_coverage <- tibble(
  Dataset_materials = nrow(catalogue_dataset_keys),
  Matched_materials = nrow(catalogue_matched),
  Unmatched_materials = nrow(catalogue_unmatched),
  Catalogue_materials_outside_dataset = nrow(catalogue_unused))
readr::write_csv(catalogue_coverage,
  file.path(table_work_directory, "catalogue_coverage.csv"))

catalogue_field_map <- c(precursor_std = "Precursor",
  preparation_route = "Preparation route", activation_route = "Activation route",
  modification_route = "Modification route", treatment_agent = "Treatment agent",
  source_location = "Source location")
catalogue_compare <- catalogue_matched |>
  select(study_id, adsorbent_id, all_of(unname(catalogue_field_map))) |>
  pivot_longer(-c(study_id, adsorbent_id), names_to = "Catalogue_field",
    values_to = "Catalogue_value") |>
  mutate(Field = names(catalogue_field_map)[match(Catalogue_field, catalogue_field_map)])
catalogue_differences <- raw_with_row |>
  select(source_input_row, study_id, adsorbent_id, all_of(names(catalogue_field_map))) |>
  mutate(across(c(study_id, adsorbent_id), ~ stringr::str_squish(as.character(.x)))) |>
  pivot_longer(all_of(names(catalogue_field_map)), names_to = "Field",
    values_to = "Dataset_value") |>
  inner_join(catalogue_compare, by = c("study_id", "adsorbent_id", "Field")) |>
  mutate(Dataset_value = stringr::str_squish(Dataset_value),
    Different = coalesce(Dataset_value, "") != coalesce(Catalogue_value, "")) |>
  filter(Different) |>
  select(-Different) |>
  mutate(Action = "Review wording or classification against the source; no automatic overwrite")
readr::write_csv(catalogue_differences,
  file.path(table_work_directory, "catalogue_dataset_differences.csv"), na = "")
submission_s11a <- catalogue_matched |>
  rename(`Study ID` = study_id, `Adsorbent ID` = adsorbent_id) |>
  select(all_of(catalogue_columns))
save_submission_table(submission_s11a,
  "Table_S11A_preparation_and_treatment_classification_catalogue",
  submission_supp_tables_directory,
  title = "Table S11A. Preparation and treatment classifications of materials in the current extraction dataset.",
  subtitle = paste0(nrow(catalogue_matched), " matched materials; ",
    nrow(catalogue_unmatched), " unmatched dataset materials. ",
    "Scope is the extraction dataset, not the complete review roster. ",
    "None reported indicates absence of documentation; Unclear indicates an unresolved classification. ",
    "NA is retained as supplied and requires clarification, not automatically interpreted as not applicable. ",
    "Source references are author-supplied. Matching does not independently verify classifications."),
  left_columns = seq_len(ncol(submission_s11a)))

# 19.26 PREPARATION, ACTIVATION AND MODIFICATION ROUTE SUMMARIES --------------
# Descriptive medians/IQRs, separately for qe, qmax and removal. These are not
# causal route effects. Study counts accompany unit counts in every stratum.
route_classification_audit <- dat_all_extracted |>
  mutate(
    preparation_route_primary = route_label(preparation_route),
    preparation_route_structured = route_label(production_route_std),
    modification_route_primary = route_label(modification_route),
    modification_route_structured = route_label(modification_route_std),
    preparation_text_difference =
      !is.na(preparation_route_primary) &
      !is.na(preparation_route_structured) &
      stringr::str_to_lower(preparation_route_primary) !=
        stringr::str_to_lower(preparation_route_structured),
    modification_text_difference =
      !is.na(modification_route_primary) &
      !is.na(modification_route_structured) &
      stringr::str_to_lower(modification_route_primary) !=
        stringr::str_to_lower(modification_route_structured)
  ) |>
  filter(preparation_text_difference | modification_text_difference) |>
  select(
    source_input_row, study_id, adsorbent_id, metal,
    all_of(route_source_columns),
    preparation_group, activation_group, modification_group,
    preparation_route_primary, preparation_route_structured,
    modification_route_primary, modification_route_structured,
    preparation_text_difference, modification_text_difference
  )
readr::write_csv(
  route_classification_audit,
  file.path(table_work_directory, "route_classification_text_differences.csv"),
  na = ""
)
route_unit_audit <- route_unit_metadata |>
  filter(if_any(c(preparation_group, activation_group, modification_group),
    ~ .x == "Multiple classifications within analytical unit"))
readr::write_csv(route_unit_audit,
  file.path(table_work_directory, "route_classification_within_unit.csv"), na = "")
route_outcomes_long <- submission_analysis_unit |>
  select(study_id, adsorbent_id, metal, precursor_std, preparation_group,
    activation_group, modification_group, all_of(outcomes)) |>
  pivot_longer(all_of(outcomes), names_to = "Outcome", values_to = "Value") |>
  filter(is.finite(Value),
    Outcome != "removal_reported_percent_mid" | (Value >= 0 & Value <= 100)) |>
  pivot_longer(c(preparation_group, activation_group, modification_group),
    names_to = "Classification", values_to = "Route")
route_outcome_summary <- route_outcomes_long |>
  group_by(Classification, Route, precursor_std, metal, Outcome) |>
  summarise(Studies = n_distinct(study_id), Analytical_units = n(),
    Median = median(Value), Q1 = unname(quantile(Value, .25)),
    Q3 = unname(quantile(Value, .75)), .groups = "drop")
route_study_values <- route_outcomes_long |>
  group_by(Classification, Route, precursor_std, metal, Outcome, study_id) |>
  summarise(Value = median(Value), .groups = "drop")
route_study_summary <- route_study_values |>
  group_by(Classification, Route, precursor_std, metal, Outcome) |>
  summarise(Studies = n_distinct(study_id), Analytical_units = NA_integer_,
    Median = median(Value), Q1 = unname(quantile(Value, .25)),
    Q3 = unname(quantile(Value, .75)), .groups = "drop")
submission_s11 <- bind_rows(
  route_outcome_summary |> mutate(Estimator = "Analytical-unit median"),
  route_study_summary |> mutate(Estimator = "Study-aggregated median")) |>
  mutate(Evidence = if_else(Studies < CONFIG$MIN_GROUP_N_FOR_INTERPRETATION,
    "Sparse study support; descriptive only", "Descriptive; uncontrolled study differences"))
save_submission_table(submission_s11,
  "Table_S11B_adsorption_outcomes_by_preparation_and_treatment_route",
  submission_supp_tables_directory,
  title = "Table S11B. Adsorption outcomes by preparation, activation and modification route.",
  subtitle = paste("Outcomes retain their original units. IQRs describe distributions.",
    "Route summaries use the explicit preparation_route, activation_route, and modification_route fields. Parallel *_std fields are retained for audit rather than merged by exact text. None reported means no route was documented, not confirmed absence.",
    "Route strata overlap across classification dimensions and must not be summed."),
  left_columns = c(1:5, 11:12))
readr::write_csv(route_study_values,
  file.path(study_sensitivity_directory, "study_level_route_values.csv"), na = "")
writeLines(c("ROUTE CLASSIFICATION POLICY",
  "Descriptive route summaries use preparation_route, activation_route, and modification_route as their explicit source classifications.",
  "The parallel production_route_std and modification_route_std fields are retained for text-difference audit and are not merged by exact string equality.",
  "A text difference between parallel vocabularies is not automatically interpreted as a scientific classification conflict.",
  "None reported is not evidence of no activation or modification.",
  "No route is inferred from chemical names or activation temperature alone.",
  "Multiple labels within a study-adsorbent-metal unit remain a mixed class; main outcome aggregation is unchanged.",
  "Resolve discrepancies in the extraction dataset against source_location before final interpretation.",
  "Missing numeric regeneration entries produce an empty S8; they do not demonstrate zero cycles.",
  "Review-wide PRISMA inclusion remains author-supplied and must not be replaced by the number of studies in the extraction file."),
  file.path(table_work_directory, "ROUTE_CLASSIFICATION_POLICY.txt"))

# 20. SESSION INFORMATION ------------------------------------------------------

capture.output(
  sessionInfo(),
  file = file.path(output_directory, "session_info.txt")
)

# 21. RETAIN ONLY RELEVANT DELIVERABLES ----------------------------------------
# Earlier exports are intermediate files in a short temporary directory.
# Only the final submission package and reproducibility data are retained below.
relevant_output_directory <- final_relevant_output_directory
if (!dir.exists(relevant_output_directory)) {
  dir.create(relevant_output_directory, recursive = TRUE)
}
relevant_export_manifest <- tibble(source = character(), output = character())
retain_relevant_file <- function(source, folder) {
  if (!file.exists(source)) return(invisible(FALSE)) # Optional artifacts only; required outputs checked below.
  destination_folder <- file.path(relevant_output_directory, folder)
  dir.create(destination_folder, recursive = TRUE, showWarnings = FALSE)
  destination <- file.path(destination_folder, basename(source))
  if (!file.copy(source, destination, overwrite = TRUE)) {
    stop("Could not save relevant output: ", destination,
         ". Check permissions and close this file in other applications.")
  }
  relevant_export_manifest <<- bind_rows(
    relevant_export_manifest, tibble(source = source, output = destination)
  )
  invisible(TRUE)
}

# PNG is the default; additional formats are retained only when configured.
for (folder_pair in list(
  c(submission_main_figures_directory, "main_figures"),
  c(submission_supp_figures_directory, "supp_figures")
)) {
  files <- list.files(folder_pair[1], pattern = "\\.(png|pdf|tiff)$", full.names = TRUE)
  for (source in files) retain_relevant_file(source, folder_pair[2])
}

# Word tables are retained when available; otherwise keep CSV fallbacks.
# Machine-readable CSV values are retained alongside presentation DOCX files.
for (folder_pair in list(
  c(submission_main_tables_directory, "main_tables"),
  c(submission_supp_tables_directory, "supp_tables")
)) {
  files <- list.files(folder_pair[1], pattern = "\\.(docx|csv)$", full.names = TRUE)
  stems <- unique(tools::file_path_sans_ext(basename(files)))
  for (stem in stems) {
    candidates <- files[tools::file_path_sans_ext(basename(files)) == stem]
    docx <- candidates[grepl("\\.docx$", candidates)]
    selected <- if (length(docx)) docx[1] else candidates[1]
    destination_group <- folder_pair[2]
    if (stem %in% c("Table_S3_domain_based_critical_appraisal", "Table_4_critical_appraisal_summary") &&
        !appraisal_table_complete) destination_group <- "author_work"
    if (stem == "Table_S9_source_verification_audit" &&
        !source_audit_complete) destination_group <- "author_work"
    retain_relevant_file(selected, destination_group)
    csv <- candidates[grepl("\\.csv$", candidates)]
    if (length(csv) && length(docx)) retain_relevant_file(csv[1],
      if (destination_group == "author_work") "author_work" else "data/tables")
  }
}

# Crosswalk: one workbook if available, otherwise one CSV.
crosswalk_stem <- "Table_S5_record_to_analysis_unit_crosswalk"
crosswalk_xlsx <- file.path(submission_supp_data_directory,
                            paste0(crosswalk_stem, ".xlsx"))
crosswalk_csv <- file.path(submission_supp_data_directory,
                           paste0(crosswalk_stem, ".csv"))
retain_relevant_file(if (file.exists(crosswalk_xlsx)) crosswalk_xlsx else crosswalk_csv,
                      "data")
for (filename in c("source_verification_audit_editable.csv",
                    "critical_appraisal_manual_template.csv",
                    "critical_appraisal_reviewer_agreement_summary.csv")) {
  retain_relevant_file(file.path(submission_supp_data_directory, filename),
    if (filename %in% c("source_verification_audit_editable.csv",
                        "critical_appraisal_manual_template.csv")) "author_work" else "data")
}

# Preserve validated row-level data and the exact units used for synthesis.
data_folder <- file.path(relevant_output_directory, "data")
dir.create(data_folder, recursive = TRUE, showWarnings = FALSE)
readr::write_csv(dat, file.path(data_folder, "validated_scope_records.csv"), na = "")
readr::write_csv(submission_analysis_unit,
                 file.path(data_folder, "primary_analysis_units.csv"), na = "")

# Study-level values, comparisons, contributions and leave-one-study-out results
# are retained as machine-readable supplementary evidence.
for (source in list.files(study_sensitivity_directory,
                           pattern = "\\.(csv|png|txt)$", full.names = TRUE)) {
  retain_relevant_file(source, "study_sensitivity")
}
retain_relevant_file(file.path(output_directory, "session_info.txt"), "notes")
retain_relevant_file(file.path(output_directory, "audit_unexpected_input_columns.csv"), "author_work")

for (source in list.files(table_work_directory, full.names = TRUE)) {
  retain_relevant_file(source, "author_work")
}

# 22. REPRODUCIBILITY RECORD AND COMPLETION GATES ------------------------------
# These gates assess file/schema completeness, never the truth of source judgments.
repro_directory <- file.path(relevant_output_directory, "reproducibility")
dir.create(repro_directory, recursive = TRUE, showWarnings = FALSE)
input_paths <- unique(c(input_file, classification_catalogue_file, CONFIG$REVIEW_INCLUDED_STUDY_ROSTER_FILE,
  CONFIG$CRITICAL_APPRAISAL_MANUAL_FILE, CONFIG$REVIEWER_AGREEMENT_FILE,
  "database_search_details.csv", "full_text_exclusion_log.csv",
  "source_verification_completed.csv", "screening_counts_source.csv"))
input_paths <- input_paths[file.exists(input_paths)]
if (anyDuplicated(basename(input_paths))) stop("Input basenames must be unique for the reproducibility bundle.")
input_archive <- file.path(repro_directory, "inputs")
dir.create(input_archive, recursive = TRUE, showWarnings = FALSE)
if (!all(file.copy(input_paths, input_archive, overwrite = FALSE))) stop("Could not archive all input files.")
readr::write_csv(tibble(
  file = paste0("inputs/", basename(input_paths)),
  bytes = unname(file.info(input_paths)$size),
  md5 = unname(tools::md5sum(input_paths))
), file.path(repro_directory, "input_checksums.csv"))
script_archived <- !is.null(SCRIPT_FILE) && length(SCRIPT_FILE) == 1L && file.exists(SCRIPT_FILE)
if (script_archived) {
  script_archived <- file.copy(SCRIPT_FILE,
    file.path(repro_directory, "analysis_v28_5.R"), overwrite = FALSE)
}
if (file.exists("renv.lock")) {
  if (!file.copy("renv.lock", repro_directory, overwrite = FALSE)) stop("Could not archive renv.lock.")
}
loaded_packages <- sort(unique(c(loadedNamespaces(), required_packages)))
readr::write_csv(tibble(package = loaded_packages,
  version = vapply(loaded_packages, function(p) as.character(utils::packageVersion(p)), character(1))),
  file.path(repro_directory, "package_versions.csv"))
dput(list(RUN_MODE = RUN_MODE, RANDOM_SEED = RANDOM_SEED, CONFIG = CONFIG,
  input_file = basename(input_file), INPUT_ENCODING = INPUT_ENCODING, input_sheet = input_sheet,
  classification_catalogue_file = basename(classification_catalogue_file),
  CATALOGUE_ENCODING = CATALOGUE_ENCODING),
  file = file.path(repro_directory, "run_configuration.R"))
readr::write_csv(tibble(column = required_columns,
  expected_type = ifelse(required_columns %in% numeric_columns, "numeric", "character"),
  note = ifelse(required_columns == "uncertainty_value",
    "Mixed representations; not automatically assigned to an outcome variance.",
    "See import/cleaning code for parsing and missing-value rules.")),
  file.path(repro_directory, "input_schema.csv"))
# Preserve screening provenance and all values used to construct the PRISMA flow.
readr::write_csv(prisma_screening_counts,
  file.path(repro_directory, "prisma_counts_used.csv"))
screening_template <- prisma_screening_counts |>
  mutate(Source_reference = NA_character_)
screening_documented <- FALSE
if (file.exists("screening_counts_source.csv")) {
  screening_source <- readr::read_csv("screening_counts_source.csv", show_col_types = FALSE,
    col_types = readr::cols(Stage = readr::col_character(), Count = readr::col_double(),
                          Source_reference = readr::col_character()))
  if (!all(c("Stage", "Count", "Source_reference") %in% names(screening_source))) {
    stop("screening_counts_source.csv needs Stage, Count, Source_reference columns.")
  }
  screening_documented <- !anyDuplicated(screening_source$Stage) &&
    nrow(screening_source) == nrow(prisma_screening_counts) &&
    nrow(anti_join(prisma_screening_counts, screening_source, by = c("Stage", "Count"))) == 0L &&
    all(nonblank_table(screening_source$Source_reference))
}
readr::write_csv(screening_template,
  file.path(table_work_directory, "screening_counts_source_TEMPLATE.csv"), na = "")
retain_relevant_file(file.path(table_work_directory, "screening_counts_source_TEMPLATE.csv"), "author_work")
complete_fields <- function(x, fields) {
  !is.null(x) && nrow(x) > 0L && all(fields %in% names(x)) &&
    all(vapply(x[fields], function(v) all(nonblank_table(v)), logical(1)))
}
roster_covers_extraction <- all(unique(as.character(dat_all_extracted$study_id)) %in%
                                as.character(review_included_roster$study_id))
appraisal_covers_roster <- setequal(critical_appraisal$study_id, review_included_roster$study_id) &&
  nrow(critical_appraisal) == nrow(review_included_roster) * length(critical_appraisal_domains)
documentation_checks <- tibble(
  check = c("Full roster supplied and count reconciled", "Roster covers extraction IDs",
    "Appraisal complete across roster", "Search details populated", "Exclusion log populated",
    "Source audit resolved or no flagged rows", "PRISMA count provenance supplied",
    "Exact script archived"),
  passed = c(roster_supplied && roster_count_matches, roster_covers_extraction,
    appraisal_table_complete && appraisal_covers_roster,
    complete_fields(search_details, search_columns),
    complete_fields(exclusion_details, exclusion_columns),
    source_audit_complete || nrow(submission_s9) == 0L,
    screening_documented, script_archived))
documentation_checks <- bind_rows(documentation_checks, tibble(
  check = "Route classifications reconciled",
  passed = nrow(route_classification_audit) == 0L && nrow(route_unit_audit) == 0L))
documentation_checks <- bind_rows(documentation_checks, tibble(
  check = "Classification catalogue covers current dataset materials",
  passed = nrow(catalogue_unmatched) == 0L))
readr::write_csv(documentation_checks,
  file.path(repro_directory, "documentation_checks.csv"))

# Verify expected outputs, including conditional release destinations.
expected_figures <- c("Figure_1_PRISMA", "Figure_2_data_completeness",
  "Figure_3_adsorption_performance_by_metal", "Figure_4_adsorption_performance_by_precursor",
  "Figure_5_experimental_condition_heterogeneity")
expected_supp_figures <- c("Figure_S1_combined_model_reporting",
  "Figure_S2_extreme_value_sensitivity", "Figure_S3_water_matrix_sensitivity")
if (isTRUE(CONFIG$EXPORT_OPTIONAL_PH_FIGURE)) expected_supp_figures <- c(
  expected_supp_figures, "Figure_S4_optional_pH_precipitation_caution")
figure_formats <- c("png", if (isTRUE(CONFIG$EXPORT_PDF)) "pdf",
                    if (isTRUE(CONFIG$EXPORT_TIFF)) "tiff")
expected_files <- unlist(lapply(figure_formats, function(ext) c(
  file.path("main_figures", paste0(expected_figures, ".", ext)),
  file.path("supp_figures", paste0(expected_supp_figures, ".", ext)))))
expected_files <- c(expected_files, "study_sensitivity/study_level_route_values.csv")
expected_tables <- c("Table_1_evidence_base_characteristics",
  "Table_2_dependence_reduced_adsorption_outcomes", "Table_3_exploratory_comparisons",
  "Table_4_critical_appraisal_summary", "Table_S1_included_study_characteristics_and_eligibility",
  "Table_S2_database_search_and_exclusion_accounting", "Table_S3_domain_based_critical_appraisal",
  "Table_S4_reporting_completeness", "Table_S6_experimental_conditions_by_precursor_and_metal",
  "Table_S7_sensitivity_and_water_matrix_summaries", "Table_S8_regeneration_observations",
  "Table_S9_source_verification_audit", "Table_S10_study_level_sensitivity",
  "Table_S11A_preparation_and_treatment_classification_catalogue",
  "Table_S11B_adsorption_outcomes_by_preparation_and_treatment_route")
if (!is.null(search_details) && nrow(search_details)) expected_tables <- c(expected_tables,
  "Table_S2B_database_search_strategies")
if (!is.null(exclusion_details) && nrow(exclusion_details)) expected_tables <- c(expected_tables,
  "Table_S2C_study_level_exclusions")
actual_files <- list.files(relevant_output_directory, recursive = TRUE, full.names = TRUE)
nonempty_files <- actual_files[!is.na(file.info(actual_files)$size) & file.info(actual_files)$size > 0L]
output_checks <- bind_rows(
  tibble(item = expected_files,
    passed = file.path(relevant_output_directory, expected_files) %in% nonempty_files),
  tibble(item = paste0(expected_tables, " (CSV values)"),
    passed = paste0(expected_tables, ".csv") %in% basename(nonempty_files)),
  tibble(item = paste0("study_sensitivity/", names(study_sensitivity_exports), ".csv"),
    passed = paste0(names(study_sensitivity_exports), ".csv") %in% basename(nonempty_files)),
  tibble(item = "Table S5 crosswalk",
    passed = any(paste0(crosswalk_stem, c(".csv", ".xlsx")) %in% basename(nonempty_files))))
readr::write_csv(output_checks, file.path(repro_directory, "required_output_checks.csv"))
if (!all(output_checks$passed)) stop("Required outputs are missing or empty: ",
  paste(output_checks$item[!output_checks$passed], collapse = "; "),
  ". Partial outputs retained at ", relevant_output_directory)
writeLines(c(
  "REPRODUCING THIS ANALYSIS (v28_5)",
  paste0("Required inputs: ", basename(input_file), " (", INPUT_ENCODING, ") and ", basename(classification_catalogue_file), " (", CATALOGUE_ENCODING, ")."),
  "S11A contains matched extraction materials from the classification catalogue; S11B contains outcome-by-route summaries.",
  "Catalogue keys must be unique. Unmatched dataset materials and catalogue-only materials are recorded in author_work.",
  "Catalogue differences are recorded without overwriting extraction values. Additional wording is not necessarily a scientific disagreement.",
  "Catalogue agreement does not resolve parallel *_std classification differences; resolve those against sources in the extraction data.",
  "Run from a project folder containing analysis_v28_5.R and files from inputs/.",
  "If using Rscript: Rscript --vanilla analysis_v28_5.R",
  "If using a clean R session: source('analysis_v28_5.R')",
  "If pasting code, set SCRIPT_FILE to a saved copy to archive the exact script.",
  "Requires R >= 4.1; dependencies: tidyverse, scales, patchwork; readxl for Excel input.",
  "Optional: flextable/officer for DOCX, writexl for XLSX, gt for HTML intermediates.",
  "Install dependencies explicitly before running; automatic installation defaults to FALSE.",
  "Use the recorded package_versions.csv and session_info.txt to inspect the execution environment.",
  "For version restoration, create and test an renv environment in the project folder:",
  "install.packages('renv'); renv::init(bare = TRUE)",
  "renv::install(c('tidyverse','scales','patchwork','flextable','officer','writexl','gt','readxl'))",
  "After a successful clean run: renv::snapshot(type = 'all'); submit renv.lock with the code.",
  "Review lockfile contents before sharing. Collaborators use renv::restore() in that project.",
  "A copied renv.lock has not been automatically validated against this run.",
  "The script does not silently install or update packages or fabricate an environment lockfile.",
  "Edit RUN_MODE, input_file and CONFIG near the top; retain the same settings when reproducing results.",
  "RUN_MODE='development' generates files and templates even when author records are incomplete.",
  "RUN_MODE='submission' stops at the end if documentation checks fail, retaining diagnostic files.",
  "Counts, extraction corrections, bibliographic years and judgments require source verification.",
  "screening_counts_source.csv must match prisma_counts_used.csv and add Source_reference per row.",
  "The screening template is in author_work; counts include dataset-derived downstream stages.",
  "Counts that change must be reconciled in the screening configuration and source log.",
  "The appraisal is an adsorption-specific domain framework, not a validated risk-of-bias instrument.",
  "Wilcoxon/Kruskal-Wallis tests remain exploratory and do not model within-study dependence.",
  "Study aggregation and leave-one-study-out analyses are descriptive, not a correction to those tests.",
  "Publication years parsed from IDs are not independently verified bibliographic dates.",
  "pH screens flag potential concerns, not universal precipitation boundaries.",
  "Fresh-session execution and visual review of all released figures/tables remain required.",
  "Matching checksums document file identity, not scientific validity. Do not submit author_work as results.",
  "Input schema lists required columns; retain extraction definitions and units with the dataset."
), file.path(repro_directory, "README_reproducibility.txt"))

# No temporary paths are exposed in the deliverable index.
final_files <- list.files(relevant_output_directory, recursive = TRUE,
                          full.names = FALSE)
readr::write_csv(tibble(file = final_files),
                 file.path(relevant_output_directory, "output_index.csv"))
writeLines(c(
  "RELEVANT OUTPUTS",
  "main_figures: manuscript figures (PNG, plus explicitly configured formats).",
  "main_tables: final main tables (Word, or CSV if Word export is unavailable).",
  "supp_figures: combined models, extreme-value and water-matrix sensitivity.",
  "supp_tables: consolidated supplementary tables, without legacy duplicates.",
  "data: exact analytical units, validated records, crosswalk and verification files.",
  "study_sensitivity: study aggregation and leave-one-study-out results.",
  "notes: R session information.",
  "author_work: incomplete appraisals, audits, input templates and table-selection status; do not submit as final results.",
  "Appraisal templates and unresolved audit items require author verification.",
  "Independent reviewer agreement is present only if source ratings were supplied.",
  "Existing outputs from previous scripts are not deleted or modified.",
  "Each run creates a fresh folder to prevent stale outputs being retained.",
  "reproducibility: exact inputs, package versions, settings, checksums and documentation checks.",
  "CSV values accompany Word tables to support independent reanalysis.",
  "Passing file checks does not establish scientific or journal submission readiness."
), file.path(relevant_output_directory, "README.txt"))

# Remove only the temporary export directory created by this run, after copies
# have succeeded. Never delete previous user output directories.
if (startsWith(normalizePath(output_directory, winslash = "/"),
               normalizePath(tempdir(), winslash = "/"))) {
  unlink(output_directory, recursive = TRUE)
}
output_directory <- relevant_output_directory
message("Relevant deliverables saved to: ", normalizePath(output_directory))

# File identity manifest excludes itself and is created after all other exports.
checksum_files <- sort(list.files(relevant_output_directory, recursive = TRUE, full.names = TRUE))
readr::write_csv(tibble(
  file = substring(checksum_files, nchar(relevant_output_directory) + 2L),
  bytes = unname(file.info(checksum_files)$size),
  md5 = unname(tools::md5sum(checksum_files))),
  file.path(relevant_output_directory, "output_checksums.csv"))
if (RUN_MODE == "submission" && !all(documentation_checks$passed)) {
  stop("Submission documentation checks failed: ",
    paste(documentation_checks$check[!documentation_checks$passed], collapse = "; "),
    ". Outputs retained at ", normalizePath(relevant_output_directory), call. = FALSE)
}
message("Required output checks passed. Documentation checks: ",
  sum(documentation_checks$passed), "/", nrow(documentation_checks),
  ". Author scientific verification and visual review remain required.")
