# Dominant Color
(Swift 3)

#### Purpose
This project tries to obtain the most accurate dominant `n` number of colors in an image.

#### Algorithm
To obtain the colors I use a [k-mean clustering](https://en.wikipedia.org/wiki/K-means_clustering) algorithm to cluster pixels and find the most dominant colors. For more accurate representation I also created a [k-means++ initialization](https://en.wikipedia.org/wiki/K-means%2B%2B) algorithm to better place initial centroid nodes.

#### Issues
Execution time currently takes ~1.6s for most images.
I'll look into [Color Quantization](http://www.graphicsmagick.org/quantize.html) to see if it is viable to use this algorithm instead.
