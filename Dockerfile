# Use Debian stable as the base
FROM debian:stable

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for building Erlang/OTP
RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    m4 \
    libncurses-dev \
    libssl-dev \
    unixodbc-dev \
    libgmp-dev \
    libwxgtk3.2-dev \
    libsctp-dev \
    lksctp-tools \
    git \
    curl \
    ca-certificates \
    podman \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Build GmSSL v2 (OpenSSL-compatible fork with SM support)
# We add -Wno-error=incompatible-pointer-types to handle newer GCC versions
RUN git clone -b GmSSL-v2 https://github.com/guanzhi/GmSSL.git /tmp/GmSSL \
    && cd /tmp/GmSSL \
    && ./config --prefix=/opt/gmssl -Wno-error=incompatible-pointer-types \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/GmSSL

# Install kerl (Erlang version manager)
RUN curl -L https://raw.githubusercontent.com/kerl/kerl/master/kerl -o /usr/local/bin/kerl \
    && chmod a+x /usr/local/bin/kerl

# Set up kerl
WORKDIR /opt/erlang
RUN kerl update releases

# Build Erlang 26
RUN kerl build 26.2.5 26 && kerl install 26 /opt/erlang/26

# Build Erlang 28
RUN kerl build 28.0 28 && kerl install 28 /opt/erlang/28

# Build Erlang 29
RUN kerl build 29.0 29 && kerl install 29 /opt/erlang/29

# Build GmSSL-linked Erlang
RUN KERL_CONFIGURE_OPTIONS="--with-ssl=/opt/gmssl" kerl build 26.2.5 gmssl \
    && kerl install gmssl /opt/erlang/gmssl

# Cleanup kerl builds to save space
RUN kerl cleanup all

# Create a helper script to switch versions easily
RUN echo '#!/bin/bash\n\
if [ -z "$1" ]; then\n\
  echo "Usage: switch-erlang [26|28|29|gmssl]"\n\
  return 1\n\
fi\n\
case $1 in\n\
  26) source /opt/erlang/26/activate ;;\n\
  28) source /opt/erlang/28/activate ;;\n\
  29) source /opt/erlang/29/activate ;;\n\
  gmssl) \n\
    source /opt/erlang/gmssl/activate\n\
    export LD_LIBRARY_PATH=/opt/gmssl/lib:$LD_LIBRARY_PATH\n\
    ;;\n\
  *) echo "Unknown version: $1. Supported: 26, 28, 29, gmssl" ; return 1 ;;\n\
esac\n\
echo "Erlang $(erl -noshell -eval '\''io:format("~s", [erlang:system_info(otp_release)]), halt().'\'') activated."' \
> /usr/local/bin/switch-erlang.sh && chmod +x /usr/local/bin/switch-erlang.sh

# Add the switcher to .bashrc for easy use
RUN echo 'alias switch-erlang="source /usr/local/bin/switch-erlang.sh"' >> /root/.bashrc

# Default Erlang version on login
RUN echo 'source /opt/erlang/29/activate' >> /root/.bashrc

# Create logs directory
RUN mkdir -p /var/log/erlang

# Set working directory for user projects
WORKDIR /workspace

CMD ["/bin/bash"]
