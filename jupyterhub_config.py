import os, nativeauthenticator
from nativeauthenticator import NativeAuthenticator
from jupyterhub.auth import LocalAuthenticator

class LocalNativeAuthenticator(NativeAuthenticator, LocalAuthenticator):
    pass

c.JupyterHub.authenticator_class = LocalNativeAuthenticator
c.JupyterHub.template_paths = [
    f"{os.path.dirname(nativeauthenticator.__file__)}/templates/"]
c.Authenticator.admin_users = {"admin"}
c.Authenticator.allow_all = True   # Native still needs your approval per user
c.LocalAuthenticator.create_system_users = True
c.NativeAuthenticator.open_signup = False
c.Spawner.default_url = "/lab"
c.Spawner.start_timeout = 120
c.JupyterHub.bind_url = "http://0.0.0.0:8000"
c.JupyterHub.cookie_secret_file = "/srv/jupyterhub/cookie_secret"
c.JupyterHub.db_url = "sqlite:////srv/jupyterhub/hub.sqlite"