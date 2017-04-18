### Look at negative values
neg <- subset(results, results$D_BM_kg<0)
summary(neg$D_BM_kg)
summary(as.factor(neg$Pol.ID))
names(neg)
summary(neg$BPH_GE_25_CRM)
summary(neg$TPH_GE_25)
summary(neg$relNO)
hist(neg$relNO)

sum(neg$D_BM_kg)

drought16_neg <- subset(drought16, drought16$NO_TREES1<0)
summary(drought16_neg$NO_TREES2)
summary(drought16$NO_TREES2)
summary(drought16$NO_TREES3)
summary(drought16_neg$TPA1)

large <- subset(results16, results16$D_BM_kg > 60000)
nrow(large)
nrow(results16)

sum(as.numeric(results16$Pol.NO_TREES1))
sum(results16$relNO)
sum(results1215$relNO)
700,000,000,000

summary(results16$BPH_GE_25_CRM/11.1)
summary(results16$BPH_abs)
