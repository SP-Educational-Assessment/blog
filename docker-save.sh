#!/usr/bin/env bash

docker save -o speduas-blog-image.tar speduas-blog

# scp speduas-blog-image.tar jamesp@niobium:Projects/szilvi-website-images