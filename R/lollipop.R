

#' Title
#'
#' @param .data a
#' @param vars a
#' @param group a
#'
#' @return
#' @export
#'
prepare_lollipop_data <- function(.data, vars, group) {
  # assert group - logical
  d <- .data %>%
    pivot_longer({{ vars }}) %>%
    mutate(value = sten(value))

  ref_meds <- d %>%
    filter(!{{ group }}) %>%
    group_by(name) %>%
    summarise(med = median(value, na.rm = TRUE))

  n_vars <- nrow(ref_meds)

  diff_data <- d %>%
    filter({{ group }}) %>%
    left_join(ref_meds, by = "name") %>%
    mutate(diff = value - med)

  main_data <- d %>%
    group_by({{ group }}, name) %>%
    summarise(value = median(value, na.rm = TRUE), .groups = "keep") %>%
    pivot_wider(names_from = {{ group }}) %>%
    mutate(diff = `TRUE` - `FALSE`) # positive = larger foc. group value

  list(
    d = d,
    ref_meds = ref_meds,
    n_vars = n_vars,
    diff_data = diff_data,
    main_data = main_data
  )
}


#' Title
#'
#' @param plot_data a
#' @param direction a
#' @param var_labels a
#' @param negative_label a
#' @param positive_label a
#' @param ref_label a
#'
#' @return
#' @export
#'
plot_lollipop <- function(plot_data, direction = 1,
                          var_labels = waiver(),
                          negative_label = NULL, positive_label = NULL, ref_label = NULL) {
  plot_data$main_data %>%
    ggplot(aes(diff, name, col = diff > 0)) +
    # reference group line
    geom_vline(xintercept = 0, col = "grey", linetype = "dashed", size = .75) +
    # focal group datapoints
    geom_jitter(
      height = .25, width = 0, alpha = .2, shape = 16, size = 2,
      data = plot_data$diff_data
    ) +

    # lollipop stem
    geom_linerange(aes(xmax = diff, xmin = 0), size = 2.33, alpha = .5) +
    # lollipop ball-end
    geom_point(size = 4.5) +

    # negative (left) half-plane annotation arrow
    geom_segment(
      x = -.1, xend = -.9,
      y = .333, yend = .333,
      arrow = arrow(length = unit(.06, "in"), type = "closed"),
      col = "grey"
    ) +
    # negative (left) half-plane annotation text
    geom_richtext(
      aes(x = -.1, y = .333), # without aes(), nudge does not work...
      label = positive_label,
      vjust = 1.2,  hjust = 1, col = "grey", fill = NA, label.color = NA
    ) +

    # positive (right) half-plane annotation arrow
    geom_segment(
      x = .1, xend = .9,
      y = .333, yend = .333,
      arrow = arrow(length = unit(.06, "in"), type = "closed"),
      col = "grey"
    ) +
    # positive (right) half-plane annotation text
    geom_richtext(
      aes(x = .1, y = .333),
      label = negative_label,
      vjust = 1.2, hjust = 0, col = "grey", fill = NA, label.color = NA
    ) +

    # reference group annotation arrow
    geom_curve(
      x = .5, xend = .1,
      yend = plot_data$n_vars + .4, y = plot_data$n_vars + .5,
      arrow = arrow(length = unit(.06, "in"), type = "closed"), curvature = .2,
      col = "grey"
    ) +

    # reference group annotation text
    geom_text(
      label = ref_label,
      x = .5, y = plot_data$n_vars + .5,
      vjust = .4, hjust = -.075,
      col = "grey", lineheight = 1
    ) +
    scale_x_continuous(
      breaks = scales::breaks_width(2),  minor_breaks = scales::breaks_width(1),
      expand = expansion(.025)
    ) +
    scale_y_discrete(
      labels = var_labels, # named vector of variable-label
      expand = expansion(add = c(1.05, .65))
    ) +
    # master color depending on diff sign
    scale_color_manual(
      values = c(`TRUE` = "#2C7BB6FF", `FALSE` = "#D7191CFF")
    ) +
    guides(col = guide_none()) + # disable legend
    xlab("rozdíl mezi Vaší školou a ostatními") +
    ylab(NULL) +
    theme_schola("x") +
    theme(
      plot.subtitle = element_markdown(lineheight = 1.1),
      # axis.title.x = element_markdown(),
      panel.grid.minor.x = element_line(colour = "grey92", size = .15)
    )
}


