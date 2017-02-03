### Crop 2016 results from results_16_crop (which was cropped in Arc and took forever to load)

# Check that crs match
crs(results_16_crop)
crs(FS_CA)

# Crop 2016 results to the size of each of the management units
unit_names <- c("FS", "KCNP", "LNP", "MH", "SNP", "SP")

for(i in 1:length(unit_names)) {
  print(i)
}
results_16_