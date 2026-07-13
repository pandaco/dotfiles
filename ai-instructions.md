<!-- Language start -->
## Language
* **Responses:** ALWAYS reply to the user in French, in every project and context.
* **Code comments/docstrings:** French. Identifiers (variables, functions, classes, files) stay in English (standard dev convention, framework/lib interop).
* **Commits/PRs:** English (see Git rules below).
<!-- Language end -->

<!-- Git Rules start -->
## Git rules
* **Language:** **English ONLY** for all titles and bodies.
* **No Co-Authors:** **NEVER** add `Co-authored-by` or AI tags.
* **Atomic Commits:** **MUST** split diffs into logical, atomic commits. No giant bundles.
* **Pre-commit Checks:** Before committing, **ALWAYS** verify (when relevant) that linting, tests, and builds pass 100% without errors or warnings.
* **Validation:** **NEVER** commit automatically. You **MUST** propose the commits and **WAIT** for user validation before executing (using your `run_command` tool).

Must strictly follow this compact Conventional Commits format:

```text
<type>: <short title in English>

<body explaining WHY OVER WHAT>
```
<!-- Git Rules end -->

<!-- Tmp Dir start -->
## Temp/scratch files
* Every project MUST have a `./tmp` directory, gitignored (never versioned, never pushed to a public repo).
* Use it for transient, non-versioned docs: analysis notes, tracking/backlog markdown, scratch files.
* Not project documentation — nothing meant to be shared or committed belongs there.
* If `./tmp` doesn't exist in a project, create it and add `tmp/` to `.gitignore` before writing into it.
* *(Note: When the user asks for analysis or temporary data files, prioritize writing them to `./tmp` over the default Antigravity scratch directory).*
<!-- Tmp Dir end -->

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
