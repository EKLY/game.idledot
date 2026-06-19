# AI_SPEC_TEMPLATE.md

## Purpose

This specification is designed for a **single-developer, multi-AI workflow**. Its purpose is **cross-AI continuity and consistency**, not team or organizational governance.

This file is a **meta-specification template**. It is used to **create a project-specific `AI_SPEC.md`**.

When this file is used, AI must:

* Read this template first.
* Ask the user structured questions about:

  * What system is being built
  * Which stacks and technologies will be used
  * How the project should be structured
  * What constraints must be enforced
* Then generate a new, concrete `AI_SPEC.md` based on the answers.

This file itself must not be treated as the project AI_SPEC. It exists only to bootstrap one.

---

## Core Principles

* The system must have explicit boundaries between major areas (e.g., UI vs server logic, client vs API, app vs data layer).
* AI must not invent architecture, conventions, or behaviors that are not written in this spec or discovered in the repository.
* If the repository reality conflicts with this spec, AI must report the mismatch and propose an update to this spec.

---

## Language Policy

### Human vs AI Documentation Language

* **Human-facing interaction (chat, explanations, reports)** must be written in **Thai**.
* **All files named `AI_*.md` must be written in English only**.
* Mixing languages inside the same `AI_*.md` file is not allowed.
* File paths, code, identifiers, and library names must always remain unchanged.
* AI must not translate existing English specification content into Thai.

Violation of this language policy should be treated as a specification violation.

---

## Task Invocation Contract

To reduce prompt verbosity, AI must treat the following minimal instruction as sufficient to begin work:

> "Before starting, read AI_SPEC.md and then execute the task below."

The absence of repeated instructions in the prompt does **not** relax or override any rule in this specification.

---

## AI Cross-Agent Rules

### Optional Cross-Project Document: `AI_DOCUMENT.md`

A project may optionally provide an `AI_DOCUMENT.md` file.

This file is **not required** for internal development tasks. It exists to support **cross-project AI interaction**.

Its purpose is to explain, at a system and interface level:

* What this project is
* What services, APIs, or capabilities it exposes
* How external systems or other projects should integrate with it
* What assumptions or constraints external AI agents must respect

When present:

* `AI_DOCUMENT.md` is written in **English only**.
* It is a **project-facing integration document**, not a working document.
* It may be **updated after tasks are completed** to reflect new or changed integration capabilities.
* It must not be used as working memory or internal history.
* AI must not place project state, internal decisions, or changelog-style entries in this file.

---

This file is written **for AI-first consumption**.

This file is written **for AI-first consumption**.

Any AI interacting with this repository must follow the **mandatory execution order** below.

### Mandatory AI Execution Order

1. **Read `AI_SPEC.md` first**

   * This file defines the system contract, architecture, and all hard constraints.
   * No task analysis or assumption is allowed before this step.

2. **Read `AI_MEMORY.md` second**

   * This file represents the current working state of the project.
   * It contains context about previously completed tasks, decisions, and unresolved items.

3. **Execute the assigned task**

   * Tasks must be performed strictly within the constraints defined in `AI_SPEC.md`.
   * Existing context in `AI_MEMORY.md` must be respected and not contradicted.

4. **Update `AI_MEMORY.md`**

   * During long or multi-step tasks, AI should update `AI_MEMORY.md` periodically.
   * After task completion, AI must update `AI_MEMORY.md` to reflect the new current state.

### AI Memory Discipline

* `AI_MEMORY.md` is the **only persistent working memory** for AI across tasks.
* AI must not rely on chat history as long-term memory.
* Any decision, assumption, or state required for future work must be written to `AI_MEMORY.md`.

### Task-Scoped Memory File Selection

AI may be instructed to use a task-specific memory file instead of the root `AI_MEMORY.md`.

If the user explicitly specifies a memory file path in the task instruction (e.g., "Start work by reading AI_SPEC.md using `frontend/src/pages/crm/AI_MEMORY.md`"), then:

* Treat the specified file as the active `AI_MEMORY.md` for that task.
* Read from it as step 2 in the Mandatory AI Execution Order.
* Write updates to that file instead of the root `AI_MEMORY.md`.

If no memory file path is explicitly specified, use the root `AI_MEMORY.md`.

### Change Log Policy

* All historical and chronological records **must be written to `AI_CHANGELOG.md`**.
* `AI_MEMORY.md` must reflect **only the current state**, not history.
* AI must not append change history to `AI_MEMORY.md`.
* Every completed task or meaningful change must result in an entry in `AI_CHANGELOG.md`.

Failure to follow this execution order, memory discipline, or change log policy should be treated as a specification violation.

---

## Future Extensions (Optional)

Add only if needed:

* Canonical folder structures
* API contracts and conventions
* Naming and coding standards
* Error code specifications
* Data models
* Additional AI discipline rules
