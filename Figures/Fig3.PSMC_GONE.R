#----load library
library(dplyr)
library(ggplot2)
library(scales)
library(readxl)

rm(list = ls())

#----paths
setwd("psmc")

#---- 1. PARSE PSMC DATA
parse_psmc_combined <- function(file, mu = 0.8e-8, gen_time = 25, bin_size = 100) {lines <- readLines(file)
  
  # Every "RD\t0" marks the start of a new independent run (main or bootstrap)
  run_starts <- grep("^RD\t0$", lines)
  run_ends   <- c(run_starts[-1] - 1, length(lines))
  
  out <- lapply(seq_along(run_starts), function(i) {
    run_block <- lines[run_starts[i]:run_ends[i]]
    
    # Within this run, find its own RD indices and take the LAST one (converged)
    rd_idx_local <- grep("^RD", run_block)
    final_start  <- tail(rd_idx_local, 1)
    block <- run_block[final_start:length(run_block)]
    
    tr_line <- block[grep("^TR", block)]
    if (length(tr_line) == 0) return(NULL)
    theta0 <- as.numeric(strsplit(tr_line, "\t")[[1]][2])
    
    rs_lines <- block[grep("^RS", block)]
    if (length(rs_lines) == 0) return(NULL)
    rs <- do.call(rbind, strsplit(rs_lines, "\t"))
    d <- data.frame(t_k = as.numeric(rs[, 3]), lambda_k = as.numeric(rs[, 4]))
    
    N0 <- theta0 / (4 * mu * bin_size)
    d$years <- d$t_k * 2 * N0 * gen_time
    d$Ne    <- N0 * d$lambda_k
    d$run   <- i
    d
  })
  bind_rows(out)}

all_runs <- parse_psmc_combined("combined.psmc",
                                mu = 0.8e-8,
                                gen_time = 25,
                                bin_size = 100)

main  <- filter(all_runs, run == 1)    # first run = main estimate
boots <- filter(all_runs, run != 1)    # remaining runs = bootstrap replicates

#---- clean datset tag with method, filter PSMC to years >= 5000 (drop unreliable recent tail) ----
psmc_main  <- main  %>% mutate(method = "PSMC") %>% filter(years >= 5000)
psmc_boots <- boots %>% mutate(method = "PSMC") %>% filter(years >= 5000)

#---- 2.LOAD GONE2 DATA
df_gone <- read_excel("D:/MS/19. ddRAD_gharial/MS19 Submission/BMC Genomics Data/Revision I/MS19 Supplementary tables-v2.R1.bak.xlsx",
                      sheet = "GONE2")

df_gone <- df_gone %>%
  rename(Replicate = 1, Generation = 2, Ne = 3) %>%
  mutate(Generation = as.numeric(Generation),
         Ne = as.numeric(Ne),
         years = Generation * 25)   # match PSMC's gen_time

gone_main <- df_gone %>% filter(Replicate == "M") %>% arrange(years) %>%
  transmute(years, Ne, method = "GONE2")

gone_reps <- df_gone %>% filter(Replicate != "M") %>%
  rename(run = Replicate) %>% arrange(run, years) %>%
  transmute(years, Ne, run, method = "GONE2")

#---- 3. COMBINE PSMC + GONE2
main_all <- bind_rows(
  psmc_main %>% select(years, Ne, method),
  gone_main)

reps_all <- bind_rows(
  psmc_boots %>% select(years, Ne, run, method) %>% mutate(run = paste0("psmc_", run)),
  gone_reps  %>% mutate(run = paste0("gone_", run))
)

#---- 4. AXIS SCALING
ne_range <- range(c(main_all$Ne, reps_all$Ne), na.rm = TRUE)
unit_scale <- 10000
y_max <- 42000
x_breaks <- c(10, 100, 1000, 10000, 100000, 1000000, 5e6)
y_breaks <- seq(0, ceiling(ne_range[2] / (0.5*unit_scale)) * 0.5 * unit_scale, by = 0.5 * unit_scale)

xlim_min <- min(gone_main$years, na.rm = TRUE)   # capture GONE2's earliest point
xlim_max <- 6000000

#---- 5. GEOLOGICAL PERIOD BANDS
periods <- data.frame(
  label = c("Holocene", "Pleistocene", "Pliocene"),
  start = c(0, 11700, 2580000),
  end   = c(11700, 2580000, 6000000),
  fill  = c("#F5E6A3", "#B7CFE0", "palegreen4")
)

strip_bottom <- y_max * 0.90
strip_top    <- y_max * 0.98

periods <- periods %>%
  mutate(
    strip_bottom = strip_bottom,
    strip_top = strip_top,
    y_center   = (strip_top + strip_bottom) / 2,
    start_clip = pmax(start, xlim_min),
    end_clip   = pmin(end, xlim_max),
    x_center   = 10^((log10(start_clip) + log10(end_clip)) / 2),
    fontsize   = c(3.0, 3.0, 2.0)
  )
periods <- periods %>%
  mutate(
    start_clip = pmax(start, xlim_min),
    end_clip   = pmin(end, xlim_max),
    x_center   = 10^((log10(start_clip) + log10(end_clip)) / 2),
    y_center   = (strip_top + strip_bottom) / 2
  )
periods$start_clip[1] <- -Inf
periods$end_clip[nrow(periods)] <- Inf
geom_rect(data = periods,
          aes(xmin = start_clip, xmax = end_clip, ymin = strip_bottom, ymax = strip_top),
          fill = periods$fill, color = "white", linewidth = 0.4,
          alpha = 0.50, inherit.aes = FALSE)

#---- 6. PLOT
p <- ggplot() +
  geom_rect(data = periods,
            aes(xmin = start, xmax = end, ymin = strip_bottom, ymax = strip_top),
            fill = periods$fill, color = "white", linewidth = 0.4,
            alpha = 0.50, inherit.aes = FALSE) +
  geom_text(data = periods,
            aes(x = x_center, y = y_center, label = label, size = fontsize),
            fontface = "bold", color = "gray15", hjust = 0.5, vjust = 0.5) +
  scale_size_identity() +
  geom_step(data = reps_all,
            aes(x = years, y = Ne, group = run, color = method),
            alpha = 0.05, linewidth = 0.5) +
  geom_step(data = main_all,
            aes(x = years, y = Ne, color = method),
            linewidth = 1) +
  scale_color_manual(values = c("PSMC" = "darkblue", "GONE2" = "darkred"), name = "Method") +
  scale_x_log10(labels = scales::comma, breaks = x_breaks,
                limits = c(xlim_min, xlim_max), expand = c(0, 0))+
  scale_y_continuous(breaks = y_breaks, labels = y_breaks / unit_scale,
                     limits = c(0, y_max), expand = c(0, 0)) +
  labs(x = "Years before present", y = expression(paste("Effective population size, ", N[e], " (x", 10^4, ")"))) +
  theme_minimal(base_size = 13) +
  theme(axis.line = element_line(colour = "grey20", linewidth = .5, linetype = "solid"),
        axis.ticks = element_line(colour = "grey20", linewidth = .4),
        axis.ticks.length = unit(0.15, "cm"),
        text = element_text(size = 12),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(),
        legend.position = c(0.02, 0.90),
        legend.justification = c(0, 1),
        legend.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(t = 10, r = 15, b = 10, l = 10)) +
  
  geom_segment(data = data.frame(x = c(11700, 2580000)),
               aes(x = x, xend = x, y = 0, yend = strip_bottom),
               linetype = "dashed", color = "gray40")

print(p)
