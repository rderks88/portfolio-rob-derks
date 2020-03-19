FROM nginx

RUN apt-get update

RUN apt-get install -y openssl

RUN mkdir /opt/tls

ADD docker-nginx-entrypoint.sh /opt/docker-nginx-entrypoint.sh
RUN chmod a+x /opt/docker-nginx-entrypoint.sh

ADD rootCA.cnf /opt/tls/rootCA.cnf
ADD server.csr.cnf /opt/tls/server.csr.cnf
ADD v3.ext /opt/tls/v3.ext

ADD nginx.conf /etc/nginx/conf.d/default.conf

ENTRYPOINT ["/opt/docker-nginx-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
