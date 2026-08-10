#----load library
library(ggplot2)
library(dplyr)
library(tidyr)
library(readxl)

#---- Read Q matrix
Q <- read.table("outfile.Q", header = FALSE)
colnames(Q) <- c("K1","K2")

#---- Read metadata
meta <- read.table("D:/MS/19. ddRAD_gharial/MS19 Analysis/admixture/outfile4a.2.meta.txt", header = FALSE,
                   col.names = c("Individual","Population"))

#---Combine and order
dat <- cbind(meta, Q)
pop.order <- c("PA","BR","RD","DG","TG")
dat$Pop <- dat$Population
dat$Pop <- factor(dat$Pop, levels = pop.order)
dat <- dat %>% arrange(Pop)
dat$Ind <- 1:nrow(dat)

#---- Convert to long format
long <- pivot_longer(dat, cols = c(K1, K2),
                     names_to = "Cluster",
                     values_to = "Q")

#----define population boundaries
bounds <- dat %>%
  group_by(Pop) %>%
  summarise(start = min(Ind),
            end = max(Ind),
            center = (start + end)/2,
            .groups = "drop")

#---- Plot
p1<-ggplot(long,aes(x = Ind, y = Q, fill = Cluster)) +
  geom_col(width = 0.95, colour = "white", linewidth = 0.35) +  # thin white line between individuals
  geom_vline(xintercept = bounds$end[-nrow(bounds)] + 0.5, linewidth = 0.5, colour = "black") +  # only one separator between populations
  scale_fill_manual(values = c("#9FD7DD",   # light teal "antiquewhite"    # cream)) + 
  scale_x_continuous(
    breaks = bounds$center,
    labels = bounds$Pop,
    expand = c(0,0)) +
  scale_y_continuous(
    limits = c(0,1),
    expand = c(0,0)) +
  labs(y = "Ancestry coefficient (Q)",
       x = NULL) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "none",
    panel.border = element_blank(),
    axis.line.x = element_blank(),
    axis.line.y = element_line(colour = "black", linewidth = 0.7),
    axis.text.x = element_text(size = 12), #face = "bold"
    axis.text.y = element_text(size = 12),
    axis.ticks.x = element_blank())
p1
ggsave("Fig3A._admixture_K2.pdf", plot = p1, width = 10, height = 4)
ggsave("Figure_admixture_K2.tiff", plot = p1, width = 10, height = 4, dpi = 300, compression = "lzw")
