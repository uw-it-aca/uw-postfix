FROM ubuntu:18.04 as uw-postfix

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get clean all && \
    apt-get install -y postfix

RUN mkdir /config && \
    mv /etc/postfix/main.cf /config/main.cf && \
    mv /etc/postfix/master.cf /config/master.cf && \
    ln -s /config/main.cf /etc/postfix/main.cf && \
    ln -s /config/master.cf /etc/postfix/master.cf && \
    mkdir /certs

ADD scripts /scripts

RUN chmod -R +x /scripts

CMD ["/scripts/start.sh"]
