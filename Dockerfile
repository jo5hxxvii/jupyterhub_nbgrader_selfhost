FROM quay.io/jupyterhub/jupyterhub:5
RUN pip install --no-cache-dir jupyterlab notebook \
    jupyterhub-nativeauthenticator nbgrader
RUN useradd -m -s /bin/bash instructor \
 && mkdir -p /srv/nbgrader/exchange /srv/jupyterhub \
 && chmod 777 /srv/nbgrader/exchange
COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py
COPY nbgrader_config.py /etc/jupyter/nbgrader_config.py
WORKDIR /srv/jupyterhub
CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]