FROM debian:stable-slim
COPY .config-apu2 .config-apu2-sub .config-init build_source.sh config-kernel-apu2 PACKAGES ./
RUN ./build_source.sh 19.07.1 -j6
