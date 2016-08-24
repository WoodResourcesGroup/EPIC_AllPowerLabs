library(rmarkdown)

    library(viridis)

GitHub Documents
----------------

This is an R Markdown format used for publishing markdown documents to
GitHub. When you click the **Knit** button all R code chunks are run and
a markdown file (.md) suitable for publishing to GitHub is generated.

Including Code
--------------

You can include R code in the document as follows:

    image(volcano, col=viridis(200))

![](rmarkdown_tests_files/figure-markdown_strict/unnamed-chunk-2-1.png)<!-- -->

Including Plots
---------------

You can also embed plots, for example:

![](rmarkdown_tests_files/figure-markdown_strict/pressure-1.png)<!-- -->

Note that the `echo = FALSE` parameter was added to the code chunk to
prevent printing of the R code that generated the plot.
