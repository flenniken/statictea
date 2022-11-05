# This builds a development environment for the statictea project.

FROM debian:latest
MAINTAINER Steve Flenniken

# Install apps.
RUN apt-get update && apt-get -qy install less man sudo tree \
  libssl-dev build-essential gcc curl nim

# Create user steve with sudo permissions and no password.
RUN mkdir -p /etc/sudoers.d \
  && echo "steve ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/steve \
  && chmod 440 /etc/sudoers.d/steve \
  && adduser --disabled-password --gecos '' steve \
  && usermod -aG sudo steve \
  && echo 'steve:devenv' | chpasswd

# Switch to user steve for following commands.
USER steve
WORKDIR /home/steve

# # Install choosenim and the latest version of nim.
# RUN curl -sSfLo init.sh https://nim-lang.org/choosenim/init.sh \
#   && sed -i 's/need_tty=yes/need_tty=no/' init.sh \
#   && bash init.sh \
#   && rm init.sh

# && export PATH=/home/steve/.nimble/bin:$PATH \
# && echo "export PATH=$PATH" >> .bashrc

# Install bashrc
COPY --chown=steve:steve bashrc .bashrc

WORKDIR /home/steve/statictea
CMD ["/bin/bash"]

