FROM debian:stable-slim
COPY build.sh .
RUN ./build.sh 18.06.6
