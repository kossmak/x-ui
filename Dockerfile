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

ARG user=appuser
ARG userhome=/home/${user}
ARG appdir=/opt/app
ARG gid=5055
ARG uid=5055

#COPY --from=builder  /app/build/ /opt/app/
COPY --from=builder  /app/build/ ${appdir}/

# переопределяем в docker-compose.yml
ENV XUI_DB_FOLDER=${userhome}/etc/x-ui

# run container as unprivileged user
# https://pythonspeed.com/articles/root-capabilities-docker-security/
RUN addgroup app --gid $gid \
    && adduser -D -G app -h ${userhome} --uid ${uid} ${user} \
    && mkdir -p ${XUI_DB_FOLDER} \
    && chown ${user}:${gid} ${XUI_DB_FOLDER}


WORKDIR ${appdir}
#VOLUME [ "/etc/x-ui" ]
#CMD [ "./x-ui" ]

USER ${uid}
# определяем в docker-compose
#VOLUME [ "${XUI_DB_FOLDER}" ]
