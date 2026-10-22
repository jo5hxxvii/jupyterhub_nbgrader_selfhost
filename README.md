# Python Assessments on JupyterHub

This repo runs a JupyterHub server with nbgrader. Learners sign up, open a notebook, solve Python assessments and submit them. nbgrader marks the work for you.


## What is in this repo

| File | What it does |
|---|---|
| `Dockerfile` | Builds the image with JupyterHub, JupyterLab, NativeAuthenticator and nbgrader |
| `jupyterhub_config.py` | Login rules, admin user, username pattern, server settings |
| `nbgrader_config.py` | Shared nbgrader settings (exchange folder and course name) |
| `entrypoint.sh` | Starts the Hub and recreates Linux users from the saved home folders after every redeploy |
| `docker-compose.yml` | Only used if you deploy as a Compose service. A Dokploy Application ignores it |

Optional: keep your teacher notebooks in an `assignments/` folder, for example `assignments/control_statements/control_statements.ipynb`.

## How it works

1. A learner signs up with their student ID as the username.
2. The admin approves the learner.
3. The learner opens JupyterLab, fetches an assignment, solves it and submits it.
4. The admin collects the submissions, runs autograde, then releases feedback.

## Deploy on Dokploy

Create the data folders on the VPS first. Run this on the VPS itself, not in the container:

```bash
mkdir -p /opt/jhub/hub_data /opt/jhub/home /opt/jhub/exchange
chmod 777 /opt/jhub/exchange
```

Then in Dokploy:

1. Create an **Application** from this repo. Build type is **Dockerfile**.
2. Under **Advanced > Volumes**, add three **Bind Mounts**:

| Host path | Mount path in the container |
|---|---|
| `/opt/jhub/hub_data` | `/srv/jupyterhub` |
| `/opt/jhub/home` | `/home` |
| `/opt/jhub/exchange` | `/srv/nbgrader/exchange` |

3. Under **Domains**, add your address, for example `203-0-113-10.sslip.io`. Use container port `8000`, turn on HTTPS and pick Let's Encrypt. Ports 80 and 443 must be open in the Contabo firewall.
4. Click **Deploy** and wait for "JupyterHub is now running" in the logs.

The bind mounts are what keep accounts and files safe. Without them, every redeploy wipes everything.

To check that the mounts are in place:

```bash
docker inspect $(docker ps -q --filter name=jupyterhub) --format '{{json .Mounts}}'
```

You should see three entries with `"Type":"bind"`.

## First time setup

1. Open the site, click **Sign up** and create the user `admin`. Admin is approved automatically.
2. Open the Dokploy terminal for the service and run:

```bash
mkdir -p /home/admin/.jupyter /home/admin/course
cat > /home/admin/.jupyter/nbgrader_config.py <<'EOF'
c = get_config()
c.CourseDirectory.root = "/home/admin/course"
EOF
chown -R admin:admin /home/admin
```

3. In the Hub, stop your server and start it again. The **Formgrader** tab should appear.

## Username rule

Learners must sign up with their student ID, for example `ALT_SOD_TIN_025_0120`. The Hub turns it into lowercase. The rule is set in `jupyterhub_config.py`:

```python
c.Authenticator.username_pattern = r"^(?=.{1,32}$)(?i:admin|alt(_[a-z0-9]+){4})$"
```

It accepts `admin`, or `alt` followed by exactly 4 groups that start with an underscore. Any other username is rejected. If the ID format changes, edit this line, push and redeploy.

## Add learners

1. Learners sign up. You approve them at `/hub/authorize`.
2. Register them in nbgrader. The ID must match the Hub username in lowercase. Save a file called `students.csv` in `/home/admin/course`:

```csv
id,first_name,last_name,email
alt_sod_tin_025_0120,Ada,Obi,ada@example.com
alt_soe_kar_026_0120,Tunde,Bello,tunde@example.com
```

Then run:

```bash
cd /home/admin/course
nbgrader db student import students.csv
```

Run it again any time to add new rows.

## Run an assessment

1. In Formgrader, go to **Manage Assignments** and add a new assignment. The name must match the notebook name.
2. Upload the teacher notebook into `/home/admin/course/source/<assignment_name>/`.
3. Click **Generate**. This removes the answers and the hidden tests for learners.
4. Click **Release**.
5. Learners fetch it from the **Assignments** tab, solve it and submit.
6. Collect the submissions, then click **Autograde**.
7. Click **Generate Feedback** and **Release Feedback**. Learners click **Fetch Feedback**, then open the feedback file from their file browser.

Never release the teacher notebook directly. Always go through **Generate**.

## Writing tests that learners cannot see

Put the real checks inside hidden markers in the test cell:

```python
assert "total" in dir(), "Make sure you created the variable total"
### BEGIN HIDDEN TESTS
assert total == 325
### END HIDDEN TESTS
```

Learners only see the first line. The hidden line runs when you autograde. Hidden tests do not stop someone typing the answer directly, so read a few submissions after autograde.

## Update the server

Change the files, push to GitHub and click **Deploy**. Accounts, files and submissions stay because they live in `/opt/jhub` on the VPS.

## Back up

```bash
tar czf ~/jhub-backup-$(date +%F-%H%M).tar.gz /opt/jhub
```

Do this before every big change. To restore, stop the service, extract the archive back to `/` and deploy again.

## Reset a learner password

NativeAuthenticator has no email reset. Run this in the container terminal and give the learner the temporary password:

```bash
python - <<'EOF'
import sqlite3, bcrypt
h = bcrypt.hashpw(b"TEMP_PASSWORD", bcrypt.gensalt())
con = sqlite3.connect("/srv/jupyterhub/hub.sqlite")
con.execute("update users_info set password=? where username='alt_sod_tin_025_0120'", (h,))
con.commit()
EOF
```

## Common problems

| Problem | Fix |
|---|---|
| Bad gateway | Check the logs. A crash on startup is the usual cause. Wait a minute after a deploy |
| `username 'x' is not valid` in the logs | The username does not match `username_pattern`. Update the pattern or the admin name |
| Accounts or files gone after a deploy | The bind mounts are missing. Check them with the `docker inspect` command above |
| Learner sees nothing under Assignments | Release the assignment in Formgrader, then restart the learner's server |
| Submission not visible to admin | Click **Collect** in Formgrader first |
| Permission error for a learner | Run `chown -R USERNAME:USERNAME /home/USERNAME` in the container terminal |
| `View Feedback` cannot be clicked | Open `assignment/feedback/<time>/<notebook>.html` from the file browser using **Open in New Browser Tab** |

## Do not

* Do not use any option in Dokploy that deletes volumes or data.
* Do not run `docker compose down -v`.
* Do not let real learners sign up before you have tested a redeploy with a dummy user.