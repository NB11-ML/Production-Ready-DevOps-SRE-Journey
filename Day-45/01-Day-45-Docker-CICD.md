
# Day 45: Docker Build & Push in GitHub Actions 🐳

Automating container builds and registry pushes is the cornerstone of a production CI/CD pipeline. This workflow guarantees that every code change merged into the main branch results in a deployable, versioned artifact shipped directly to Docker Hub.

## Task 1: Prepare
To build everything from scratch without relying on previous days, I created a minimal web application directly in the root of my repository.

**1. Create `index.html`:**
```html
<!DOCTYPE html>
<html>
<body>
    <h1>Automated Docker CI/CD Pipeline Active 🚀</h1>
</body>
</html>

```

**2. Create `Dockerfile`:**

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80

```

*Note: `DOCKER_USERNAME` (set to "docker-username" ) and `DOCKER_TOKEN` were previously configured in GitHub Settings -> Secrets.*

## Task 2 & 3 & 4: Build, Push, and Branch Conditions

I created a single CI/CD workflow at `.github/workflows/docker-publish.yml` that handles checkout, building, and conditionally pushing to the `devboard-fe-master` repository based on the branch name.

**Workflow Configuration:**

```yaml
name: Docker CI/CD Pipeline
on: 
  push:
    branches:
      - main
      - 'feature/*' 

jobs:
  build-and-publish:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Extract Short Commit SHA
        id: vars
        run: echo "sha_short=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT

      - name: Login to Docker Hub
        # Task 4: Only log in if we are on the main branch
        if: github.ref == 'refs/heads/main'
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Build and Conditionally Push Image
        uses: docker/build-push-action@v5
        with:
          context: .
          # Task 4: Push evaluates to 'true' only on main branch
          push: ${{ github.ref == 'refs/heads/main' }}
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/devboard-fe-master:latest
            ${{ secrets.DOCKER_USERNAME }}/devboard-fe-master:sha-${{ steps.vars.outputs.sha_short }}

```

<img width="1434" height="964" alt="image" src="https://github.com/user-attachments/assets/8102d379-2ea2-44ea-85f8-b86547c1e4b3" />

---

## Task 5: Add a Status Badge

I added the following status badge to the top of my repository's `README.md` to show the live pipeline health:
`[![Docker Pipeline](https://github.com/NB11-ML/git-actions/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/NB11-ML/git-actions/actions/workflows/docker-publish.yml)`

## Task 6: Pull and Run It (The Full Journey)

**What is the full journey from `git push` to a running container?**

1. **Code Commit:** A developer modifies the application and runs `git push origin main`.
2. **Webhook Trigger:** GitHub detects the push event and provisions an ephemeral Actions runner.
3. **Build & Authenticate:** The runner checks out the repository, compiles the image layer by layer using `docker build`, and securely injects `DOCKER_TOKEN` to authenticate with Docker Hub.
4. **Artifact Push:** The finished image is pushed to the public registry, tagged dynamically with both `latest` and a specific `sha-<hash>` under the `docker-user/devboard-fe-master` repository.
5. **Pull & Run:** A target server executes `docker pull docker-user/devboard-fe-master:latest` followed by `docker run -d -p 80:80 docker-user/devboard-fe-master:latest` to spin up the live application.

---

<img width="1466" height="388" alt="image" src="https://github.com/user-attachments/assets/00d7f263-74ae-4d63-8488-f6f25a3a978a" />

---
