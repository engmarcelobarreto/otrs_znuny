FROM debian:11-slim

ARG ZNUNY_VERSION
ENV DEBIAN_FRONTEND=noninteractive

# Instalação de pacotes (sem mudanças)
RUN apt-get update && apt-get install -y --no-install-recommends \
    procps wget apache2 libapache2-mod-perl2 cron libjson-xs-perl \
    libxml-libxml-perl libxml-libxslt-perl libyaml-libyaml-perl \
    libcrypt-eksblowfish-perl libencode-hanextra-perl libmail-imapclient-perl \
    libtemplate-perl libpackage-stash-perl libarchive-zip-perl \
    libauthen-sasl-perl libdata-uuid-perl libdatetime-perl \
    libhash-merge-perl libical-parser-perl libmoo-perl \
    libnet-dns-perl libtext-csv-xs-perl libxml-parser-perl \
    libnet-ldap-perl libspreadsheet-xlsx-perl libdbd-mysql-perl \
    && rm -rf /var/lib/apt/lists/*

# Download e instalação do Znuny (sem mudanças)
RUN wget https://download.znuny.org/releases/znuny-${ZNUNY_VERSION}.tar.gz -O /tmp/znuny.tar.gz \
    && tar -xzf /tmp/znuny.tar.gz -C /opt \
    && mv /opt/znuny-* /opt/znuny \
    && rm /tmp/znuny.tar.gz

# Configuração de usuário e permissões (sem mudanças)
RUN useradd -d /opt/znuny -c 'Znuny user' znuny \
    && usermod -g www-data znuny \
    && cd /opt/znuny \
    && cp Kernel/Config.pm.dist Kernel/Config.pm \
    && chown -R znuny:www-data /opt/znuny \
    && chmod -R ug+rw /opt/znuny \
    && /opt/znuny/bin/znuny.CheckModules.pl

# --- MUDANÇA PRINCIPAL AQUI ---
# Copia nossa configuração customizada do Apache para dentro da imagem
COPY znuny-apache.conf /opt/znuny/scripts/apache2-httpd.include.conf

# Configuração do Apache (agora usa o nosso arquivo)
RUN ln -s /opt/znuny/scripts/apache2-httpd.include.conf /etc/apache2/conf-available/znuny.conf \
    && a2enmod perl && a2enmod deflate && a2enmod filter && a2enmod headers \
    && a2enconf znuny

# Script de inicialização (sem mudanças)
COPY <<'EOF' /opt/znuny_starter.sh
#!/bin/bash
set -e
rm -f /var/run/apache2/apache2.pid
su -c "/opt/znuny/bin/Cron.sh start" -s /bin/bash znuny
su -c "/opt/znuny/bin/znuny.Daemon.pl start" -s /bin/bash znuny
exec /usr/sbin/apache2ctl -D FOREGROUND
EOF
RUN chmod +x /opt/znuny_starter.sh

EXPOSE 80

CMD ["/opt/znuny_starter.sh"]