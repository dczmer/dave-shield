# Project Plan Formulation

---
name: project-plan-formulation
description: Conducts iterative interviews to develop comprehensive project planning documents covering overview, tech stack, architecture, development process, conventions, and security. Use when the user asks to "create a project plan", "document a project", "conduct project planning interview", or mentions needing structured project documentation. Can accept supplemental context or instructions when invoked.
allowed-tools: "Read,Grep,Glob,Bash,AskUserQuestion,Write"
version: "1.0.0"
author: "Claude Code"
---

## Introduction

This skill conducts an interactive interview process to formulate comprehensive project planning documents. It's designed for use at the start of new projects or when documenting existing ones to establish clear architectural and development guidelines.

The skill generates a structured `PROJECT_PLAN.md` document covering:
1. **Overview** - What the project is, its purpose and scope
2. **Tech Stack** - Languages, frameworks, tools, and dependencies
3. **Architecture Overview** - System components, data flow, and design decisions
4. **Development and Testing Process** - Setup, workflows, and testing approach
5. **Conventions and Rules** - Code organization, naming, and standards
6. **Security Considerations** - Auth, data protection, and vulnerabilities

### Process Flow

The skill follows a structured, iterative approach:
- Each section includes: **gather** → **clarify** → **summarize** → **confirm**
- You must approve each section before moving to the next (blocking gates)
- You can navigate back to revise sections, skip sections, or stop at any time
- Final document is reviewed, modified if needed, and saved to the project root

### Usage

Invoke with: `/project-plan-formulation [optional context]`

You can provide supplemental context at invocation:
- File paths to read (e.g., "read AGENTS.md and lib-python-core/")
- Specific instructions (e.g., "focus on security aspects")
- Existing documentation to incorporate

The interview typically takes 10-20 minutes depending on project complexity.

---

## Step 0: Process Supplemental Context

When this skill is invoked, first check if the user provided any supplemental context or instructions.

**If supplemental context is provided:**
1. Parse the invocation for file paths, directories, or specific instructions
2. Use `Read`, `Grep`, or `Glob` to gather the referenced materials
3. Summarize what you've found and how it will inform the interview
4. Ask if there's anything else to review before starting

**If no supplemental context:**
- Proceed directly to Section 1
- Note that you'll rely on the user's knowledge during the interview
- Mention that you can read files during the interview if references come up

---

## Section 1: Project Overview

### Step 1.1: Initial Information Gathering

Use `AskUserQuestion` to gather the following information:

**Questions:**
1. What is this project? What problem does it solve or what value does it provide?
2. Who are the primary users or stakeholders?
3. What is explicitly IN scope for this project?
4. What is explicitly OUT of scope (what won't this project do)?
5. Are there any important constraints, timelines, or context I should know about?

Wait for the user's response.

### Step 1.2: Analyze and Clarify

After receiving the initial response:
1. Identify any ambiguities, gaps, or areas needing clarification
2. Formulate 2-4 specific follow-up questions based on their answers
3. Use `AskUserQuestion` to ask these clarifying questions

Example clarifications might cover:
- Scale or performance requirements
- Integration points with other systems
- Success criteria or metrics
- Existing systems being replaced or enhanced
- Regulatory or compliance requirements

Wait for the user's response.

### Step 1.3: Present Summary and Confirm (BLOCKING STEP)

Format the section summary clearly:

```markdown
## Section 1: Project Overview ✓

**What it is:**
[Summary of the project]

**Primary users/stakeholders:**
[List]

**Scope (IN):**
- [Item 1]
- [Item 2]

**Scope (OUT):**
- [Item 1]
- [Item 2]

**Key context/constraints:**
[Important context]
```

Use `AskUserQuestion` to present this summary and ask:
- "Does this accurately capture the project overview?"
- Options: "Looks good", provide corrections, or "Skip this section"

**BLOCKING GATE:** Must wait for user confirmation before proceeding.

**If corrections provided:**
1. Update the summary based on feedback
2. Show the revised summary
3. Ask for confirmation again
4. Repeat until approved

**If user says "Skip this section":**
- Note that Section 1 was skipped
- Move to Section 2

**If approved:**
- Store the approved summary
- Acknowledge and transition: "Great! Moving to Section 2: Tech Stack"

---

## Section 2: Tech Stack

### Step 2.1: Initial Information Gathering

Use `AskUserQuestion` to gather the following information:

**Questions:**
1. What programming language(s) and versions will be used?
2. What frameworks or major libraries are you using?
3. What build tools, package managers, or task runners?
4. What databases, data stores, or caching layers?
5. Are there external services, APIs, or third-party integrations?
6. What development tools are critical (IDEs, linters, formatters, etc.)?

Wait for the user's response.

### Step 2.2: Analyze and Clarify

After receiving the initial response:
1. Identify missing details or potential compatibility concerns
2. Formulate 2-4 specific follow-up questions

Example clarifications might cover:
- Specific version requirements or ranges
- Rationale for framework choices
- Development vs. production dependencies
- Infrastructure dependencies (Docker, cloud services)
- Monitoring or observability tools

Use `AskUserQuestion` to ask these clarifying questions and wait for response.

### Step 2.3: Present Summary and Confirm (BLOCKING STEP)

Format the section summary:

```markdown
## Section 2: Tech Stack ✓

**Languages:**
- [Language] (version X.Y)

**Frameworks & Libraries:**
- [Framework/Library] (version X.Y) - [purpose]

**Build Tools:**
- [Tool] (version X.Y)

**Databases & Storage:**
- [Database] (version X.Y)

**External Services:**
- [Service] - [purpose]

**Development Tools:**
- [Tool] - [purpose]
```

Use `AskUserQuestion` to present and ask for confirmation.

**BLOCKING GATE:** Must wait for approval, handle corrections as in Section 1, then proceed.

---

## Section 3: Architecture Overview

### Step 3.1: Initial Information Gathering

Use `AskUserQuestion` to gather the following information:

**Questions:**
1. What are the main components or services in the system?
2. How do these components communicate? (APIs, message queues, events, etc.)
3. What does the deployment architecture look like? (monolith, microservices, serverless, etc.)
4. What are the key design decisions or trade-offs that shaped the architecture?
5. Are there existing architectural patterns or systems this should follow?

Wait for the user's response.

### Step 3.2: Analyze and Clarify

After receiving the initial response:
1. Identify areas where architectural details are unclear
2. Formulate 2-4 specific follow-up questions

Example clarifications might cover:
- Data flow through the system
- State management approach
- Scalability considerations
- Failure handling and resilience patterns
- Relationship to existing systems or services

Use `AskUserQuestion` to ask these clarifying questions and wait for response.

### Step 3.3: Present Summary and Confirm (BLOCKING STEP)

Format the section summary:

```markdown
## Section 3: Architecture Overview ✓

**System Components:**
- [Component 1] - [description]
- [Component 2] - [description]

**Communication Patterns:**
[Description of how components interact]

**Data Flow:**
[High-level data flow description]

**Deployment Architecture:**
[Description of deployment model]

**Key Design Decisions:**
1. [Decision] - [rationale]
2. [Decision] - [rationale]

**Existing Patterns to Follow:**
[Reference to existing systems or patterns]
```

Use `AskUserQuestion` to present and ask for confirmation.

**BLOCKING GATE:** Must wait for approval, handle corrections, then proceed.

---

## Section 4: Development and Testing Process

### Step 4.1: Initial Information Gathering

Use `AskUserQuestion` to gather the following information:

**Questions:**
1. How do you set up the development environment? (dependencies, configs, etc.)
2. What is the build/compile process?
3. How do you run the application locally?
4. What types of tests are required? (unit, integration, e2e, etc.)
5. What is the testing workflow? (how to run tests, where they live, etc.)
6. What are common debugging techniques or tools for this project?
7. What are the typical development workflows? (feature branches, hot reload, etc.)

Wait for the user's response.

### Step 4.2: Analyze and Clarify

After receiving the initial response:
1. Identify gaps in the development workflow description
2. Formulate 2-4 specific follow-up questions

Example clarifications might cover:
- Test coverage expectations
- CI/CD pipeline integration
- Local vs. containerized development
- Common gotchas or troubleshooting steps
- Code review process

Use `AskUserQuestion` to ask these clarifying questions and wait for response.

### Step 4.3: Present Summary and Confirm (BLOCKING STEP)

Format the section summary:

```markdown
## Section 4: Development and Testing Process ✓

**Environment Setup:**
1. [Step 1]
2. [Step 2]

**Build Process:**
[Description or command]

**Running Locally:**
[Description or command]

**Testing:**
- **Unit tests:** [description/command]
- **Integration tests:** [description/command]
- **E2E tests:** [description/command]

**Testing Workflow:**
[Description of how/when to run tests]

**Debugging:**
[Common debugging techniques and tools]

**Common Workflows:**
[Typical development workflows]
```

Use `AskUserQuestion` to present and ask for confirmation.

**BLOCKING GATE:** Must wait for approval, handle corrections, then proceed.

---

## Section 5: Conventions and Rules

### Step 5.1: Initial Information Gathering

Use `AskUserQuestion` to gather the following information:

**Questions:**
1. How should code be organized? (file structure, module patterns, etc.)
2. What naming conventions should be followed? (files, classes, functions, variables, etc.)
3. What documentation standards are expected? (docstrings, comments, README, etc.)
4. What are the code review practices or requirements?
5. Are there antipatterns or practices to avoid in this project?
6. How should files and folders be organized?

Wait for the user's response.

### Step 5.2: Analyze and Clarify

After receiving the initial response:
1. Identify areas where conventions are unclear or might conflict
2. Formulate 2-4 specific follow-up questions

Example clarifications might cover:
- Style guide references (PEP 8, Airbnb, Google, etc.)
- Linting and formatting tools/configs
- Import ordering conventions
- Error handling patterns
- Logging conventions

Use `AskUserQuestion` to ask these clarifying questions and wait for response.

### Step 5.3: Present Summary and Confirm (BLOCKING STEP)

Format the section summary:

```markdown
## Section 5: Conventions and Rules ✓

**Code Organization:**
[Description of file structure and module patterns]

**Naming Conventions:**
- **Files:** [convention]
- **Classes:** [convention]
- **Functions:** [convention]
- **Variables:** [convention]

**Documentation Standards:**
[Description of documentation expectations]

**Code Review Practices:**
[Description of review process and requirements]

**Antipatterns to Avoid:**
- [Antipattern 1] - [why to avoid]
- [Antipattern 2] - [why to avoid]

**File/Folder Organization:**
[Description or example structure]
```

Use `AskUserQuestion` to present and ask for confirmation.

**BLOCKING GATE:** Must wait for approval, handle corrections, then proceed.

---

## Section 6: Security Considerations

### Step 6.1: Initial Information Gathering

Use `AskUserQuestion` to gather the following information:

**Questions:**
1. How does authentication work in this system?
2. How is authorization/access control handled?
3. What data protection measures are in place? (encryption, PII handling, etc.)
4. Are there known vulnerabilities or security concerns to be aware of?
5. What security review or approval processes are required?
6. How are secrets and credentials managed?
7. What are the access control patterns or policies?

Wait for the user's response.

### Step 6.2: Analyze and Clarify

After receiving the initial response:
1. Identify security areas that need more detail
2. Formulate 2-4 specific follow-up questions

Example clarifications might cover:
- Input validation and sanitization
- OWASP top 10 considerations
- Compliance requirements (GDPR, HIPAA, etc.)
- Security testing requirements
- Incident response procedures
- Third-party security audits

Use `AskUserQuestion` to ask these clarifying questions and wait for response.

### Step 6.3: Present Summary and Confirm (BLOCKING STEP)

Format the section summary:

```markdown
## Section 6: Security Considerations ✓

**Authentication:**
[Description of authentication mechanism]

**Authorization:**
[Description of access control]

**Data Protection:**
[Description of encryption, PII handling, etc.]

**Known Vulnerabilities/Mitigations:**
- [Vulnerability] - [mitigation]

**Security Review Requirements:**
[Description of required reviews or approvals]

**Secrets Management:**
[Description of how secrets/credentials are handled]

**Access Control Patterns:**
[Description of access policies]
```

Use `AskUserQuestion` to present and ask for confirmation.

**BLOCKING GATE:** Must wait for approval, handle corrections, then proceed.

---

## Step 7: Final Assembly and Output

### Step 7.1: Compile Full Plan

Once all sections are complete (approved or skipped):
1. Assemble all approved section content
2. Add project metadata (date, version)
3. Generate table of contents
4. Format consistently with proper markdown

For skipped sections, include placeholder:
```markdown
## [Section Name]

_[Information not provided during planning interview]_
```

### Step 7.2: Present Complete Plan

Display the complete document with this structure:

```markdown
# Project Plan: [Project Name]

**Generated**: [Current Date]
**Version**: 1.0
**Last Updated**: [Current Date]

## Table of Contents
1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Architecture Overview](#architecture-overview)
4. [Development and Testing Process](#development-and-testing-process)
5. [Conventions and Rules](#conventions-and-rules)
6. [Security Considerations](#security-considerations)

[Full content for each section]
```

### Step 7.3: Request Final Modifications

Use `AskUserQuestion` to present the complete document and ask:

"Here's your complete project plan. What would you like to do?"

**Options:**
- "Save it" → Proceed to Step 7.4
- "Save as [filename]" → Proceed to Step 7.4 with custom filename
- Provide modifications → Update document, show again, ask again
- "Cancel" → Discard without saving

Wait for user's response and handle accordingly.

### Step 7.4: Write to File

**Default filename**: `PROJECT_PLAN.md` in project root

**If custom filename provided**: Use the user's specified name

Use `Write` tool to save the document:
1. Write to the specified file path in the project root
2. Confirm successful save with the full path
3. Explain document uses:
   - Onboarding new team members
   - Providing context to AI assistants
   - Recording architectural decisions
   - Guiding implementation choices

**Success message:**
```
✓ Project plan saved to: /path/to/PROJECT_PLAN.md

This document can be used for:
- Onboarding new team members
- Providing context to AI coding assistants
- Recording key architectural decisions
- Guiding consistent implementation

You can edit this file directly or re-run this skill to update it.
```

---

## Navigation and Special Commands

Throughout the interview, users can navigate flexibly:

**Moving Forward:**
- "next" or "continue" → Proceed to next section (after approval)
- "looks good" or "approved" → Approve current section summary

**Moving Backward:**
- "go back to [section name]" → Return to that section, allow revisions
- When returning to a section, show the current content, ask what to change

**Skipping:**
- "skip this" or "skip this section" → Mark section as skipped, move to next
- Skipped sections will have placeholder text in final document

**Stopping:**
- "stop" or "I'm done" → End interview immediately
- Offer to save partial content with incomplete sections noted
- Provide instructions for resuming (re-run skill, can load partial document)

**Adding Context Mid-Interview:**
- If user references files: "Let me read [file]"
- Use `Read` to fetch the file
- Ask if this changes any previous sections
- Incorporate into current and future sections

**"I Don't Know" Responses:**
- Offer to explore codebase with `Glob`, `Grep`, or `Read`
- Suggest specific files to check based on section topic
- Mark section as incomplete if exploration doesn't help
- Offer to skip and revisit later

---

## Error Handling Scenarios

### Partial Completion

If user stops mid-interview:
1. Confirm they want to stop
2. Offer to save partial document
3. Mark incomplete sections with: `_[Section incomplete - stopped during interview]_`
4. Provide resume instructions

### Contradictory Information

If user provides info that contradicts earlier sections:
1. Point out the contradiction
2. Ask which is correct
3. Offer to update the earlier section
4. Show both sections for review

### Unable to Answer

If user repeatedly says "I don't know":
1. Offer codebase exploration
2. Suggest they consult with team members
3. Mark section for future completion
4. Offer to skip and continue with other sections

### File Write Failure

If `Write` fails:
1. Show the error message
2. Ask for alternative save location
3. Offer to display full content for manual copy-paste
4. Suggest checking file permissions

---

## Tips for Best Results

**For Users:**
- Have existing documentation handy (README, ADRs, etc.)
- Think through architectural decisions beforehand
- Be specific about constraints and requirements
- Don't worry about perfect wording - you can refine later

**For AI:**
- Build on information from previous sections
- Reference earlier answers when relevant in later questions
- Be specific in questions, not generic
- Acknowledge and validate user responses
- Keep summaries concise but complete
- Use proper markdown formatting consistently

---

## Related Documentation

- Example output structure: `references/output-template.md`
- For post-creation updates, just edit `PROJECT_PLAN.md` directly
- Consider checking this document into git for team visibility
- Link to this from `AGENTS.md` or `CLAUDE.md` for AI context
