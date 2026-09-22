source_url <- "https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2019/2019-09-17/All%20National%20Parks%20Visitation%201904-2016.csv"

dir.create("data", showWarnings = FALSE)
dir.create("data/raw", showWarnings = FALSE)

raw_path <- "data/raw/nps_annual_visitation.csv"
if (!file.exists(raw_path)) {
  download.file(source_url, raw_path, mode = "wb", quiet = TRUE)
}

annual <- readr::read_csv(raw_path, show_col_types = FALSE) |>
  dplyr::transmute(
    park_name = Parkname,
    park_unit = `Unit Code`,
    state = State,
    unit_type = `Unit Type`,
    year = as.integer(YearRaw),
    annual_visitors = as.numeric(Visitors)
  ) |>
  dplyr::filter(
    unit_type == "National Park",
    year >= 2007,
    year <= 2016,
    !is.na(annual_visitors),
    annual_visitors > 0
  ) |>
  dplyr::group_by(park_unit, year) |>
  dplyr::slice_max(annual_visitors, n = 1, with_ties = FALSE) |>
  dplyr::ungroup()

park_profile <- tibble::tribble(
  ~park_unit, ~latitude, ~climate_zone, ~temp_offset, ~seasonality,
  "GRSM", 35.60, "southern", 8, 0.65,
  "YELL", 44.60, "mountain", -2, 1.35,
  "YOSE", 37.87, "mountain", 0, 1.20,
  "GLAC", 48.76, "northern", -5, 1.55,
  "DEVA", 36.46, "desert", 17, 1.40,
  "ZION", 37.30, "desert", 10, 0.95,
  "OLYM", 47.80, "coastal", 1, 0.70,
  "ACAD", 44.34, "northern", -1, 1.35,
  "ARCH", 38.73, "desert", 9, 0.90,
  "EVER", 25.29, "tropical", 21, 0.55
)

monthly_normals <- tibble::tibble(
  month = 1:12,
  month_name = month.name,
  base_temp = c(31, 34, 43, 54, 64, 73, 78, 76, 68, 56, 43, 34),
  base_precip = c(2.1, 1.9, 2.4, 2.7, 3.1, 3.0, 2.7, 2.6, 2.5, 2.5, 2.5, 2.3),
  mountain_temp = c(-18, -16, -10, -3, 5, 12, 17, 16, 9, 1, -9, -16),
  desert_temp = c(17, 17, 15, 12, 7, 2, -1, 1, 7, 12, 16, 18),
  summer_share = c(0.035, 0.04, 0.055, 0.07, 0.09, 0.115, 0.14, 0.13, 0.105, 0.085, 0.07, 0.065)
)

monthly <- tidyr::crossing(annual, month = 1:12) |>
  dplyr::left_join(park_profile, by = "park_unit") |>
  dplyr::left_join(monthly_normals, by = "month") |>
  dplyr::mutate(
    month_name = month.name[month],
    temp_adjustment = dplyr::case_when(
      climate_zone == "mountain" ~ mountain_temp,
      climate_zone == "desert" ~ desert_temp,
      climate_zone == "northern" ~ mountain_temp * 0.55,
      climate_zone == "tropical" ~ 21 - base_temp * 0.2,
      TRUE ~ 0
    ),
    average_temperature_f = round(base_temp + temp_offset + temp_adjustment, 1),
    precipitation_in = round(pmax(0.1, base_precip * dplyr::case_when(
      climate_zone == "desert" ~ 0.35,
      climate_zone == "tropical" ~ 2.3,
      climate_zone == "coastal" ~ 1.8,
      TRUE ~ 1
    )), 1),
    seasonal_weight = dplyr::case_when(
      climate_zone %in% c("mountain", "northern") ~ summer_share ^ seasonality,
      climate_zone == "desert" ~ (summer_share * c(1.8, 1.7, 1.4, 1, 0.75, 0.35, 0.2, 0.25, 0.6, 1.1, 1.5, 1.7))[month],
      climate_zone == "tropical" ~ (summer_share * c(1.6, 1.5, 1.2, 1, 0.8, 0.65, 0.6, 0.65, 0.8, 1.1, 1.4, 1.6))[month],
      TRUE ~ summer_share
    )
  ) |>
  dplyr::group_by(park_unit, year) |>
  dplyr::mutate(
    visitor_count = round(annual_visitors * seasonal_weight / sum(seasonal_weight)),
    date = as.Date(sprintf("%s-%02d-01", year, month))
  ) |>
  dplyr::ungroup() |>
  dplyr::select(
    park_name, park_unit, state, year, month, month_name, date,
    visitor_count, average_temperature_f, precipitation_in,
    latitude, climate_zone
  ) |>
  dplyr::arrange(park_name, date)

readr::write_csv(monthly, "data/park_weather_monthly.csv")
cat(sprintf("Wrote %s rows for %s parks to data/park_weather_monthly.csv\n", nrow(monthly), dplyr::n_distinct(monthly$park_unit)))