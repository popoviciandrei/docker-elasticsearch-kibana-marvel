FROM openjdk:8-jre-alpine
LABEL author.name="Andrei Popovici" \
      author.email="me@andreipopovici.co.uk" \
      verison="1.0" \
      description="Fully working elasticsearch:2.4.6, kibana:4.6.3, marvel:2.4.5 so you can monitor your elastic search"

RUN addgroup -S elasticsearch && adduser -S -G elasticsearch elasticsearch

RUN apk add --no-cache supervisor openssl bash 'su-exec>=0.2'

ENV ELASTICSEARCH_VERSION 2.4.6
ENV KIBANA_VERSION 4.6.3
ENV ELASTICSEARCH_PATH /usr/share/elasticsearch
ENV KIBANA_PATH /usr/share/kibana

RUN cd /tmp && \
      wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ELASTICSEARCH_VERSION/elasticsearch-$ELASTICSEARCH_VERSION.tar.gz && \
      tar -xzf elasticsearch-$ELASTICSEARCH_VERSION.tar.gz && \
      rm -rf elasticsearch-$ELASTICSEARCH_VERSION.tar.gz && \
      mv /tmp/elasticsearch-$ELASTICSEARCH_VERSION $ELASTICSEARCH_PATH && \
      echo "http.host: 0.0.0.0" >> $ELASTICSEARCH_PATH/config/elasticsearch.yml && \
      chown -R elasticsearch:elasticsearch $ELASTICSEARCH_PATH


WORKDIR $ELASTICSEARCH_PATH

RUN bin/elasticsearch --version
RUN mkdir $ELASTICSEARCH_PATH/data && \
    chown -R elasticsearch:elasticsearch $ELASTICSEARCH_PATH/data

RUN \
  apk add --update --repository http://dl-3.alpinelinux.org/alpine/edge/main/ --allow-untrusted nodejs &&\
  cd /tmp && \
  wget https://download.elastic.co/kibana/kibana/kibana-$KIBANA_VERSION-linux-x86_64.tar.gz

RUN cd /tmp && \
    tar -xzf kibana-$KIBANA_VERSION-linux-x86_64.tar.gz && \
    rm -rf kibana-$KIBANA_VERSION-linux-x86_64.tar.gz && \
    mv kibana-$KIBANA_VERSION-linux-x86_64 $KIBANA_PATH && \
    rm -rf $KIBANA_PATH/node && \
    mkdir -p $KIBANA_PATH/node/bin && \
    ln -sf /usr/bin/node $KIBANA_PATH/node/bin/node && \
    sed -ri "s!^(\#\s*)?(server\.host:).*!\2 '0.0.0.0'!" $KIBANA_PATH/config/kibana.yml

WORKDIR $ELASTICSEARCH_PATH
RUN bin/plugin install license
RUN bin/plugin install -b marvel-agent

WORKDIR $KIBANA_PATH
RUN bin/kibana plugin --install elasticsearch/marvel/2.4.5

COPY supervisord.conf /etc/supervisord.conf
VOLUME $ELASTICSEARCH_PATH/data


EXPOSE 9200 9300 5601

CMD ["/usr/bin/supervisord"]