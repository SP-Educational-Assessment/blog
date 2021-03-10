# SP Educational Assessment Blog

This repo can be used to build the SP Educational Assessment blog (using the Blogdown package from within RStudio). Helper scripts then allow you to deploy a Docker container to a staging server. Once you've completed tests you can then push to live.

The live blog is current served from this domain-name (on Mythic Beasts):

`blog.speduconsulting.co.uk`

## Hugo Theme

Bookdown is based on the [Hugo](https://gohugo.io/) static website framework, and currently uses a custom theme called `starter-blog`, which is based on the [Wowchemy](https://github.com/wowchemy/wowchemy-hugo-modules/) Hugo theme.

If you want to make changes to the theme then it's recommended to read through and understand the following:

### Blogdown

- [Blogdown](https://bookdown.org/yihui/blogdown/themes.html)

### Wowchemy Theme

- [Getting Started](https://wowchemy.com/docs/install/)
- [Documentation](https://wowchemy.com/docs/)

## Local Development

Once you've checked out this repo, you can make changes to files in the `/content` folder. New posts are added as sub-folders under `/content/post`. Other folders you shouldn't need to touch.

RStudio comes with a useful Addin that makes it relatively straightforward to add new posts. There is a handy tutorial on how to do this in the [Get Started](https://bookdown.org/yihui/blogdown/rstudio-ide.html) section of the Blogdown documentation.

### Building the Site

To build and serve the blog on your local development environment, first run the `build_site()` command from the RStudio console:

```r
blogdown::build_site()
```

Then you can then run the `serve_site()` command to start a local webserver and view the blog in a browser (it's recommended to use a real browser when testing locally rather than RStudio's built-in viewer):

```r
blogdown::serve_site()
```

Once you're happy you can then run the blog in an Apache webserver to test how it will behave on the live (Mythic Beasts) platform. The easiest way to do this is via a Docker container.

## Running in a Container

There are a set of Docker build scripts that can be run so that you can view the blog running in an Apache webserver (current Apache version 2.4 is used). This is useful if you want to run it on a staging server.

* docker-build.sh (build the container image)
* docker-run.sh (run the container, navigate to <https://localhost> to view the website)
* docker-clean.sh (get rid of the container)
* docker-save.sh (saves the container image to the file speduas-blog-image.tar)

If you want to move the container to a different host you can copy the speduas-blog-image.tar file, and then load it on the other host. To do this, run the `docker-build.sh` and `docker-save.sh` scripts in sequence to create a new `speduas-blog-image.tar` image file. Then copy this file over to the host you want to run it on (using `scp` or `rsync` for instance).

```bash
scp speduas-blog-image.tar jamesp@niobium:Projects/szilvi-website-images
```

You can then log on to that host and load the image by running this command:

```bash
docker load --input speduas-blog-image.tar
```

You can then run a new container on this host (using port 81 for client requests) like this:

```bash
docker run --name szilvi-blog -d -p 81:80 speduas-blog
```

If you get the following error message on the remote host:

`docker: Error response from daemon: Conflict. The container name "/szilvi-blog" is already in use by container`

Then it means you have an older version of the container. You can remove it as follows:

```bash
docker rm szilvi-blog
```

Then try again.

Finally, once your container is running on your remote host, you can connect to the Apache webserver and view the website with a simple URL:

```bash
http http://niobium:81/
```

Note that HTTPS is not configured for use in the Docker container.

## Publish to Live

The easiest way to publish to the Mythic Beasts hosting service is to zip the `public` directory then copy it to the `onza` host:

```bash
cp .htaccess public/.htaccess
zip -r speduas-blog-image public -x "*.DS_Store"
scp speduas-blog-image.zip jamesp27@onza.mythic-beasts.com:www
```

Then log on to the `onza` host and extract to a new folder called `public` in `www`:

```bash
unzip speduas-blog-image.zip
```

You can use the `tree public` command to check that the files have been extracted.

Finally, when you are ready to make the switch, do a folder rename like this:

```bash
mv blog.speduconsulting.co.uk oldsite
mv public blog.speduconsulting.co.uk
```

Then use the following URL to browse the live site: <https://blog.speduconsulting.co.uk/>.

You can then delete the `oldsite` folder when you are happy with the change.
