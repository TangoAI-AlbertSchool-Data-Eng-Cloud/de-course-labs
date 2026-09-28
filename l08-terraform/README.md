# Lesson 8 · Terraform

| Path | What it is |
|---|---|
| `lab-example/` | the Terraform that created **your group's Google Cloud project** |

## Read this one, do not run it

`lab-example/` is the real thing, sanitised. It is the configuration your
teacher applied before lesson 2 to create the project you have been working
inside ever since: it makes the project, enables the APIs you have been using,
sets the budget that stops the course bankrupting anybody, and grants your
group its roles.

**It is here to be read.** Applying it would try to create another project
against a billing account you do not have, which is why the values it needs
are not published. `terraform.tfvars.example` shows their shape.

It is worth reading for three reasons:

- **It is the only production Terraform you have access to**, and it is small
  enough to finish — under 500 lines including comments.
- **Its comments explain refusals, not just choices.** `variables.tf` says why
  `roles/iam.serviceAccountKeyAdmin` is absent and what you get instead. That
  is the kind of comment worth copying.
- **You are inside it.** Every permission you have or lack in lesson 8's
  exercise is a line in `main.tf`.

## It is generated, so do not edit it here

These files are produced from the private staff repository by
`scripts/build-lab-example.mjs` in the course platform, and regenerated when
the lab changes. An edit made here is overwritten the next time somebody runs
it.

What is deliberately absent and always will be: `terraform.tfvars` (the billing
account and everybody's addresses), any `.tfstate` (which holds all of that in
clear), and the `.terraform/` directory.
