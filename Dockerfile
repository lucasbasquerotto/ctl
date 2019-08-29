ARG CTL_IMAGE
ARG CTL_VERSION

FROM $CTL_IMAGE:$CTL_VERSION

WORKDIR /root/ctl

COPY setup/image.sh /tmp/
COPY env/ /tmp/env/

RUN chmod +x /tmp/image.sh \
 && /tmp/image.sh \
 && rm /tmp/image.sh