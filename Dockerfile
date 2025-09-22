FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    cowsay \
    fortune-mod \
    fortunes-min \
    netcat-openbsd \
    socat \
 && rm -rf /var/lib/apt/lists/*

# Add /usr/games to PATH so cowsay & fortune can be found
ENV PATH="/usr/games:${PATH}"

WORKDIR /app
COPY wisecow.sh .
RUN chmod +x wisecow.sh

EXPOSE 4499
CMD ["./wisecow.sh"]



