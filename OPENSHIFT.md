# OpenShift Deployment Guide

This repository has been updated to support deployment on OpenShift clusters.

## What changed
1. **Next.js Standalone Mode:** Updated `apps/editor/next.config.ts` to output a `standalone` build. This significantly reduces the size of the Docker image.
2. **Dockerfile:** Added a multi-stage Dockerfile that:
   - Uses `oven/bun` to install dependencies and build the application.
   - Uses a minimal `node:20-alpine` image to run the standalone app.
   - Configures the required OpenShift security context (assigning group `0` and giving it group-write `g=u` permissions to directories where the app runs). This allows the container to run under an arbitrary UID assigned by OpenShift.
3. **.dockerignore:** Keeps out unnecessary files.

## How to deploy on OpenShift

### Option 1: Using the OpenShift Web Console
1. In the **Developer** perspective, click **+Add**.
2. Select **Import from Git**.
3. Paste the URL of your repository: `https://github.com/hartripley/editor.git` (ensure it points to your branch with the Dockerfile).
4. Under **Builder Image**, OpenShift should automatically detect the `Dockerfile`.
5. Under **General**, set the Application name and Name.
6. Under **Resources**, select **Deployment** or **Serverless Deployment**.
7. Keep **Create a route to the application** checked so you can access the app from the web.
8. Click **Create**.

OpenShift will build the image via a BuildConfig and then deploy it.

### Option 2: Using the `oc` CLI
You can trigger a build and deployment directly from your terminal if you are logged in to your cluster:

```bash
# Create a new app using the Git repository
oc new-app https://github.com/hartripley/editor.git#openshift-deployment --name=pascal-editor

# Expose the service to create a route
oc expose svc/pascal-editor
```

## Testing Locally
If you want to test the Docker image locally before deploying to OpenShift, you can use Docker or Podman:

```bash
docker build -t pascal-editor:latest .
docker run -p 3000:3000 -u 1001230000 pascal-editor:latest
```
*(The `-u` flag simulates OpenShift's arbitrary user ID assignment).*
