# Use Ubuntu 24.04 as the base (LTS available in 2026)
FROM ubuntu:24.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for building Erlang/OTP
RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    m4 \
    libncurses5-dev \
    libssl-dev \
    unixodbc-dev \
    libgmp-dev \
    libwxgtk3.2-dev \
    libsctp-dev \
    lksctp-tools \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install kerl (Erlang version manager)
RUN curl -L https://raw.githubusercontent.com/kerl/kerl/master/kerl -o /usr/local/bin/kerl \
    && chmod a+x /usr/local/bin/kerl

# Set up kerl and build requested Erlang versions
# We build them in /opt/erlang
WORKDIR /opt/erlang

# Build Erlang 26.x, 28.x, and 29.x
# Note: In a real environment, you might want to specify exact patch versions
RUN kerl update releases \
    && kerl build 26.2.5 26 \
    && kerl install 26 /opt/erlang/26 \
    && kerl build 28.0 28 \
    && kerl install 28 /opt/erlang/28 \
    && kerl build 29.0 29 \
    && kerl install 29 /opt/erlang/29 \
    && kerl cleanup all

# Create a helper script to switch versions easily
RUN echo '#!/bin/bash\n\
if [ -z "$1" ]; then\n\
  echo "Usage: switch-erlang [26|28|29]"\n\
  return 1\n\
fi\n\
case $1 in\n\
  26) source /opt/erlang/26/activate ;;\n\
  28) source /opt/erlang/28/activate ;;\n\
  29) source /opt/erlang/29/activate ;;\n\
  *) echo "Unknown version: $1. Supported: 26, 28, 29" ; return 1 ;;\n\
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
