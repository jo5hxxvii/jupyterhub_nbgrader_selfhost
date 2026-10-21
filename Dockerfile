FROM quay.io/jupyterhub/jupyterhub:5
RUN pip install --no-cache-dir jupyterlab notebook \
    jupyterhub-nativeauthenticator nbgrader
RUN pip install --no-cache-dir pandas numpy matplotlib seaborn scipy \
    scikit-learn openpyxl requests
RUN mkdir -p /srv/nbgrader/exchange /srv/jupyterhub /etc/jupyterhub
COPY jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py
COPY nbgrader_config.py /etc/jupyter/nbgrader_config.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
WORKDIR /srv/jupyterhub
CMD ["/entrypoint.sh"]