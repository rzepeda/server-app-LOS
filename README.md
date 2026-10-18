# server-app-starter
an app saved on a server, updated via pipeline from server manager

# Guide: Forking and Deploying a New Application

Thanks to the automated CI/CD architecture running on your homeserver, deploying a new microservice is a fast, streamlined process. You don't need to touch the core server infrastructure; you simply fork the template, update the routing, and push your code.

Here is the step-by-step process to launch a new app (using `monthlybudget` as an example).

## Step 1: Fork the Starter Repository in GitHub
1. Go to your original `server-app-starter` repository on GitHub.
2. Click on **Use this template** (or **Fork**) to create a new repository.
3. Name your new repository (e.g., `monthlybudget`). 
4. **Crucial:** Ensure the new repository is set to **Private** so GitHub Actions can securely build and push the image to your private GHCR (GitHub Container Registry).

## Step 2: Clone the Repository to Your Server
Your Homeserver Deployment Manager constantly watches the `/server/apps` directory. You need to pull your new repository into this folder.

SSH into your server and run:
```bash
cd /server/apps
git clone https://github.com/rzepeda/monthlybudget.git
cd monthlybudget
```

## Step 3: Configure the Deployment Contract (`deploy.yml`)
The manager uses the `deploy.yml` file to know how to run your app. Open this file in your newly cloned repository and update the values to match your new app:

```yaml
version: 1
name: monthlybudget
image: ghcr.io/rzepeda/monthlybudget:main   # Update with your new repo name
container_name: srv-monthlybudget           # Unique container name
container_port: 8000

public:
  enabled: true
  subdomain: budget                         # This will create budget.agentictools.uk

database:
  postgres: true                            # Set to true if it needs the homeserver-data network
```

## Step 4: Configure App Secrets (Optional)
If your new application requires API keys, database credentials, or any private environment variables, **do not put them in your code**. Instead, use the secure secrets vault on your server.

1. Create a `.env` file in the secrets directory. **The filename must exactly match the folder name of your app** (e.g., `monthlybudget.env`).
   ```bash
   nano /server/secrets/monthlybudget.env
   ```
2. Add your private variables:
   ```env
   DATABASE_URL=postgres://user:password@postgres:5432/monthlybudget
   OPENAI_API_KEY=your_private_token_here
   ```
*The deployment manager will automatically inject these into your container at runtime.*

## Step 5: Add the Route to Cloudflare Tunnels
You need to tell Cloudflare to send traffic for your new subdomain to your Caddy proxy.

1. Go to your **Cloudflare Zero Trust Dashboard**.
2. Navigate to **Networks** -> **Tunnels** and select your active Caddy tunnel (e.g., `homeserver-caddy`).
3. Go to the **Public Hostname** tab and click **Add a public hostname**:
   * **Subdomain:** `budget` *(Must match what you put in `deploy.yml`)*
   * **Domain:** `agentictools.uk`
   * **Service Type:** `HTTP`
   * **URL:** `http://caddy-proxy:80` *(Make sure to include `http://` to prevent redirect loops)*
4. Click **Save hostname**.

## Step 6: Commit and Push (The Magic Step)
Now that the server is ready, trigger the automated pipeline by pushing your updated `deploy.yml` (and any new code) to GitHub.

You can do this from your local computer, Codespace, or the server itself:
```bash
git add deploy.yml
git commit -m "chore: setup deployment contract for monthlybudget"
git push origin main
```

### What happens next automatically?
1. **GitHub Actions** detects the push, compiles your Flutter/FastAPI code, and pushes a new Docker image to `ghcr.io/rzepeda/monthlybudget:main`.
2. Within 30 seconds, your **Homeserver Deployment Manager** reads the `deploy.yml`, pulls the fresh image, and starts `srv-monthlybudget`.
3. It securely mounts your secrets and connects the app to the database network.
4. It generates a new Caddy routing file for `budget.agentictools.uk`.
5. You can visit `https://budget.agentictools.uk` in your browser and see your new app live!