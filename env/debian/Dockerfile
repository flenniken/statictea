# This builds a development environment for the statictea project.

FROM debian:11
MAINTAINER Steve Flenniken
ENV statictea_env=debian

# Install base apps.
RUN apt update && apt -qy install less man sudo tree curl wget

# Install the c language and the nim language.
# https://nim-lang.org/
RUN apt -qy install libssl-dev build-essential clang nim

# Install glow for viewing markdown at the command line.
# https://github.com/charmbracelet/glow
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://repo.charm.sh/apt/gpg.key \
  | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] \
  https://repo.charm.sh/apt/ * *" \
  | tee /etc/apt/sources.list.d/charm.list
RUN apt update && apt install glow

# Install jq for viewing JSON at the command line.
# https://github.com/stedolan/jq
ENV JQ_VERSION='1.5'
RUN \
  wget --no-check-certificate \
    https://raw.githubusercontent.com/stedolan/jq/master/sig/jq-release.key \
    -O /tmp/jq-release.key && \
  wget --no-check-certificate \
    https://raw.githubusercontent.com/stedolan/jq/master/sig/v${JQ_VERSION}/jq-linux64.asc \
    -O /tmp/jq-linux64.asc && \
  wget --no-check-certificate \
    https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 \
    -O /tmp/jq-linux64 && \
  gpg --import /tmp/jq-release.key && \
  gpg --verify /tmp/jq-linux64.asc /tmp/jq-linux64 && \
  cp /tmp/jq-linux64 /usr/bin/jq && \
  chmod +x /usr/bin/jq && \
  rm -f /tmp/jq-release.key && \
  rm -f /tmp/jq-linux64.asc && \
  rm -f /tmp/jq-linux64

# Install graphviz for creating svg dependency charts.
# https://graphviz.org/
RUN apt install -qy graphviz

# Create user teamaster with sudo permissions and no password.
RUN mkdir -p /etc/sudoers.d \
  && echo "teamaster ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/teamaster \
  && chmod 440 /etc/sudoers.d/teamaster \
  && adduser --disabled-password --gecos '' teamaster \
  && usermod -aG sudo teamaster \
  && echo 'teamaster:devenv' | chpasswd

# Switch to user teamaster for following commands.
USER teamaster
WORKDIR /home/teamaster

# Choosenim install isn't supported for linux_arm64 yet.
# You could probably get the latest nim version as a tar file and build it.
# # Install choosenim and the latest version of nim.
# RUN curl -sSfLo init.sh https://nim-lang.org/choosenim/init.sh \
#   && sed -i 's/need_tty=yes/need_tty=no/' init.sh \
#   && bash init.sh \
#   && rm init.sh
# Use the bashrc file instead of this:
# && export PATH=/home/teamaster/.nimble/bin:$PATH \
# && echo "export PATH=$PATH" >> .bashrc

# Install bashrc for the prompt and some aliases.
COPY --chown=teamaster:teamaster bashrc .bashrc

# Start in the statictea directory.
WORKDIR /home/teamaster/statictea
CMD ["/bin/bash"]

