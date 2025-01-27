
TODO: - Document `add_meta_tags()` - Document default
`write_panels(..., force = FALSE)`

<!-- README.md is generated from README.Rmd. Please edit that file -->

# trelliscope

<!-- badges: start -->

[![R-CMD-check](https://github.com/trelliscope/trelliscope/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/trelliscope/trelliscope/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/trelliscope/trelliscope/branch/main/graph/badge.svg)](https://app.codecov.io/gh/trelliscope/trelliscope?branch=main)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

This repository contains an rewrite of the trelliscopejs R package, now
simply called trelliscope.

## Installation

You can install the development version of trelliscope from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
# load_all()
devtools::install_github("trelliscope/trelliscope")
```

## Overview

Trelliscope provides a simple mechanism to make a collection of
visualizations and display them as interactive [small
multiples](https://en.wikipedia.org/wiki/Small_multiple). This is a
useful general visualization technique for many scenarios, particularly
when looking at a somewhat large dataset comprised of many natural
subsets.

The Trelliscope R package provides utilities to create the
visualizations, specify metadata about the visualizations that can be
used to interactively navigate them, and specify other aspects of how
the visualization viewer should behave. These specifications are given
to a Trelliscope viewer written in JavaScript.

### Data frames of visualizations

The basic principle behind the design of the R package is that you
specify a collection of visualizations as a data frame, with one column
representing the plot (either as a plot object such as ggplot or as a
reference to an image such as a png, svg, or even html file), and the
other columns representing metadata about each visualization.

This package provides utilities to help build these data frames and then
explore them in an interactive viewer.

### Example

As a simple example, let’s consider the `gapminder` dataset that comes
with the `gapminder` package.

``` r
# install.packages("gapminder")
library(gapminder)

gapminder
#> # A tibble: 1,704 × 6
#>    country     continent  year lifeExp      pop gdpPercap
#>    <fct>       <fct>     <int>   <dbl>    <int>     <dbl>
#>  1 Afghanistan Asia       1952    28.8  8425333      779.
#>  2 Afghanistan Asia       1957    30.3  9240934      821.
#>  3 Afghanistan Asia       1962    32.0 10267083      853.
#>  4 Afghanistan Asia       1967    34.0 11537966      836.
#>  5 Afghanistan Asia       1972    36.1 13079460      740.
#>  6 Afghanistan Asia       1977    38.4 14880372      786.
#>  7 Afghanistan Asia       1982    39.9 12881816      978.
#>  8 Afghanistan Asia       1987    40.8 13867957      852.
#>  9 Afghanistan Asia       1992    41.7 16317921      649.
#> 10 Afghanistan Asia       1997    41.8 22227415      635.
#> # … with 1,694 more rows
```

This data provides statistics such as life expectancy annually for 142
countries.

Suppose we want to visualize life expectancy vs. year for each country.
One way to do this is to create a data frame with one row per country,
with one of the columns of the data frame containing a plot.

``` r
library(trelliscope)
suppressPackageStartupMessages(
  library(tidyverse, warn.conflicts = FALSE) # for ggplot2, tidyr, dplyr, purrr
)

visdf <- gapminder %>%
  tidyr::nest(data = !dplyr::one_of(c("continent", "country"))) %>%
  dplyr::mutate(
    mean_lifeexp = purrr::map_dbl(data, ~ mean(.x$lifeExp)),
    panel = trelliscope::map_plot(data,
      ~ (ggplot2::ggplot(ggplot2::aes(year, lifeExp), data = .x)) +
        ggplot2::geom_point())
  )
visdf
#> # A tibble: 142 × 5
#>    country     continent data              mean_lifeexp panel     
#>    <fct>       <fct>     <list>                   <dbl> <nstd_pnl>
#>  1 Afghanistan Asia      <tibble [12 × 4]>         37.5 <gg>      
#>  2 Albania     Europe    <tibble [12 × 4]>         68.4 <gg>      
#>  3 Algeria     Africa    <tibble [12 × 4]>         59.0 <gg>      
#>  4 Angola      Africa    <tibble [12 × 4]>         37.9 <gg>      
#>  5 Argentina   Americas  <tibble [12 × 4]>         69.1 <gg>      
#>  6 Australia   Oceania   <tibble [12 × 4]>         74.7 <gg>      
#>  7 Austria     Europe    <tibble [12 × 4]>         73.1 <gg>      
#>  8 Bahrain     Asia      <tibble [12 × 4]>         65.6 <gg>      
#>  9 Bangladesh  Asia      <tibble [12 × 4]>         49.8 <gg>      
#> 10 Belgium     Europe    <tibble [12 × 4]>         73.6 <gg>      
#> # … with 132 more rows
```

Here we have built a data frame of visualizations, the basic construct
that is needed to create a Trelliscope display. We have a data frame
with 142 rows, one for each country. We have country metadata such as
the country and continent names, as well as the mean life expectency,
and then we have a column “panel” that contains a plot for each country
of life expectancy vs. year. (Note: We show the `package::` prefixes for
each function used in this example to highlight what packages are being
used but will remove these from future examples).

There is a lot going on in the code example above that should be
familiar if you have experience with Tidyverse packages such as dplyr
and tidyr. A great resource for this can be found in [“R for Data
Science”](https://r4ds.had.co.nz/index.html), particularly [this
chapter](https://r4ds.had.co.nz/many-models.html) which mimics many of
the ideas here of nesting and list columns with the same dataset.

The one non-tidyverse function used in this example is `map_plot()`.
This acts as an analog to `map` functions in the purrr package such as
`map_dbl()`, etc., that applies a function to every element in a list
and returns a list-column that indicates that it contains plots that can
be used in a Trelliscope display.

Note that although the tidyverse provides many helpful functions, it
does not matter what package or approach you use as long as you can get
your data into the form of a data frame with one row per visualization
and a visualiztion column created with `map_plot()`.

### Turning a data frame into an interactive visualization

Once you have data in this form, you can create a Trelliscope display by
simply doing the following:

``` r
as_trelliscope_df(visdf, name = "life expectancy") %>% write_trelliscope()
```

Passing the data frame to `as_trelliscope_df()` creates a trelliscope
data frame that provides information about the display that will be
created from the data frame, such the name of the display and an
optional description and tags, as well as the directory where the dispay
will be written (if not specified it is placed in a temporary
directory). Then `write_trelliscope()` writes out and shows the display
using the Trelliscope JavaScript viewer app.

\[screenshot (TODO)\]

Now from the app you can interatively view all 142 of the
visualizations, with controls to specify what order they should appear
in, how many to view at once, and filter to only visualizations of
interest (e.g. countries in Africa with an average life expectancy of
less than 50 years).

From this you can see how it can be useful to provide as much metadata
about each visualization as might be useful for a meaningful interactive
experience, especially when the number of visualizations is much larger.
For example, we could add metrics for the latest life expectancy, the
slope of the trend of life expectancy over time, the country’s
population, etc. that could help us navigate to interesting
visualizations in the display.

There are many functions provided that operate on the object that comes
out of `as_trelliscope_df()` that allow us to specify more information
about the display and its behavior before we write it out with
`write_trelliscope()`. We will discuss several of these later.

### Conveniently creating visualization data frames from ggplot2

A utility function, `facet_panels()` makes it easier to achieve the same
result as what we showed in the previous example staying strictly within
ggplot and not needing to rely on the other tidyverse functions to nest
the data, etc.

The `facet_panels()` function works in a very similar manner as
ggplot2’s `facet_wrap()`, in that we are specifying that we want the
same visualization specification to be applied to each facet of the data
that we specify.

For example, using ggplot2, we might do the following to visualize each
country separately:

``` r
ggplot(aes(year, lifeExp), data = gapminder) +
  geom_point() +
  facet_wrap(~ continent + country)
```

This will plot life expectancy vs. year for each of the 142 countries
and lay the plots out in a page.

With Trelliscope, we can swap out `facet_wrap()` with `facet_panels()`:

``` r
p <- ggplot(aes(year, lifeExp), data = gapminder) +
  geom_point() +
  facet_panels(~ continent + country)
```

This creates a ggplot object that we can turn into a data frame suitable
for Trelliscope with the following:

``` r
visdf <- nest_panels(p)
visdf
#> # A tibble: 142 × 4
#>    country     continent data              panel     
#>    <fct>       <fct>     <list>            <nstd_pnl>
#>  1 Afghanistan Asia      <tibble [12 × 5]> <gg>      
#>  2 Albania     Europe    <tibble [12 × 5]> <gg>      
#>  3 Algeria     Africa    <tibble [12 × 5]> <gg>      
#>  4 Angola      Africa    <tibble [12 × 5]> <gg>      
#>  5 Argentina   Americas  <tibble [12 × 5]> <gg>      
#>  6 Australia   Oceania   <tibble [12 × 5]> <gg>      
#>  7 Austria     Europe    <tibble [12 × 5]> <gg>      
#>  8 Bahrain     Asia      <tibble [12 × 5]> <gg>      
#>  9 Bangladesh  Asia      <tibble [12 × 5]> <gg>      
#> 10 Belgium     Europe    <tibble [12 × 5]> <gg>      
#> # … with 132 more rows
```

This builds a data frame similar to what we produced in the first
example, which we can modify in any way we would like to add more
per-country metadata (e.g. calculate mean life expectancy, merge other
demographic statistics, etc.) and then pass this to
`as_trelliscope_df()` to create our data frame of visualizations. Note
that we can pass `p` directly to `as_trelliscope_df()` as well in which
case it will build the panels for us, but it can be useful to have more
control over additional modifications to the data frame and the panel
building.

The `nest_panels()` function has a few arguments that allow us to
specify more about how we want the panels built. One is `as_plotly`
which we can set to `TRUE` to have the plots converted to interactive
plotly plots:

``` r
visdf <- nest_panels(p, as_plotly = TRUE)
visdf
#> # A tibble: 142 × 4
#>    country     continent data              panel     
#>    <fct>       <fct>     <list>            <nstd_pnl>
#>  1 Afghanistan Asia      <tibble [12 × 5]> <plotly>  
#>  2 Albania     Europe    <tibble [12 × 5]> <plotly>  
#>  3 Algeria     Africa    <tibble [12 × 5]> <plotly>  
#>  4 Angola      Africa    <tibble [12 × 5]> <plotly>  
#>  5 Argentina   Americas  <tibble [12 × 5]> <plotly>  
#>  6 Australia   Oceania   <tibble [12 × 5]> <plotly>  
#>  7 Austria     Europe    <tibble [12 × 5]> <plotly>  
#>  8 Bahrain     Asia      <tibble [12 × 5]> <plotly>  
#>  9 Bangladesh  Asia      <tibble [12 × 5]> <plotly>  
#> 10 Belgium     Europe    <tibble [12 × 5]> <plotly>  
#> # … with 132 more rows
```

If you are plotting with ggplot2, there are several benefits to using
`facet_panels()`. First, it fits more naturally into the ggplot2
paradigm, where you can build a Trelliscope visualization exactly as you
would with building a ggplot2 visualization. Second, you can make use of
the `scales` argument in `facet_panels()` (which behaves similarly to
the same argument in `facet_wrap()`) to ensure that the x and y axis
ranges of your plots behave the way you want. The default is for all
plots to have the same `"fixed"` axis ranges. This is an important
consideration in visualizing small multiples because if you are making
visual comparisons you often want to be comparing things on the same
scale. In the first example where we didn’t use `facet_trellicope()`, we
would have had to manually figure out the ranges of the x and y axes and
hard code them into our plots.

### Finer control

So far we have seen the following general set of steps to create a
trelliscope display:

Starting with a data frame of raw data, `df`, we can create a data frame
of visualizations using tidyverse functions:

``` r
df %>%
  nest(...) %>%
  mutate(
    panel = map_plot(...),
    ...
  ) %>%
  as_trelliscope_df(...) %>%
  write_trelliscope(...)
```

or using `facet_panels()`:

``` r
df %>%
  (ggplot(...) + ... + facet_panels()) %>%
  nest_panels() %>%
  as_trelliscope_df() %>%
  write_trelliscope()
```

In between `as_trelliscope_df() %>% write_trelliscope()`, there are many
functions we can call that give us better control over how our display
looks and behaves. These include the following:

-   `write_panels()`: allows finer control over how panels are written
    (e.g. plot dimensions, file format, etc.)
-   `add_meta_defs()`: specify metadata variable definitions (e.g. plain
    text variable descriptions, types, tags)
-   `add_meta_labels()`: as an alternative to fully specifying metadata
    variable definitions, this is a convenience function to only supply
    labels for all of the variables
-   `set_default_labels()`, `set_default_layout()`,
    `set_default_sort()`, `set_default_filters()`: specify the initial
    state of the display
-   `add_view()`: add any number of pre-defined “views” that navigate
    the user to specified states of the display
-   `add_inputs()`: specify inputs that can collect user feedback for
    each panel in the display

Each of these functions takes a trelliscope data frame (created with
`as_trelliscope_df()`) and returns a modified trelliscope data frame,
making them suitable for chaining.

To illustrate some of these, let’s create a trelliscope data frame:

``` r
x <- (ggplot(aes(year, lifeExp), data = gapminder) +
  geom_point() +
  facet_panels(~ continent + country)) %>%
  nest_panels() %>%
  mutate(
    mean_lifeexp = purrr::map_dbl(data, ~ mean(.x$lifeExp)),
    min_lifeexp = purrr::map_dbl(data, ~ min(.x$lifeExp)),
    mean_gdp = purrr::map_dbl(data, ~ mean(.x$gdpPercap)),
    wiki_link = paste0("https://en.wikipedia.org/wiki/", country)
  ) %>%
  as_trelliscope_df(name = "life expectancy")

x
#> ℹ Trelliscope data frame. Call show_info() for more information
#> # A tibble: 142 × 8
#>    country     continent data              panel mean_…¹ min_l…² mean_…³ wiki_…⁴
#>    <fct>       <fct>     <list>            <nst>   <dbl>   <dbl>   <dbl> <chr>  
#>  1 Afghanistan Asia      <tibble [12 × 5]> <gg>     37.5    28.8    803. https:…
#>  2 Albania     Europe    <tibble [12 × 5]> <gg>     68.4    55.2   3255. https:…
#>  3 Algeria     Africa    <tibble [12 × 5]> <gg>     59.0    43.1   4426. https:…
#>  4 Angola      Africa    <tibble [12 × 5]> <gg>     37.9    30.0   3607. https:…
#>  5 Argentina   Americas  <tibble [12 × 5]> <gg>     69.1    62.5   8956. https:…
#>  6 Australia   Oceania   <tibble [12 × 5]> <gg>     74.7    69.1  19981. https:…
#>  7 Austria     Europe    <tibble [12 × 5]> <gg>     73.1    66.8  20412. https:…
#>  8 Bahrain     Asia      <tibble [12 × 5]> <gg>     65.6    50.9  18078. https:…
#>  9 Bangladesh  Asia      <tibble [12 × 5]> <gg>     49.8    37.5    818. https:…
#> 10 Belgium     Europe    <tibble [12 × 5]> <gg>     73.6    68    19901. https:…
#> # … with 132 more rows, and abbreviated variable names ¹​mean_lifeexp,
#> #   ²​min_lifeexp, ³​mean_gdp, ⁴​wiki_link
```

As you can see, `x` is still a data frame. To see more information about
trelliscope-specific settings, you can use `show_info()`:

``` r
show_info(x)
#> A trelliscope display
#> • Name: "life expectancy"
#> • Description: "life expectancy"
#> • Tags: none
#> • Key columns: "continent" and "country"
#> • Path:
#>   "/var/folders/7b/thg__1xx7w98wc4rs8t3djrw0000gn/T//RtmpIdyzPk/file17b1a51b472aa"
#> • Number of panels: 142
#> • Panels written: no
#> • Metadata variables that will be inferred:
#>     ───────────────────────────────────
#>     name         `inferred type` label 
#>     ───────────────────────────────────
#>     country      factor          [none]
#>     continent    factor          [none]
#>     mean_lifeexp number          [none]
#>     min_lifeexp  number          [none]
#>     mean_gdp     number          [none]
#>     wiki_link    string          [none]
#>     ───────────────────────────────────
#> • Variables that will be ignored as metadata: "data" and "panel"
```

<!-- #### `write_panels()`

The optional chain function `write_panels()` can be used to have finer control over how panels get written to disk. It also can give the advantage of making panel writing a separate step so that it does not need to be repeated every time a display might be modified.

The main arguments are `width`, `height`, and `format`. The `width` and `height` are specified in pixels, and are mainly to provide information about the plot's aspect ratio and size of text and glyphs. The actual dimensions of the plot as shown in the viewer will vary (the aspect ratio remains fixed) depending on how many plots are shown at once.

The file format can be either `png` or `svg`. This is ignored if the plot column of the data frame is an htmlwidget such as a ggplotly plot.

disp <- disp %>%
  write_panels(width = 800, height = 500, format = "svg")

Once the panels are written, a note is made in the `disp` object so that it knows it doesn't have to be done with writing out the display. -->

#### `add_meta_defs()`

Each metadata variable can have addtional attributes specified about it
that enhance the user’s experience when viewing the display. The main
attribute is the metadata variable label. Without supplying a label,
variables will appear in the viewer by their variable names
(e.g. `mean_gdp` vs. a label such as
`Mean of yearly GDP per capita (US$, inflation-adjusted)`).

Additionally, we can specify the variable type, specify tags
(e.g. “demographics”, “geography”, etc.) that can make variables easier
to navigate in the viewer when there are many of them, and other
type-specific parameters.

Each metadata variable can be specified by using a helper function that
specifies its type. Each of these has the arguments `varname`, `label`,
and `tags` (denoted below with `...`) and any additional arguments which
are eitehr self-explanatory or can be further studied by looking at the
function help files.

-   `meta_string(...)`: indicates the variable is a string
-   `meta_factor(..., levels)`: indicates the variable is a fator - the
    difference between this and a string is that the provided `levels`
    are used to determine the sorting order, etc. as opposed to
    alphabetically with strings
-   `meta_number(..., digits, locale)`: indicates a numeric variable
-   `meta_currency(..., code)`: indicates a currency variable -
    essentially the same as a number but will be displayed differently
    in the app
-   `meta_date(...)`: indicates a date variable
-   `meta_datetime(...)`: indicates a datetime variable
-   `meta_href(...)`: indicates a variable that contains a hyperlink to
    another web source - it will be rendered as a hyperlink
-   `meta_geo(..., latvar, longvar)`: indicates geographic coordinates
    (currently not supported)
-   `meta_graph(..., idvarname, direction)`: indicates network graph
    relationships between variables (currently not supported)

We can provide these specifications by calling `add_meta_defs()` on our
trelliscope data frame. This function takes as arguments any number of
`meta_*()` function calls. For example, let’s build up our object to
include some of these metadata variable specifications:

``` r
x <- x %>%
  add_meta_defs(
    meta_number("mean_gdp",
      label = "Mean of annual GDP per capita (US$, inflation-adjusted)",
      digits = 2),
    meta_href("wiki_link", label = "Wikipedia country page")
  )

x
#> ℹ Trelliscope data frame. Call show_info() for more information
#> # A tibble: 142 × 8
#>    country     continent data              panel mean_…¹ min_l…² mean_…³ wiki_…⁴
#>    <fct>       <fct>     <list>            <nst>   <dbl>   <dbl>   <dbl> <chr>  
#>  1 Afghanistan Asia      <tibble [12 × 5]> <gg>     37.5    28.8    803. https:…
#>  2 Albania     Europe    <tibble [12 × 5]> <gg>     68.4    55.2   3255. https:…
#>  3 Algeria     Africa    <tibble [12 × 5]> <gg>     59.0    43.1   4426. https:…
#>  4 Angola      Africa    <tibble [12 × 5]> <gg>     37.9    30.0   3607. https:…
#>  5 Argentina   Americas  <tibble [12 × 5]> <gg>     69.1    62.5   8956. https:…
#>  6 Australia   Oceania   <tibble [12 × 5]> <gg>     74.7    69.1  19981. https:…
#>  7 Austria     Europe    <tibble [12 × 5]> <gg>     73.1    66.8  20412. https:…
#>  8 Bahrain     Asia      <tibble [12 × 5]> <gg>     65.6    50.9  18078. https:…
#>  9 Bangladesh  Asia      <tibble [12 × 5]> <gg>     49.8    37.5    818. https:…
#> 10 Belgium     Europe    <tibble [12 × 5]> <gg>     73.6    68    19901. https:…
#> # … with 132 more rows, and abbreviated variable names ¹​mean_lifeexp,
#> #   ²​min_lifeexp, ³​mean_gdp, ⁴​wiki_link
```

If metadata variable definitions are not provided (such as here where we
don’t provide explicit definitions for `country`, `continent`,
`min_lifeexp`, and `mean_lifeexp`), they are inferred at the time the
display is written. The inference usually works pretty well but it
cannot infer labels and is not able to detect things like currencies.

#### `add_meta_labels()`

Often the metadata inference works well enough that we might just want
to provide labels for our metadata variables and skip the more formal
metadata variable definition. We can do this with `add_meta_labels()`.
This function simply takes a named set of parameters as input, with the
names indicating the variable name and the values indicating the labels.
For example:

``` r
x <- x %>%
  add_meta_labels(
    mean_lifeexp = "Mean of annual life expectancies",
    min_lifeexp = "Lowest observed annual life expectancy"
  )

x
#> ℹ Trelliscope data frame. Call show_info() for more information
#> # A tibble: 142 × 8
#>    country     continent data              panel mean_…¹ min_l…² mean_…³ wiki_…⁴
#>    <fct>       <fct>     <list>            <nst>   <dbl>   <dbl>   <dbl> <chr>  
#>  1 Afghanistan Asia      <tibble [12 × 5]> <gg>     37.5    28.8    803. https:…
#>  2 Albania     Europe    <tibble [12 × 5]> <gg>     68.4    55.2   3255. https:…
#>  3 Algeria     Africa    <tibble [12 × 5]> <gg>     59.0    43.1   4426. https:…
#>  4 Angola      Africa    <tibble [12 × 5]> <gg>     37.9    30.0   3607. https:…
#>  5 Argentina   Americas  <tibble [12 × 5]> <gg>     69.1    62.5   8956. https:…
#>  6 Australia   Oceania   <tibble [12 × 5]> <gg>     74.7    69.1  19981. https:…
#>  7 Austria     Europe    <tibble [12 × 5]> <gg>     73.1    66.8  20412. https:…
#>  8 Bahrain     Asia      <tibble [12 × 5]> <gg>     65.6    50.9  18078. https:…
#>  9 Bangladesh  Asia      <tibble [12 × 5]> <gg>     49.8    37.5    818. https:…
#> 10 Belgium     Europe    <tibble [12 × 5]> <gg>     73.6    68    19901. https:…
#> # … with 132 more rows, and abbreviated variable names ¹​mean_lifeexp,
#> #   ²​min_lifeexp, ³​mean_gdp, ⁴​wiki_link
```

We still haven’t specified labels for `country` and `continent`. If
labels are not provided, they will be set to the variable name. In the
case of these two varibles, the variable name is clear enough to not
need to specify the labels.

#### `set_default_labels()`

By default, the “key columns” will be shown as labels. If we’d like to
change what labels are shown when the display is opened, we can use
`set_default_labels()`, e.g.:

``` r
x <- x %>%
  set_default_labels(c("country", "continent", "wiki_link"))
```

#### `set_default_layout()`

We can also set the default panel layout:

``` r
x <- x %>%
  set_default_layout(nrow = 3, ncol = 5)
```

#### `set_default_sort()`

We can set the default sort order with `set_default_sort()`:

``` r
x <- x %>%
  set_default_sort(c("continent", "mean_lifeexp"), dir = c("asc", "desc"))
```

#### `set_default_filters()`

We can set the default filter state with `set_default_filters()`.
Currently there are two different kinds of filters:

-   `filter_range(varname, min = ..., max = ...)`: works with numeric,
    date, or datetime variables
-   `filter_string(varname, values = ...)`: works with factor or string
    variables

``` r
x <- x %>%
  set_default_filters(
    filter_string("continent", values = "Africa"),
    filter_range("mean_lifeexp", max = 50)
  )
```

More types of filters are planned.

#### `add_view()`

Views are predefined sets of state that are made available in the viewer
to help the user get to regions of the display that are interesting in
different ways. You can add a view chaining the display through the
`add_view()` function.

`add_view()` takes a `name` as its first argument, and then any number
of state specifications. The functions available to set the state are
the following:

-   `state_layout()`
-   `state_labels()`
-   `state_sort()`
-   `filter_string()`
-   `filter_range()`

The `state_*()` functions have the same parameters as and behave
similarly to their `set_*()` counterparts except that unlike those,
these do not recieve a trelliscope data frame and return a trelliscope
data frame, but instead just specify a state. The `filter_*()` functions
we have seen already.

For example, suppose we wish to add a view that only shows countries
with minimum life expectancy greater than or equal to 60, sorted from
highest to lowest minimum life expectancy:

``` r
x <- x %>%
  add_view(
    name = "Countries with high life expectancy (min >= 60)",
    filter_range("min_lifeexp", min = 60),
    state_sort("min_lifeexp", dir = "desc")
  )
```

You can add as many views as you would like by chaining more calls to
`add_view()`.

#### `add_inputs()`

You can add user inputs that are attached to each panel of the display
using the `add_inputs()` function. This function takes any number of
arguments created by any of the following functions:

-   `input_radio(name, label, options)`
-   `input_checkbox(name, label, options)`
-   `input_select(name, label, options)`
-   `input_multiselect(name, label, options)`
-   `input_text(name, label, width, height)`
-   `input_number(name, label)`

These specify different input types.

For example, if we want a free text input for comments as well as yes/no
question asking if the data looks correct for the panel, we can do the
following:

``` r
x <- x %>%
  add_inputs(
    input_text(name = "comments", label = "Comments about this panel",
      width = 100, height = 6),
    input_radio(name = "looks_correct",
      label = "Does the data look correct?", options = c("no", "yes"))
  ) %>%
  add_input_email("johndoe123@fakemail.net")
```

Let’s see how all of these operations are reflected in our trelliscope
data frame:

``` r
show_info(x)
#> A trelliscope display
#> • Name: "life expectancy"
#> • Description: "life expectancy"
#> • Tags: none
#> • Key columns: "continent" and "country"
#> • Path:
#>   "/var/folders/7b/thg__1xx7w98wc4rs8t3djrw0000gn/T//RtmpIdyzPk/file17b1a51b472aa"
#> • Number of panels: 142
#> • Panels written: no
#> • Defined metadata variables:
#>     ─────────────────────────────────────────────────
#>     name      type   label                      tags 
#>     ─────────────────────────────────────────────────
#>     mean_gdp  number Mean of annual GDP per ca… []   
#>     wiki_link href   Wikipedia country page     []   
#>     ─────────────────────────────────────────────────
#> • Metadata variables that will be inferred:
#>     ───────────────────────────────────────────────────────────────────
#>     name         `inferred type` label                                 
#>     ───────────────────────────────────────────────────────────────────
#>     country      factor          [none]                                
#>     continent    factor          [none]                                
#>     mean_lifeexp number          Mean of annual life expectancies      
#>     min_lifeexp  number          Lowest observed annual life expectancy
#>     ───────────────────────────────────────────────────────────────────
#> • Variables that will be ignored as metadata: "data" and "panel"
```

#### Output

Now that we have built up our trelliscope data frame, we can write it
out as specified before with `write_trelliscope()`.

``` r
write_trelliscope(x)
#> Writing panels ■                                  1% | ETA:  2m
#> Writing panels ■■■■■                             15% | ETA: 18s
#> Writing panels ■■■■■■■■■■■■■■■                   46% | ETA:  7s
#> Writing panels ■■■■■■■■■■■■■■■■■■■■■■■■          77% | ETA:  3s
#> Writing panels ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  100% | ETA:  0s
#> ℹ Meta definitions inferred for variables "country", "continent",
#>   "mean_lifeexp", and "min_lifeexp"
#> ℹ No default "layout" state supplied for view 'Countries with high life
#>   expectancy (min >= 60)'. Using nrow=2, ncol=3.
#> ℹ No default "labels" state supplied for view 'Countries with high life
#>   expectancy (min >= 60)'. Using continent, country.
#> ℹ Trelliscope written to
#>   /var/folders/7b/thg__1xx7w98wc4rs8t3djrw0000gn/T//RtmpIdyzPk/file17b1a51b472aa/index.html
#>   Open this file or call view_trelliscope() to view.
```

list.files(disp\$path)

This writes the panels if they haven’t been written yet, and then writes
out a JSON representation of all of the other specifications we have
made for the app to consume.

To see what the JSON representation of this looks like for the display
we have been building:

``` r
x %>% as_json()
#> ℹ Meta definitions inferred for variables "country", "continent",
#>   "mean_lifeexp", and "min_lifeexp"
#> ℹ No default "layout" state supplied for view 'Countries with high life
#>   expectancy (min >= 60)'. Using nrow=2, ncol=3.
#> ℹ No default "labels" state supplied for view 'Countries with high life
#>   expectancy (min >= 60)'. Using continent, country.
#> {
#>   "name": "life expectancy",
#>   "description": "life expectancy",
#>   "tags": [],
#>   "keycols": ["continent", "country"],
#>   "keysig": null,
#>   "metas": [
#>     {
#>       "locale": true,
#>       "digits": 2,
#>       "sortable": true,
#>       "filterable": true,
#>       "tags": [],
#>       "label": "Mean of annual GDP per capita (US$, inflation-adjusted)",
#>       "type": "number",
#>       "varname": "mean_gdp"
#>     },
#>     {
#>       "sortable": false,
#>       "filterable": false,
#>       "tags": [],
#>       "label": "Wikipedia country page",
#>       "type": "href",
#>       "varname": "wiki_link"
#>     },
#>     {
#>       "levels": ["Afghanistan", "Albania", "Algeria", "Angola", "Argentina", "Australia", "Austria", "Bahrain", "Bangladesh", "Belgium", "Benin", "Bolivia", "Bosnia and Herzegovina", "Botswana", "Brazil", "Bulgaria", "Burkina Faso", "Burundi", "Cambodia", "Cameroon", "Canada", "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros", "Congo, Dem. Rep.", "Congo, Rep.", "Costa Rica", "Cote d'Ivoire", "Croatia", "Cuba", "Czech Republic", "Denmark", "Djibouti", "Dominican Republic", "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Ethiopia", "Finland", "France", "Gabon", "Gambia", "Germany", "Ghana", "Greece", "Guatemala", "Guinea", "Guinea-Bissau", "Haiti", "Honduras", "Hong Kong, China", "Hungary", "Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy", "Jamaica", "Japan", "Jordan", "Kenya", "Korea, Dem. Rep.", "Korea, Rep.", "Kuwait", "Lebanon", "Lesotho", "Liberia", "Libya", "Madagascar", "Malawi", "Malaysia", "Mali", "Mauritania", "Mauritius", "Mexico", "Mongolia", "Montenegro", "Morocco", "Mozambique", "Myanmar", "Namibia", "Nepal", "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "Norway", "Oman", "Pakistan", "Panama", "Paraguay", "Peru", "Philippines", "Poland", "Portugal", "Puerto Rico", "Reunion", "Romania", "Rwanda", "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Serbia", "Sierra Leone", "Singapore", "Slovak Republic", "Slovenia", "Somalia", "South Africa", "Spain", "Sri Lanka", "Sudan", "Swaziland", "Sweden", "Switzerland", "Syria", "Taiwan", "Tanzania", "Thailand", "Togo", "Trinidad and Tobago", "Tunisia", "Turkey", "Uganda", "United Kingdom", "United States", "Uruguay", "Venezuela", "Vietnam", "West Bank and Gaza", "Yemen, Rep.", "Zambia", "Zimbabwe"],
#>       "sortable": true,
#>       "filterable": true,
#>       "tags": [],
#>       "label": "country",
#>       "type": "factor",
#>       "varname": "country"
#>     },
#>     {
#>       "levels": ["Africa", "Americas", "Asia", "Europe", "Oceania"],
#>       "sortable": true,
#>       "filterable": true,
#>       "tags": [],
#>       "label": "continent",
#>       "type": "factor",
#>       "varname": "continent"
#>     },
#>     {
#>       "locale": true,
#>       "digits": null,
#>       "sortable": true,
#>       "filterable": true,
#>       "tags": [],
#>       "label": "Mean of annual life expectancies",
#>       "type": "number",
#>       "varname": "mean_lifeexp"
#>     },
#>     {
#>       "locale": true,
#>       "digits": null,
#>       "sortable": true,
#>       "filterable": true,
#>       "tags": [],
#>       "label": "Lowest observed annual life expectancy",
#>       "type": "number",
#>       "varname": "min_lifeexp"
#>     }
#>   ],
#>   "state": {
#>     "layout": {
#>       "page": 1,
#>       "arrange": "rows",
#>       "ncol": 5,
#>       "nrow": 3,
#>       "type": "layout"
#>     },
#>     "labels": {
#>       "varnames": ["country", "continent", "wiki_link"],
#>       "type": "labels"
#>     },
#>     "sort": [
#>       {
#>         "dir": "asc",
#>         "varname": "continent",
#>         "type": "sort"
#>       },
#>       {
#>         "dir": "desc",
#>         "varname": "mean_lifeexp",
#>         "type": "sort"
#>       }
#>     ],
#>     "filter": [
#>       {
#>         "values": ["Africa"],
#>         "regexp": null,
#>         "filtertype": "category",
#>         "varname": "continent",
#>         "type": "filter"
#>       },
#>       {
#>         "max": 50,
#>         "min": null,
#>         "filtertype": "numberrange",
#>         "varname": "mean_lifeexp",
#>         "type": "filter"
#>       }
#>     ]
#>   },
#>   "views": [
#>     {
#>       "name": "Countries with high life expectancy (min >= 60)",
#>       "state": {
#>         "layout": {
#>           "page": 1,
#>           "arrange": "rows",
#>           "ncol": 3,
#>           "nrow": 2,
#>           "type": "layout"
#>         },
#>         "labels": {
#>           "varnames": ["continent", "country"],
#>           "type": "labels"
#>         },
#>         "sort": [
#>           {
#>             "dir": "desc",
#>             "varname": "min_lifeexp",
#>             "type": "sort"
#>           }
#>         ],
#>         "filter": [
#>           {
#>             "max": null,
#>             "min": 60,
#>             "filtertype": "numberrange",
#>             "varname": "min_lifeexp",
#>             "type": "filter"
#>           }
#>         ]
#>       }
#>     }
#>   ],
#>   "inputs": {
#>     "inputs": [
#>       {
#>         "height": 6,
#>         "width": 100,
#>         "type": "text",
#>         "active": true,
#>         "label": "Comments about this panel",
#>         "name": "comments"
#>       },
#>       {
#>         "options": ["no", "yes"],
#>         "type": "radio",
#>         "active": true,
#>         "label": "Does the data look correct?",
#>         "name": "looks_correct"
#>       }
#>     ],
#>     "storageInterface": {
#>       "type": "localStorage"
#>     },
#>     "feedbackInterface": {
#>       "feedbackEmail": "johndoe123@fakemail.net",
#>       "includeMetaVars": []
#>     }
#>   },
#>   "paneltype": "img",
#>   "panelformat": null,
#>   "panelaspect": null,
#>   "thumbnailurl": null
#> }
```
