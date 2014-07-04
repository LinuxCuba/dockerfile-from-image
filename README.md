## dockerfile-from-image
Reverse-engineers a Dockerfile from a Docker image.

Using the metadata that Docker stores alongside each layer of an image, the
*dockerfile-from-image* script is able to re-create ([approximately](#limitations)) the
Dockerfile that was used to generate an image.

### Usage

The Ruby *dockerfile-from-image* script is itself packaged as a Docker image
so it can easily be executed with the Docker *run* command:

    docker run -v /var/run/docker.sock:/var/run/docker.sock \
      centurylinklabs/dockerfile-from-image <IMAGE_TAG_OR_ID>

The `<IMAGE_TAG_OR_ID>` parameter can be either an image tag (e.g. `ruby`) or
an image ID (either the truncated form or the complete image ID).

Since the script interacts with the Docker API in order to query the metadata
for the various image layers it needs access to the Docker API socket.  The
`-v` flag shown above makes the Docker socket available inside the container
running the script.

Note that the script only works against images that exist in your local image
repository (the stuff you see when you type `docker images`). If you want to
generate a Dockerfile for an image that doesn't exist in your local repo
you'll first need to `docker pull` it.

### Example
Here's an example that shows the official Docker ruby image being pulled and
the Dockerfile for that image being generated.

    $ docker pull ruby
    Pulling repository ruby

    $ docker run -v /run/docker.sock:/run/docker.sock centurylinklabs/dockerfile-from-image ruby
    FROM buildpack-deps:latest
    RUN useradd -g users user
    RUN apt-get update && apt-get install -y bison procps
    RUN apt-get update && apt-get install -y ruby
    ADD dir:03090a5fdc5feb8b4f1d6a69214c37b5f6d653f5185cddb6bf7fd71e6ded561c in /usr/src/ruby
    WORKDIR /usr/src/ruby
    RUN chown -R user:users .
    USER user
    RUN autoconf && ./configure --disable-install-doc
    RUN make -j"$(nproc)"
    RUN make check
    USER root
    RUN apt-get purge -y ruby
    RUN make install
    RUN echo 'gem: --no-rdoc --no-ri' >> /.gemrc
    RUN gem install bundler
    ONBUILD ADD . /usr/src/app
    ONBUILD WORKDIR /usr/src/app
    ONBUILD RUN [ ! -e Gemfile ] || bundle install --system

### Limitations
As the *dockerfile-from-image* script walks the list of layers contained in the
image it stops when it reaches the first tagged layer. It is assumed that a layer
which has been tagged represents a distinct image with its own Dockerfile so the
script will output a `FROM` directive with the tag name.

In the example above, the *ruby* image contained a layer in the local image
repository which had been tagged with *buildpack-deps* (though it wasn't shown
in the example, this likely means that *buildpack-deps:latest* was also pulled
at some point). If the *buildpack-deps* layer had not been tagged, the
*dockerfile-from-image* script would have continued outputing Dockerfile
directives until it reached the root layer.

Also note that the output generated by the script won't match exactly the
original Dockerfile if either the `COPY` or `ADD` directives (like the
example above) are used. Since we no longer have access to the build context
that was present when the original `docker build` command was executed all we
can see is that some directory or file was copied to the image's filesystem.
