# syntax=docker/dockerfile:1.7
FROM debian:bookworm-slim AS nvchad-base

ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG GIT_AUTHOR_EMAIL
ARG GIT_AUTHOR_NAME

USER root

ENV NVIM_VERSION=v0.11.2
RUN apt-get update && apt-get install -y \
    git \
    wget \
    build-essential \
    zsh \
    curl \
    fd-find \
    ripgrep && \
    wget https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz && \
    tar xzf nvim-linux-x86_64.tar.gz && \
    mv nvim-linux-x86_64 /opt/nvim && \
    ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim && \
    rm nvim-linux-x86_64.tar.gz && \
    rm -rf /var/lib/apt/lists/*

# Create user and group
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m -s /usr/bin/zsh $USERNAME

ENV HOME=/home/$USERNAME

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Install Oh My Zsh for the user
# RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Set up NVChad (default config, untouched)
RUN git clone https://github.com/NvChad/starter /home/$USERNAME/.config/nvim

# Configure git if build args are provided
RUN <<EOF
if [ -n "$GIT_AUTHOR_EMAIL" ] && [ -n "$GIT_AUTHOR_NAME" ]; then
   git config --global user.email "$GIT_AUTHOR_EMAIL"
   git config --global user.name "$GIT_AUTHOR_NAME"
fi
EOF

# Set default shell to zsh and add pyenv to PATH by default
SHELL ["/usr/bin/zsh", "-c"]

CMD ["zsh"]

# --- PYTHON STAGE ---
FROM nvchad-base AS python-dev

USER root
RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

# Ensure the app directory exists and is owned by $USERNAME
RUN mkdir -p /home/$USERNAME/app && chown -R $USERNAME:$USERNAME /home/$USERNAME/app

USER $USERNAME
WORKDIR /home/$USERNAME/app

RUN python3 -m venv /home/$USERNAME/app/.venv
ENV PATH="/home/$USERNAME/app/.venv/bin:$PATH"

COPY --chown=$USERNAME:$USERNAME ./dev_envs/python/base/requirements.txt ./
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# --- RUST STAGE ---
FROM nvchad-base AS rust-dev

USER $USERNAME
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}"

# --- C++ STAGE ---
FROM nvchad-base AS cpp-dev

USER root
RUN apt-get update && apt-get install -y g++ cmake make && rm -rf /var/lib/apt/lists/*
USER $USERNAME
