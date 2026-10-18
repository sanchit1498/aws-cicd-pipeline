# aws-cicd-pipeline

This is the third project in my cloud portfolio. The second one was a three-tier setup on AWS (VPC, EC2, RDS) written in Terraform. Here I kept that Terraform and put a pipeline around it, so that nobody has to run `terraform apply` from a laptop anymore.

A push or pull request runs checks. A pull request that touches Terraform also gets a plan posted as a comment. After a merge, the deploy waits for me to click Approve in GitHub, then builds everything in AWS. GitHub logs in to AWS with short-lived credentials (OIDC), so there are no AWS keys stored anywhere.

The app is small on purpose: a Flask product catalog that reads five rows from MySQL on RDS, with nginx in front. The pipeline is the point.

```mermaid
flowchart LR
    A[Push branch] --> B[Open pull request]
    B --> C[CI: lint, tests, terraform validate, Checkov, pip-audit]
    B --> D[terraform plan posted as PR comment]
    C --> E[Merge to main]
    D --> E
    E --> F{Approve in GitHub<br/>environment: production}
    F --> G[terraform apply<br/>deploy role via OIDC]
    G --> H[VPC + EC2 + RDS in us-east-2]
```

## Layout

```
app/                  Flask app
tests/                pytest (just the /health route)
terraform/            root config and modules: vpc, security, ec2, rds
.github/workflows/
    ci.yml            lint, tests, terraform checks, security scans
    terraform-plan.yml   plan on pull requests
    deploy.yml        approval-gated apply / destroy
    aws-test.yml      manual "who am I" check for the OIDC login
```

## What runs when

**On every push to main and every pull request (`ci.yml`)**

- flake8 and pytest on the Python side.
- `terraform fmt -check`, `terraform init -backend=false` and `terraform validate`.
- Checkov on the Terraform and pip-audit on `requirements.txt`. Checkov is set to report without failing the build, for reasons I explain further down. pip-audit does fail the build if it finds a known vulnerable package.

![CI run, all green](screenshots/ci-green.png)

**On pull requests that touch `terraform/**` (`terraform-plan.yml`)**

It logs in to AWS with a read-only role, runs `terraform plan` against the real state in S3, and posts the result on the PR. I read that comment before merging. For the full stack it said 13 to add, 0 to change, 0 to destroy.

![Plan comment and passing checks on a pull request](screenshots/pr-plan-checks.png)

**On merge to main, or by hand (`deploy.yml`)**

The workflow starts, then stops at the `production` environment, which has me as the required reviewer. Nothing is created until I approve. After that it assumes a separate deploy role and runs `terraform apply`. The same workflow has a dropdown on its Run workflow button with `apply` or `destroy`, which is how I tear everything down afterwards. A concurrency group makes sure two runs never touch the state at the same time.

![Approval prompt on the production environment](screenshots/approval-gate.png)

When I later changed the app's startup script, the plan comment showed exactly what I expected: one resource added and one destroyed (the EC2 instance being replaced), and nothing else touched.

![Plan for the app change: 1 to add, 1 to destroy (old IP covered)](screenshots/pr-ec2-replace-plan.png)

The first full deploy took 5 minutes 33 seconds, and most of that was RDS (about 5 minutes on its own).

![Deploy job, all steps green](screenshots/deploy-run-green.png)

![Apply complete, 13 added](screenshots/apply-complete.png)

## Logging in to AWS without keys

GitHub Actions can ask GitHub for a signed token that says which repo and which run it is. AWS has an identity provider for `token.actions.githubusercontent.com` and checks that token against the trust policy of an IAM role. If it matches, the job gets credentials that expire in about an hour.

I use two roles:

- `github-actions-cicd-role` has `ReadOnlyAccess` plus read/write on the Terraform state bucket. Its trust policy accepts runs from the main branch and from pull requests. This is what the plan job uses.
- `github-actions-deploy-role` can create and delete EC2 and RDS resources, only in us-east-2, plus the state bucket. Its trust policy accepts only runs that went through the `production` environment, so it can't be used without my approval.

![Trust policy of the read-only role (account ID covered)](screenshots/trust-policy.png)

![Output of aws sts get-caller-identity from a workflow run](screenshots/oidc-whoami.png)

## State and secrets

Terraform state lives in an S3 bucket with encryption on, and locking uses the S3 lockfile (`use_lockfile = true`), so there's no DynamoDB table. That feature needs Terraform 1.10 or newer.

The values Terraform needs but I don't want in the repo (my IP for SSH, the AMI ID, the key pair name and the database password) are GitHub secrets, passed in as `TF_VAR_*` environment variables. `*.tfvars` and `*.tfstate` are in `.gitignore`.

## The result

After the second deploy the EC2 instance was replaced with one that downloads this repo, starts the Flask app as a systemd service, and has nginx forwarding port 80 to it. The database sits in private subnets and only accepts connections from the web server's security group.

![EC2 instance running](screenshots/ec2-running.png)

![RDS instance available](screenshots/rds-available.png)

![Product catalog served through nginx and Flask, reading from RDS](screenshots/app-product-catalog.png)

![The /health endpoint](screenshots/app-health.png)

When I was done I ran the workflow with `destroy`, approved it, and waited for it to finish green. Afterwards I checked the console: no instances, no databases (and no snapshots, since the RDS instance skips the final one), and the only VPC left is the account's default one. The whole thing was up for a few hours, so it cost very little.

![EC2 instances list, empty after destroy (account ID covered)](screenshots/destroyed-ec2.png)

![RDS dashboard, zero instances and zero snapshots](screenshots/destroyed-rds.png)

![VPC list, only the default VPC remains (account ID covered)](screenshots/destroyed-vpc.png)

## Security scans

Checkov ended with 21 passed and 23 failed checks on the Terraform. I went through the failures instead of silencing them, and sorted them into two piles:

![Checkov summary: 21 passed, 23 failed](screenshots/checkov-summary.png)

- About eight are cheap and I should just fix them: require IMDSv2 on the instance, encrypt the root volume, turn on RDS storage encryption, automatic minor version upgrades and copying tags to snapshots, add descriptions to the egress rules, and restrict the default security group. I haven't applied these yet. That's the first item in the list at the bottom.
- The other 15 are things a short-lived demo doesn't need, like multi-AZ or enhanced monitoring on the database. I left them alone on purpose, but I'd want them for anything real.

Checkov runs with `--soft-fail`, so it reports but doesn't block a merge. I'd rather start there and tighten later than have a new scanner block everything on day one.

## Things that broke

Most of what I learned came from fixing these.

**The first push was rejected.** My personal access token didn't have the `workflow` scope, and GitHub won't let you push files under `.github/workflows` without it.

**Lint and format checks failed on code I thought was fine.** flake8 wanted a newline at the end of the file, no spaces on a blank line, and a `# noqa: E402` on an import that comes after a `sys.path` change. `terraform fmt -check` failed on three files until I ran `terraform fmt -recursive`.

**My Terraform was too old for S3 locking.** I had 1.8.3 locally and `use_lockfile` needs 1.10. Homebrew wouldn't upgrade it, so I installed 1.16.5 by hand.

**AWS refused the login: "Not authorized to perform sts:AssumeRoleWithWebIdentity".** I added a debug step that prints the token's subject claim and found it includes numeric owner and repo IDs (`repo:OWNER@ID/REPO@ID:ref:refs/heads/main`), which my trust policy didn't have. Then pull requests failed in a different way, because their subject ends in `:pull_request` instead of a branch name, so the policy needed both.

**The plan job was green while Terraform was failing.** The secrets weren't set yet, so the plan stopped with `"" is not a valid CIDR block`. But I was piping the output through `tee`, and a pipe returns the exit code of its last command, which was `tee`. Adding `shell: bash` (which turns on `pipefail`) made the job go red like it should. The lesson I took away is that a green check only means the steps didn't fail, not that they did what I wanted.

**GitHub said my deploy workflow was invalid.** I'd pasted the shell command that creates the file into the file itself, so line 1 was `cat > ... << 'EOF'`. GitHub showed the workflow under its file path instead of its name and failed two runs with no jobs. Deleting two stray lines fixed it. The same mistake hit a Terraform file later, and `terraform validate` caught it before I pushed.

![Deploy workflow runs failing because the file was invalid](screenshots/invalid-workflow-file.png)

**The site wouldn't load after deploy.** The server's startup log looked fine, so I ran `curl` against it and got `200 OK` from nginx. Chrome had been quietly switching the address to `https://`, and the server only listens on port 80.

**Changing the startup script did nothing.** EC2 only runs its user data on first boot, so editing it on a running instance doesn't re-run it. Setting `user_data_replace_on_change = true` makes Terraform replace the instance instead.

## What I'd do next

- Apply the Checkov fixes through a normal PR.
- Narrow the deploy role from `ec2:*` and `rds:*` to the specific actions Terraform actually calls.
- Turn on branch protection so nothing reaches `main` without a pull request and green checks. Right now I'm the only one pushing, so I haven't had to.
- Stop putting the database password in the instance's startup script, where anyone with access to the EC2 console can read it. SSM Parameter Store or Secrets Manager is the usual answer.
- Update the actions. The runs show a warning that `checkout@v4`, `configure-aws-credentials@v4` and `setup-terraform@v3` run on a deprecated Node version, and that `ubuntu-latest` moves to Ubuntu 26 starting October 19, 2026. I'd also pin the Terraform version in CI.
- Put HTTPS in front of the app, with a load balancer or CloudFront.

## Running it yourself

It isn't one click, because some things live outside the repo. You'd need an AWS account with a GitHub OIDC identity provider and the two roles described above, an S3 bucket for state (update `terraform/backend.tf` with its name), a GitHub environment called `production` with a required reviewer, and four repository secrets: `MY_IP` (with the `/32`), `AMI_ID`, `KEY_NAME` and `DB_PASSWORD`. Then run **Actions, Deploy, Run workflow** and choose `apply`. When you're finished, run it again with `destroy`.
