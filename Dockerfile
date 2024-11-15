FROM rust:1.82-bookworm

# Add repository for dotnet
RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb

# Install dependencies (including ones to build Renode)
RUN apt-get -y update && apt-get -y install \
    gdb-multiarch binutils-arm-none-eabi zsh \
    dotnet-sdk-8.0 \
    git automake cmake autoconf libtool g++ coreutils policykit-1 \
    uml-utilities gtk-sharp3 python3 python3-pip

# Fix git issues with the container running as root
RUN git config --global --add safe.directory '*'

# Install Oh My Zsh for convenience
RUN chsh -s $(which zsh)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

# Install convenient Rust utilities
RUN curl -LsSf https://get.nexte.st/latest/linux | tar zxf - -C ${CARGO_HOME:-~/.cargo}/bin
RUN rustup component add clippy

# Install probe-rs to flash and debug our MCU
RUN curl --proto '=https' --tlsv1.2 -LsSf https://github.com/probe-rs/probe-rs/releases/latest/download/probe-rs-tools-installer.sh | sh
RUN mkdir -p /root/.zfunc
RUN probe-rs complete --shell zsh install

# Compile Renode from source
RUN git clone https://github.com/renode/renode.git
RUN cd renode && ./build.sh --net
ENV PATH="$PATH:/renode"

# Install renode-test dependencies
RUN pip install --break-system-packages -r /renode/tests/requirements.txt

# Set the default shell to Zsh
CMD ["zsh"]