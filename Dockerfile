FROM lucasbasquerotto/ansible:0.0.2

WORKDIR /root/ansible-manager

COPY setup/image.sh /tmp/
COPY env/ /tmp/env/

RUN chmod +x /tmp/image.sh \
 && /tmp/image.sh \
 && rm /tmp/image.sh