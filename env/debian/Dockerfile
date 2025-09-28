# This builds a development environment for the statictea project.

FROM debian:12
MAINTAINER Steve Flenniken
ENV statictea_env=debian

# Install base apps.
RUN apt update && apt -qy install less man sudo tree curl wget nano git

# Install the c language.
RUN apt -qy install libssl-dev build-essential clang

# Install graphviz for creating svg dependency charts.
# https://graphviz.org/
RUN apt install -qy graphviz

# Install jq for viewing JSON at the command line.
# https://github.com/stedolan/jq
RUN apt -qy install jq

# Install glow for viewing markdown at the command line.
# https://github.com/charmbracelet/glow
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://repo.charm.sh/apt/gpg.key \
  | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] \
  https://repo.charm.sh/apt/ * *" \
  | tee /etc/apt/sources.list.d/charm.list
RUN apt update && apt install glow

# Install the perl regular expression library to avoid "could not
# load: libpcre.so(.3|.1|)" runtime error.
RUN apt -qy install libpcre3 libpcre3-dev

# Create user teamaster with sudo permissions and no password.
RUN mkdir -p /etc/sudoers.d \
  && echo "teamaster ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/teamaster \
  && chmod 440 /etc/sudoers.d/teamaster \
  && adduser --disabled-password --gecos '' teamaster \
  && usermod -aG sudo teamaster \
  && echo 'teamaster:devenv' | chpasswd

RUN chown teamaster:teamaster /home/teamaster

# Switch to user teamaster for following commands.
USER teamaster
WORKDIR /home/teamaster

# The debian package manager installs an old nim version.  To get a
# newer version you can download prebuilt binaries or build from
# source.  The prebuilt binaries are built for x86 machines and no
# version for arm64. The x86 version will run using emulation, however
# nimble is very slow.  You can build from source by cloning the git
# repo, checking out a version tag and running a build script.  This
# docker file supports the build from source method.

# Note: You need to manually run build_all.sh once in the container to
# build nim.

# cd ~/Nim
# build_all.sh
# nim -v

# Get nim source for manually building nim.
RUN git clone https://github.com/nim-lang/Nim.git
ARG nim_version=v2.2.4
RUN cd Nim \
  && git checkout $nim_version \
  && git switch -c $nim_version

# Install bashrc for the prompt and some aliases.
COPY --chown=teamaster:teamaster bashrc .bashrc

# Start in the statictea directory.
WORKDIR /home/teamaster/statictea
CMD ["/bin/bash"]
