FROM debian:bookworm-slim
LABEL maintainer="Odoo S.A. <info@odoo.com>"

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG=C.UTF-8

# Install dependencies and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      dirmngr \
      fonts-noto-cjk \
      gnupg \
      libssl-dev \
      node-less \
      npm \
      python3-num2words \
      python3-pdfminer \
      python3-pip \
      python3-psycopg2 \
      python3-phonenumbers \
      python3-qrcode \
      python3-setuptools \
      python3-slugify \
      python3-vobject \
      python3-watchdog \
      python3-xlrd \
      python3-xlwt \
      xz-utils \
      nano \
      git \
      wkhtmltopdf && \
    rm -rf /var/lib/apt/lists/*

# install latest postgresql-client (PGDG for bookworm)
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main' > /etc/apt/sources.list.d/pgdg.list && \
    GNUPGHOME="$(mktemp -d)" && export GNUPGHOME && \
    repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' && \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" && \
    gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc && \
    gpgconf --kill all && rm -rf "$GNUPGHOME" && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client && \
    rm -f /etc/apt/sources.list.d/pgdg.list && \
    rm -rf /var/lib/apt/lists/*

# Install rtlcss
RUN npm install -g rtlcss

# Install Odoo
ENV ODOO_VERSION=18.0
ARG ODOO_RELEASE=latest
ARG ODOO_SHA=
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/18.0/nightly/deb/odoo_18.0.latest_all.deb && \
    apt-get update && \
    apt-get -y install --no-install-recommends ./odoo.deb && \
    rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /entrypoint.sh
COPY ./odoo.conf /etc/odoo/odoo.conf
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set permissions and create addon mount points
RUN chown odoo /etc/odoo/odoo.conf && \
    mkdir -p /mnt/extra-addons && \
    chown -R odoo /mnt/extra-addons && \
    chmod +x /entrypoint.sh

VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Install pycups via apt to avoid PEP 668 pip issues
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3-cups && \
    rm -rf /var/lib/apt/lists/*

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]