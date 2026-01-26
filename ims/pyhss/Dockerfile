FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive

# Bağımlılıkları kur (iptables dahil)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-pip python3-dev python3-setuptools python3-wheel \
        git pkg-config libsystemd-dev libmysqlclient-dev libsctp-dev \
        gcc mysql-server lsb-release curl gpg iptables \
    && rm -rf /var/lib/apt/lists/*

# Redis kurulumu (opsiyonel, eğer pod içinde çalışacaksa)
RUN curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends redis

# --- DEĞİŞİKLİK BURADA ---
# Dışarıdan clone yapmak yerine, bilgisayarındaki 'code' klasörünü imajın içine kopyalıyoruz
COPY code /pyhss

WORKDIR /pyhss

# Bağımlılıkları kur
RUN pip3 install -r requirements.txt
RUN mkdir -p /pyhss/log/

# Yapılandırma dosyalarını ve init scriptini kopyala
COPY config.yaml /pyhss/config.yaml
COPY pyhss_init.sh /usr/local/bin/pyhss_init.sh
RUN chmod +x /usr/local/bin/pyhss_init.sh

CMD ["/usr/local/bin/pyhss_init.sh"]
