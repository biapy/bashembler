FROM bash:5.2.15-alpine3.18

COPY --chown=root:root --chmod=755 "bin/bashembler" "/usr/local/bin/bashembler"

RUN mkdir '/data' && \
  chown 1000:1000 '/data' && \
  chmod 775 '/data'

SHELL ["/bin/bash", "-c"]

# Entrypoint is bashembler interpreted by bash.
ENTRYPOINT ["/usr/local/bin/bash", "/usr/local/bin/bashembler"]

# Defualt argument for bashembler is --help to print usage information.
CMD ["--help"]

# OpenContainers annotations
# See: https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL "org.opencontainers.image.base.name"="biapy/bashembler"
LABEL "org.opencontainers.image.title"="Bashembler"
LABEL "org.opencontainers.image.description"="command-line tool to build a single-file bash script from a\
  main script sourcing other scripts."
LABEL "org.opencontainers.image.vendor"="Biapy"
LABEL "org.opencontainers.image.licenses"="MIT"
LABEL "org.opencontainers.image.authors"="Pierre-Yves Landuré\
  - https://github.com/landure\
  - https://twitter.com/@biapy\
  - https://howto.biapy.com/"
LABEL "org.opencontainers.image.source"="https://github.com/biapy/bashembler/"
LABEL "org.opencontainers.image.docker.run"="docker run --rm --volume '.:/data' 'biapy/bashembler' 'input.sh' 'output.sh'"
