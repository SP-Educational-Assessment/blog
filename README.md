# Blog based on the [Wowchemy Website Builder](https://wowchemy.com)

The blog is served from here:

blog.speduconsulting.co.uk 


[**Wowchemy**](https://github.com/wowchemy/wowchemy-hugo-modules/) makes it easy to create a beautiful website for free using Markdown, Jupyter, or RStudio. Customize anything on your site with widgets, themes, and language packs.

- 👉 [**Get Started**](https://wowchemy.com/docs/install/)
- 📚 [View the **documentation**](https://wowchemy.com/docs/)


## Running in a Container

There are a set of Docker build scripts that can be run so that you can view the blog running in an Apache webserver (current Apache version 2.4 is used). This is useful if you want to run it on a staging server.

* docker-build.sh (build the container image)
* docker-run.sh (run the container, navigate to <https://localhost> to view the website)
* docker-clean.sh (get rid of the container)
* docker-save.sh (saves the container image to the file speduas-www-image.tar)

If you want to move the container to a different host you can copy the speduas-blog-image.tar file, and then load it on the other host. To do this, run the `docker-build.sh` and `docker-save.sh` scripts in sequence to create a new `speduas-blog-image.tar` image file. Then copy this file over to the host you want to run it on (using `scp` or `rsync` for instance).

```bash
scp speduas-blog-image.tar jamesp@niobium:Projects/szilvi-website-images
```

You can then log on to that host and load the image by running this command:

```bash
docker load --input speduas-blog-image.tar
```

You can then run a new container on this host like this:

```bash
docker run --name szilvi-blog -p 80:80 speduas-blog
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
http http://niobium/
```

Note that HTTPS is not configured for use in the Docker container.

## Publish to Live

The easiest way to publish to the Mythic Beasts hosting service is to zip the build directory then copy it to the `onza` host:

```bash
zip -r speduas-blog-image build -x "*.DS_Store"
scp speduas-blog-image.zip jamesp27@onza.mythic-beasts.com:www
```

Then log on to the `onza` host and extract to a new folder called `build` in `www`:

```bash
unzip speduas-blog-image.zip
```

You can use the `tree build` command to check that the files have been extracted.

Finally, when you are ready to make the switch, do a folder rename like this:

```bash
mv blog.speduconsulting.co.uk oldsite
mv build blog.speduconsulting.co.uk
rm -Rf build
```

Then use the following URL to browse the live site: <https://blog.speduconsulting.co.uk/>.

You can then delete the `oldsite` folder when you are happy with the change.
