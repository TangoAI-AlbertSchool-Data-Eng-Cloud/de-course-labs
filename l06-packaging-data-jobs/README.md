# Lesson 6 · Packaging data jobs

The job the course containerises, and the two Dockerfiles it is built with —
one good, one deliberately bad.

| Path | What it is |
|---|---|
| `extract/extract_orders.py` | reads one table from the marketplace database and writes Parquet |
| `extract/requirements.txt` | pinned, because an unpinned image is a different image tomorrow |
| `extract/Dockerfile` | the one to copy: layer order, no secrets, not root |
| `extract/Dockerfile.naive` | the one the lecture takes apart |
| `naive/` | the build context that demonstrates the secret leak |

The published result is `charlestng/albert-extractor:2026-09-25`, which lesson
7 then schedules. You do not have to build it to follow lesson 7.

## Two things that will confuse you otherwise

**`extract/dockerignore.txt` is really a `.dockerignore`.** It is committed
under another name so that git does not treat it as this folder's own ignore
file. Rename it when you use it.

**`naive/` has no `.dockerignore`, on purpose.** That is the whole point of it:
it is the context that leaks `.env` into the image in demo guide section 3.
