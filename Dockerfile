FROM golang:1.25-alpine AS builder
WORKDIR /app
ARG TARGETARCH 
RUN apk --no-cache --update add build-base gcc wget unzip
COPY . .
ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"
RUN go build -ldflags "-w -s" -o build/x-ui main.go
RUN ./DockerInitFiles.sh "$TARGETARCH"

FROM alpine
LABEL org.opencontainers.image.authors="alireza7@gmail.com,kossmak@gmail.com"
ENV TZ=Asia/Tehran

RUN apk add ca-certificates tzdata

ARG user=app
ARG userhome=/home/${user}
ARG appdir=/opt/app
ARG gid=5055
ARG uid=5055

# Копируем бинарник
COPY --from=builder /app/build/ ${appdir}/

# Создаем пользователя и директории
RUN addgroup ${user} --gid ${gid} \
    && adduser -D -G ${user} -h ${userhome} --uid ${uid} ${user} \
    && mkdir -p ${userhome}/etc/x-ui ${userhome}/cert \
    && chown -R ${uid}:${gid} ${userhome} ${appdir}\
    && mkdir -p ${userhome}/cert \
    && chown -R ${uid}:${gid} ${userhome}/cert \
    && ln -sf ${userhome}/cert /root/cert

# Устанавливаем переменные окружения
ENV XUI_DB_FOLDER=${userhome}/etc/x-ui

WORKDIR ${appdir}

# непривилегированный пользователь - мастхэв для секьюрности
USER ${uid}
# CMD теперь в docker-compose (вроде меньше на один слой)
