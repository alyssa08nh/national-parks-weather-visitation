# National Parks Weather & Visitation

A Quarto data story about how season and weather shape visitation at US national parks.

## Run locally

```bash
Rscript scripts/prepare_data.R
quarto preview
```

The site has three views:

- **Field Notes**: a network-wide scatter plot of monthly visitors and temperature.
- **Exploration**: park dropdowns, Plotly zoom controls, and monthly visitor/weather charts.
- **Story**: a guided comparison of northern and desert park seasons.

## Data

The annual visitor totals are from the National Park Service Stats archive, downloaded through the public TidyTuesday mirror of the 1904–2016 NPS export. The preparation script keeps 2007–2016 observations for units classified as National Parks.

The source archive is annual, so `scripts/prepare_data.R` allocates annual totals across months using park-specific seasonal profiles. Temperatures and precipitation are regional climate-profile estimates intended for exploration and teaching; they are not event-level NOAA station observations. The limitation is stated in the site so the visual story is not mistaken for a causal weather study.

## Publish

After committing and pushing the project to GitHub, publish the rendered site with:

```bash
quarto publish gh-pages
```

The repository is configured with the descriptive name `national-parks-weather-visitation`.