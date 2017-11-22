FROM centos:7

# Install requirements
RUN yum -y install epel-release
RUN yum -y install postgresql postgresql-contrib postgresql-devel postgis
RUN yum -y install gcc gcc-c++ make git gdal geos
RUN yum -y install libxml2 libxml2-devel libxslt libxslt-devel
RUN yum -y install gdal-python python-pip python-imaging python-virtualenv \
            libxml2-python libxslt-python python-lxml \
            python-devel python-babel python-psycopg2 \
            python-pylons python-repoze-who python-repoze-who-plugins-sa \
            python-repoze-who-testutil python-repoze-who-friendlyform \
            python-tempita python-zope-interface policycoreutils-python

# Set Env Vars
ENV CKAN_HOME="/usr/lib/ckan"
ENV CKAN_CONFIG="/etc/ckan"
ENV CKAN_STORAGE_PATH "/var/lib/ckan"

# Build time argument
ARG CKAN_SITE_URL="http://localhost:5000"
ARG CKAN_GIT_REPO="https://github.com/ckan/ckan.git"
ARG CKAN_GIT_CHECKOUT="tags/ckan-2.7.2"

# Add 'ckan' user
RUN useradd -m -s /sbin/nologin -d "${CKAN_HOME}" -c "CKAN User" ckan

# Create CKAN directories and set permissions
RUN mkdir -p "${CKAN_HOME}" "${CKAN_CONFIG}" "${CKAN_STORAGE_PATH}"
RUN chown ckan:ckan "${CKAN_HOME}" \
	&& chown ckan:ckan "${CKAN_CONFIG}" \
	&& chown ckan:ckan "${CKAN_STORAGE_PATH}"

RUN chmod 755 "${CKAN_HOME}" \
	&& chmod 755 "${CKAN_CONFIG}" \
	&& chmod 755 "${CKAN_STORAGE_PATH}"

RUN pip install --upgrade pip
WORKDIR "${CKAN_HOME}"

# Get CKAN code
RUN git clone "${CKAN_GIT_REPO}"
WORKDIR "${CKAN_HOME}/ckan"
RUN git checkout "${CKAN_GIT_CHECKOUT}"

# Temporary fix for dependencies
RUN pip install pytz

# Install requirements
RUN pip install -r "${CKAN_HOME}/ckan/requirement-setuptools.txt"
RUN pip install -r "${CKAN_HOME}/ckan/requirements.txt"

# Install CKAN
RUN pip install -e . #egg=ckan

# Configure CKAN
RUN ln -s "${CKAN_HOME}/ckan/config/who.ini" "${CKAN_CONFIG}/who.ini"

WORKDIR "${CKAN_HOME}"

ADD ckan-entrypoint.sh /ckan-entrypoint.sh
RUN chmod +x /ckan-entrypoint.sh

ENTRYPOINT ["/ckan-entrypoint.sh"]

USER ckan
EXPOSE 5000

CMD ["paster","serve","${CKAN_CONFIG}/ckan.ini"]
