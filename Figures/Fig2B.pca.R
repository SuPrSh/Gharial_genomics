#---- load library
library(tidyverse)

#---- load covariance matrix
cov <- as.matrix(read.table("pca.r3.covMat", header = F)) 

#---- add metadata file or population assignments
pop <- c("PA","DG","BR","TG","TG","BR","DG","PA","PA","PA","PA","PA","RD","RD","RD","RD","BR","BR","BR","BR","BR")

#----PCA using eigen decomposition
mme.pca <- eigen(cov)

#----Percent variance explained
var_exp <- mme.pca$values / sum(mme.pca$values) * 100

# Build plotting data frame
pca.vectors <- tibble( pop = pop,
  PC1 = mme.pca$vectors[, 1],
  PC2 = mme.pca$vectors[, 2])

#----Choose colors
pop_cols <- c(
  "PA" = "#F28E8C",  # salmon
  "BR" = "#A6A600",  # olive
  "RD" = "#1FC48C",  # green-teal
  "DG" = "#25A9E0",  # blue
  "TG" = "#D870E8")
pca.vectors$pop <- factor(pca.vectors$pop,levels = c("PA", "BR", "RD", "DG", "TG"))

pca_plot <- ggplot(pca.vectors, aes(x = PC1, y = PC2, colour = pop)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.5) +
  geom_point(size = 4, shape=19, alpha=.8) +
  scale_colour_manual(values = pop_cols) +
  labs(x = paste0("PC1 (", round(var_exp[1], 2), "% variance)"),
    y = paste0("PC2 (", round(var_exp[2], 2), "% variance)"),
    colour = "Sampling site") +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major = element_line(colour = "grey85", linewidth = 0.4),
    panel.grid.minor = element_line(colour = "grey92", linewidth = 0.25),
    axis.title = element_text(size = 12, colour = "black"),
    axis.text = element_text(size = 12, colour = "grey25"),
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 12),
    legend.position = "right")

pca_plot

ggsave(filename = "Fig2B.pcaPlot.pdf", plot = pca_plot, width = 7, height = 5)
