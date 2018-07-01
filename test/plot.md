# plot - Plot package

## pvector - Plot an arbitrary vector in a 2D image

This is a test for [#42](https://github.com/iraf-community/iraf/issues/42)
(originally reported ad [iraf.net](http://iraf.net/forum/viewtopic.php?showtopic=1469841)

```
cl> plot
cl> pvector dev$pix xc=250 yc=250  theta=235  vec_out=pvec out_typ=image
cl> pvector dev$pix xc=250 yc=251  theta=235  vec_out=pvec out_typ=image
```

