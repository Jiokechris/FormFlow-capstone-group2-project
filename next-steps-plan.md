# FormFlow — What's Left To Do (Plain-English Plan)

Think of the whole project like shipping a food truck: build the truck (containers), pick a
parking spot (server), then set up a system so new food (code changes) gets delivered
automatically without you driving it there by hand every time.

## Where you already are

| # | Task | Status | Notes |
|---|------|--------|-------|
| 3 | Dockerfiles for frontend & backend | ✅ Done | Already in `frontend/Dockerfile` and `backend/Dockerfile` |
| 4 | `docker-compose.yml` running all 3 services | ✅ Done | frontend + backend + db, tested locally, all healthy |
| 6 | Provision a Linux VM | ✅ Mostly done | Terraform already builds an EC2 instance + load balancer (`terraform/`) — this **is** your Linux VM in AWS |
| 5 | Push versioned images to Docker Hub | ❌ Not done yet | You've only built locally so far |
| 7 | GitHub Actions pipeline (build → push → deploy via SSH) | ❌ Not done yet | No `.github/workflows/` folder exists yet |
| — | Tested, screenshotted rollback | ❌ Not done yet | Can't do this until the pipeline exists |

**Translation: the "build a truck" part is basically finished. The "deliver food automatically" part hasn't started.**

---

## What each remaining piece actually means

### 5. Versioned Docker Hub pushes ("no bare `latest`") — ✅ DECIDED

Right now if you push an image tagged `latest`, nobody can tell *which* version of your code
is actually running — it's like labeling every delivery box "stuff," then wondering later which
box has the thing you need.

**Decision: tag every image twice — with a human version AND the exact git commit.**

- `yourname/formflow-backend:v1.0.3` — the human-readable release number
- `yourname/formflow-backend:a1b2c3d` — the exact git commit it was built from (short SHA)
- `latest` can still exist too, as a convenience pointer, but never as the *only* tag

**Where `v1.0.3` comes from: git tags — not a file you edit by hand.**
When you're ready to cut a release, you run:
```
git tag v1.0.3
git push origin v1.0.3
```
That push is what triggers GitHub Actions to build, tag, and deploy that exact version. No
file in the repo to remember to bump — the version lives in git's tag history, which also
means "what's deployed right now" and "what tag is that" are always the same question.

Rule going forward: **every deploy corresponds to exactly one git tag.** No tag, no deploy.

### 6. Linux VM, exposed to the internet
You already have this via Terraform (EC2 instance behind a load balancer). What's left is
making sure:
- The security group opens the right ports (80/443, and SSH port 22 only from your IP)
- The VM actually has Docker installed and running on boot

### 7. GitHub Actions CI/CD pipeline
This is the biggest missing piece. In plain terms, every time you push code to `main`, a robot
should automatically:
1. Build the frontend and backend Docker images
2. Tag them with a version (see #5)
3. Push them to Docker Hub
4. SSH into your VM
5. Pull the new images and restart the containers (`docker compose pull && docker compose up -d`)

You write this once as a `.github/workflows/deploy.yml` file, and GitHub runs it for you on
every push — no manual `docker push` or SSH-ing in by hand ever again.

### Rollback procedure (mandatory, must be *proven*, not just written)
"Rollback" = if a new deploy breaks something, you go back to the last known-good version fast.

Because you're using versioned tags (#5), rollback is simple in concept:
> Re-run the deploy step but point it at the *previous* version tag instead of the new one.

But the assignment wants proof, not just a promise. That means:
1. Deploy version A (working)
2. Deploy version B (pretend it's broken, or actually break something small on purpose)
3. Roll back to version A using your documented steps
4. **Screenshot each step** (the broken state, the rollback command, the working state after)
5. Write the steps down in a short `ROLLBACK.md` so someone else could repeat it

---

## Suggested build order (so nothing blocks something else)

1. Decide on the version-tagging scheme (e.g. semantic version `v1.0.0`, or git short SHA)
2. Manually build + push both images once to Docker Hub using that scheme — confirms Docker Hub
   credentials and tagging work before automating it
3. Confirm the VM (Terraform EC2) can pull those images and run `docker compose up -d` by hand over SSH
4. Write the GitHub Actions workflow to automate steps 2–3
5. Do one real deploy through the pipeline (not by hand) to prove it works end-to-end
6. Perform and screenshot the rollback drill
7. Write `ROLLBACK.md` describing exactly what you did

---

## One thing to flag back to whoever wrote the worksheet (Phase 0 divergence note)

Your Terraform already provisions an ALB (load balancer) in front of the EC2 instance, which is
more infrastructure than "a Linux VM" strictly requires. That's fine — just add a one-line note
in your write-up like: *"We provisioned an ALB in addition to the bare VM for cleaner external
exposure and future scalability; this exceeds the minimum requirement but doesn't diverge from
its intent."*
