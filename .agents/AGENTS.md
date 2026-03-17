# Agent Implementation Rules

This file defines the roles, scanning protocols, and resource management requirements for AI agents operating within this repository.

## Agent Roles

* **Chat (Thinking Agent)**: Acts as the primary lead for planning and delegations.
* **Antigravity (Thinking / Execution Agent)**: Serves as the Instruction Governor, ensuring all operations adhere to established constraints and protocols. This agent is responsible for verifying updates to `AGENT.md` and `PLAN.md`, refining `TASK.md` when additional work is required, and generating the specific prompts required for execution agents.
* **Claude Code (Execution Agent)**: Responsible for high-reasoning engineering and complex code implementation.
* **Gemini CLI (Execution Agent)**: Conducts directory indexing, file summarisation, and provides relevant context for engineering tasks.

## Scanning Protocols

* **Ignore File Compliance**: During the initial scan phase, the agent must explicitly read and adhere to all ignore files within the repository, including `.gitignore`, `.aiexclude`, and `.geminiignore`.

## Work Scoping & Resource Management

* **Usage Limit Awareness**: When creating or updating the `TASK.md` file, the Thinking Agent must scope work to ensure that allocated daily usage limits for execution agents are not exhausted.
* **Task Classification**: Every task entry must carry a classification of **light**, **medium**, or **heavy** based on the estimated usage cost and computational intensity of the request.

## Housekeeping Requirements

* **Handover Updates**: Upon the completion of a task, the execution agent must update the handover section of `PLAN.md` to reflect current progress and status.
* **Continuous Improvement**: The agent must update this file (`AGENT.md`) with any lessons learned, identified preferences, or workflow optimisations discovered during the execution of its tasks.