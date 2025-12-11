# Ahab Project Specifications

**Single Source of Truth for All Feature Specifications**

This document consolidates all feature specifications for the Ahab project. Each feature includes requirements (WHAT and WHY), design (HOW), and tasks (implementation steps).

**Last Updated**: December 8, 2025

---

## Why One File?

**Problem**: Specs scattered across multiple directories are hard to find, read, and maintain.

**Solution**: Consolidate everything into one file.

**Benefits**:
- Find any spec in seconds (Ctrl+F)
- See all features at a glance
- Understand dependencies between features
- No directory navigation needed
- Follows Single Source of Truth principle (Core Principle #9)
- Easier to review and update

**What's Consolidated**:
- Requirements (WHAT and WHY)
- Design (HOW)
- Tasks (implementation steps)
- All features in one place

**Original Location**: Individual specs still exist in `.kiro/specs/` for reference, but THIS file is the source of truth.

---

## Table of Contents

1. [Docker Compose First Architecture](#1-docker-compose-first-architecture)
2. [Documentation Strategy](#2-documentation-strategy)
3. [Website Redesign](#3-website-redesign)

---

## 1. Docker Compose First Architecture

### Requirements

**Why This Matters**: The Ahab project delivers reliable infrastructure automation to schools and non-profits. Docker Compose First Architecture is our commitment: every build produces a working docker-compose.yml file that proves services deploy correctly, tests pass, and we deliver what we promise.

**Terms**:
- **Ahab_System**: The complete infrastructure automation system
- **Module**: A self-contained service definition (Apache, MySQL, etc.)
- **Docker_Compose_File**: YAML file defining multi-container Docker applications
- **Bootstrap_Script**: bootstrap.sh that clones all repositories
- **Generation_Script**: generate-docker-compose.py that creates docker-compose.yml

**What We Need**:

#### 1.1 Workstation Bootstrap (CRITICAL)
**Why**: This is what users do first. If this fails, nothing else matters.

**What**:
- `make install` creates workstation VM
- Installs Git, Ansible, Docker
- Clones all 4 repositories
- Creates symlinks
- `make verify-install` confirms it works

**Test**: Can a user run `make install` and have a working workstation? Yes or no.

#### 1.2 Four-Repository Architecture
**Why**: Separation of concerns. Orchestration ≠ configuration ≠ inventory ≠ modules.

**What**:
- ahab (orchestration)
- ansible-config (configuration)
- ansible-inventory (environments)
- ahab-modules (service definitions, Git submodule)
- Symlinks connect them

**Test**: Are all 4 repositories independently versioned? Yes or no.

#### 1.3 Docker Compose Generation
**Why**: Consistent, reproducible deployments.

**What**:
- Script reads module.yml files
- Generates valid docker-compose.yml
- Resolves dependencies
- Includes networks, volumes, services
- `docker-compose up -d` works

**Test**: Does the generated docker-compose.yml start all services without errors? Yes or no.

#### 1.4 Working Tests for Every Module
**Why**: Verify deployments before production.

**What**:
- Every module has a test script
- Tests prove module deploys correctly
- Tests show services function
- Tests provide diagnostics on failure

**Test**: Does every module have a passing test? Yes or no.

#### 1.5 Testing Pipeline
**Why**: No release until tests pass.

**What**:
- Workstation → Raspberry Pi → Dev Server (d701.dundore.net) → Release
- Each stage must pass
- Release includes validated docker-compose.yml
- All 4 repositories tagged with same version

**Test**: Did all tests pass before release? Yes or no.

### Design

**The Plan**:
1. Configure ahab-modules as Git submodule
2. Update bootstrap.sh for 4-repo architecture
3. Create/update generate-docker-compose.py
4. Create working test template
5. Update documentation
6. Create testing pipeline

**Why each step**:
- Submodule = independent versioning of modules
- Bootstrap = automated setup
- Generation script = consistent deployments
- Tests = proof it works
- Documentation = users understand it
- Pipeline = quality gate

### Tasks

- [x] 1. Configure ahab-modules as Git submodule
- [ ] 2. Update bootstrap.sh for four-repository architecture
- [ ] 3. Update Makefile for workstation bootstrap test
- [ ] 4. Create or update generate-docker-compose.py script
- [ ] 5. Test Docker Compose generation
- [ ] 6. Create Working_Test template for modules
- [ ] 7. Implement Apache module Working_Test
- [ ] 8. Update DEVELOPMENT_RULES.md
- [ ] 9. Update ABOUT.md
- [ ] 10. Update README.md
- [ ] 11. Create Raspberry Pi deployment test
- [ ] 12. Create d701.dundore.net deployment test
- [ ] 13. Create release creation script
- [ ] 14. Run complete workstation bootstrap test
- [ ] 15. Test Docker Compose generation end-to-end
- [ ] 16. Validate documentation accuracy
- [ ] 17. Checkpoint - Workstation Bootstrap Test must pass

---

## 2. Documentation Strategy

### Overview

The Documentation Strategy consolidates three related specifications (documentation-compliance, ai-transparency, and executive-summary) into a comprehensive approach for creating, maintaining, and validating all project documentation. This ensures documentation follows development rules, provides verifiable proof of AI development, and communicates business value to diverse audiences.

**See**: [.kiro/specs/documentation-strategy/](.kiro/specs/documentation-strategy/) for complete requirements, design, and implementation plan.

### Key Requirements

**Why This Matters**: Documentation must serve multiple audiences (students, developers, executives, skeptics) while maintaining consistency with core principles and providing verifiable evidence of AI capabilities.

**Terms**:
- **Kiro**: The AI that wrote this code
- **Timeline**: When features were completed (dates and times)
- **Velocity**: How fast features get done (features per day)
- **Proof**: Git commits you can verify yourself

**What We Need**:

#### 2.1 README Must Say "AI Built This"
**Why**: If people don't know AI built it, the whole point is lost.

**What**:
- Top of README.md: "🤖 AI-Powered Development" section
- Says "Kiro (AI) wrote this code"
- Lists what AI did: architecture, code, tests, docs
- Shows percentage: "84% AI-generated, 16% human review"
- Links to git commits as proof

**Test**: Can a hiring manager read README and immediately understand AI's role? Yes or no.

#### 2.2 Timeline Shows Speed
**Why**: "AI is fast" means nothing without dates and times.

**What**:
- DEVELOPMENT_TIMELINE.md file
- Every feature with date completed
- Shows velocity: "3.5 features per day"
- Includes failures: "Took 3 attempts to fix SELinux"
- Compares to traditional: "Would take 3 months, took 1 week"

**Test**: Can someone look at the timeline and say "holy shit, that's fast"? Yes or no.

#### 2.3 Graphs Make It Obvious
**Why**: People understand pictures faster than numbers.

**What**:
- Commit frequency graph
- AI vs Human pie chart (84% AI)
- Features per week bar chart
- Timeline visualization

**Test**: Can a non-technical person look at the graphs and understand AI did most of the work? Yes or no.

#### 2.4 Show What Jobs AI Replaced
**Why**: "AI can code" is vague. "AI did the work of 3 senior engineers" is specific.

**What**:
- DevOps Engineer: 40%
- Systems Architect: 25%
- Technical Writer: 20%
- QA Engineer: 15%
- Show complexity: NASA Power of 10 standards
- Link to commits
- Compare time: "Senior DevOps: 3 months. AI: 1 week."

**Test**: Can a CTO read this and calculate ROI for AI adoption? Yes or no.

#### 2.5 Be Honest About Failures
**Why**: If we only show successes, nobody will believe us.

**What**:
- "What AI Struggled With" section
- Document iterations
- Show human role
- List mistakes
- Explain fixes

**Test**: Does this feel honest or like marketing bullshit? Honest = good.

#### 2.6 Git Commits Are Proof
**Why**: Anyone can claim anything. Git history doesn't lie.

**What**:
- Every claim links to a commit hash
- Commit messages say "AI: implemented X"
- Timeline entries include commit hashes
- Anyone can run `git log` and verify

**Test**: Can a skeptic verify every claim by checking git history? Yes or no.

#### 2.7 Compare to Traditional Development
**Why**: Speed means nothing without context.

**What**:
- Traditional estimate: "3 senior engineers, 3 months = 9 person-months"
- AI actual: "1 week with AI + human direction"
- Time savings: "97% faster"
- Quality: "NASA standards compliant"
- Cost savings: "~$90,000"

**Test**: Can a CFO calculate ROI? Yes or no.

#### 2.8 Live Updates
**Why**: Watching it happen is more convincing than reading about it later.

**What**:
- QUEUE.md updated with timestamps
- CHANGELOG.md logs completion times
- "Last Updated" on every file
- Velocity changes documented

**Test**: Can someone watch the project and see AI working in real-time? Yes or no.

### Design

**The Plan**:
1. Extract data from git history
2. Calculate metrics (velocity, percentages)
3. Generate timeline
4. Create graphs
5. Write it all in README.md

**Scripts We Need**:
- `scripts/generate-timeline.sh` - Extracts timeline from git
- `scripts/analyze-code.py` - Counts lines, calculates percentages
- `scripts/generate-graphs.sh` - Creates visual charts
- `scripts/update-readme.sh` - Adds AI section to README

**Data Format**:
```
Date: 2025-12-07 10:30 AM
Feature: Docker Compose First Architecture
Status: ✅ Completed
Duration: 2 hours
Iterations: 2 (SELinux permissions issue)
Commits: abc123, def456
```

**Correctness Properties**:
1. Timeline chronologically ordered
2. Commit hashes verify in git log
3. Percentages sum to 100%
4. Timeline matches QUEUE.md
5. Metrics consistent across documents
6. Links resolve to valid GitHub URLs
7. Dates follow consistent format

### Tasks

- [ ] 1. Create git history extraction script
- [ ] 2. Parse QUEUE.md for completed items
- [ ] 3. Extract commit statistics
- [ ] 4. Calculate code statistics
- [ ] 5. Compute development velocity
- [ ] 6. Generate timeline entries
- [ ] 7. Create Mermaid diagrams
- [ ] 8. Generate ASCII charts
- [ ] 9. Write AI transparency section for README.md
- [ ] 10. Create DEVELOPMENT_TIMELINE.md
- [ ] 11. Create AI_CONTRIBUTIONS.md
- [ ] 12. Update ABOUT.md with AI philosophy
- [ ] 13. Create update scripts
- [ ] 14. Add to CI/CD pipeline
- [ ] 15. Manual review of all documentation
- [ ] 16. Verify all links and references
- [ ] 17. Get stakeholder approval

---

## 3. Website Redesign

### Requirements

**Why This Matters**: Transform index.html from technical demo into compelling marketing/educational tool for schools, non-profits, students, and teachers.

**Terms**:
- **Website**: The index.html file served by Apache
- **User**: School IT staff, non-profit admins, students, teachers
- **Docker Compose First**: Every build produces working docker-compose.yml
- **Module**: Service definition (Apache, MySQL, etc.)

**What We Need**:

#### 3.1 Clear Value Proposition
**Why**: Users need to understand what Ahab is immediately.

**What**:
- Headline ≤10 words
- Value proposition in 2-3 sentences
- Logical flow: problem → solution → action
- Plain language, no jargon
- Highlight "Docker Compose First"

**Test**: Can a school IT admin understand what Ahab is in 30 seconds? Yes or no.

#### 3.2 Show Problems We Solve
**Why**: Users need to see if Ahab addresses their needs.

**What**:
- 3 main problems:
  - Expensive cloud services
  - Expensive IT consultants
  - Complex DIY tools
- Specific pain points for each
- Connect problems to solutions
- Concrete examples of cost savings

**Test**: Can a non-profit admin see their problem listed? Yes or no.

#### 3.3 Technical Credibility
**Why**: Developers need to evaluate technical merit.

**What**:
- 9 core principles with explanations
- Docker Compose First with example
- Four-repository architecture
- NASA Power of 10 compliance
- Links to detailed docs

**Test**: Can a developer evaluate if this is technically sound? Yes or no.

#### 3.4 Quick Start Guide
**Why**: Lower barrier to entry.

**What**:
- ≤5 commands to get started
- Brief explanation for each command
- Takes <5 minutes
- Link to full documentation

**Test**: Can someone try Ahab in under 5 minutes? Yes or no.

#### 3.5 Target Audiences
**Why**: Help visitors self-identify.

**What**:
- 4 audiences: K-12 schools, non-profits, students, teachers
- 3-4 benefits per audience
- Concrete examples
- "Free forever" emphasis
- Inclusive language

**Test**: Can each audience see themselves and their benefits? Yes or no.

#### 3.6 Project Status & Roadmap
**Why**: Set expectations, show momentum.

**What**:
- What works, what's in progress, what's not ready
- 3-4 major milestones
- Honest disclaimer: "Experimental / Educational"
- Link to CHANGELOG

**Test**: Do users understand the project's maturity level? Yes or no.

#### 3.7 Visual Design
**Why**: First impressions matter.

**What**:
- Modern, professional design
- Visual hierarchy
- Distinct sections
- Clear visual feedback
- Responsive layout

**Test**: Does the site look professional and trustworthy? Yes or no.

#### 3.8 Safety & Transparency
**Why**: Build trust.

**What**:
- NASA Power of 10 standards
- Radical transparency principle
- Security audit disclaimer
- Multi-stage testing pipeline
- "Don't trust us, verify us"

**Test**: Do users feel they can trust the system? Yes or no.

#### 3.9 Clear Calls-to-Action
**Why**: Users need to know what to do next.

**What**:
- CTA after each major section
- Primary CTA to GitHub/docs
- "Get Started" button
- Links to documentation
- Path to contribution guide

**Test**: Is it obvious what to do next? Yes or no.

#### 3.10 Accessibility
**Why**: Everyone should be able to use the site.

**What**:
- Keyboard navigation with focus indicators
- Semantic HTML with ARIA labels
- WCAG AA color contrast (4.5:1 normal, 3:1 large)
- Descriptive alt text
- Proper heading hierarchy

**Test**: Can someone using a screen reader access all information? Yes or no.

### Design

**The Plan**:
1. Hero Section - Value proposition + CTA
2. Problem Section - 3 problems we solve
3. Solution Section - How Ahab solves them
4. Principles Section - 9 core principles
5. Quick Start Section - ≤5 commands
6. Target Audiences Section - 4 audiences
7. Architecture Section - 4-repository structure
8. Status & Roadmap Section - Current state + future
9. How to Help Section - Contribution opportunities
10. Footer Section - Links, contact, legal

**Technology**:
- HTML5 (semantic markup)
- CSS3 (custom properties, no frameworks)
- No JavaScript (static page)
- Single file (index.html)

**Correctness Properties**:
1. Color contrast meets WCAG AA (4.5:1 normal, 3:1 large)
2. All images have non-empty alt text

### Tasks

- [ ] 1. Set up HTML structure and CSS foundation
- [ ] 2. Implement Hero Section
- [ ] 3. Implement Problem Section
- [ ] 4. Implement Solution Section
- [ ] 5. Implement Principles Section
- [ ] 6. Implement Quick Start Section
- [ ] 7. Implement Target Audiences Section
- [ ] 8. Implement Architecture Section
- [ ] 9. Implement Status & Roadmap Section
- [ ] 10. Implement Safety & Transparency Section
- [ ] 11. Implement How to Help Section
- [ ] 12. Implement Footer Section
- [ ] 13. Implement accessibility features
- [ ] 13.1 Write property test for image alt text completeness
- [ ] 14. Implement responsive design and polish
- [ ] 15. Implement color contrast compliance
- [ ] 15.1 Write property test for color contrast accessibility
- [ ] 16. Add CTAs throughout the page
- [ ] 17. Write unit tests for content requirements
- [ ] 18. Checkpoint - Ensure all tests pass
- [ ] 19. Final validation and deployment preparation

---

## How to Use This Document

### For Developers

**Before coding**:
1. Read the requirements for your feature
2. Understand WHAT and WHY
3. Read the design for HOW
4. Check the tasks for implementation steps
5. Follow Absolute Rule #1: Read requirements FIRST

**During coding**:
1. Reference requirements to verify you're building the right thing
2. Use design as implementation guide
3. Check off tasks as you complete them
4. Update this document if requirements change

**After coding**:
1. Verify code matches requirements
2. Run all tests
3. Update task status
4. Document any deviations

### For Project Managers

**Planning**:
1. Review requirements to understand scope
2. Check tasks to estimate effort
3. Identify dependencies between features
4. Prioritize based on requirements

**Tracking**:
1. Monitor task completion
2. Verify requirements are met
3. Ensure design is followed
4. Update QUEUE.md with progress

### For Users

**Understanding features**:
1. Read requirements to see what's being built
2. Understand WHY each feature exists
3. See how features connect
4. Track progress through tasks

---

## Maintenance

**When to update**:
- Requirements change
- Design decisions change
- Tasks are completed
- New features are added
- Bugs are found that affect specs

**How to update**:
1. Update the relevant section
2. Update "Last Updated" date at top
3. Notify team of changes
4. Update QUEUE.md if priorities change

**Version control**:
- This file is tracked in Git
- Changes are reviewed before merge
- History shows evolution of specs

---

## Notes

- This document follows Absolute Rule #1: Read requirements before coding
- All specs follow EARS format (Easy Approach to Requirements Syntax)
- All specs include WHY (not just WHAT)
- All specs are testable (clear pass/fail criteria)
- All specs reference requirements in tasks

---

## Spec Consolidation Strategy

### Why We Consolidated

**Before**: Specs scattered across multiple directories with overlapping concerns
- `.kiro/specs/docker-compose-first/` (3 files)
- `.kiro/specs/documentation-compliance/` (3 files)
- `.kiro/specs/ai-transparency/` (2 files)
- `.kiro/specs/executive-summary/` (2 files)
- `.kiro/specs/website-redesign/` (3 files)
- `.kiro/specs/infrastructure-as-code/` (1 file)

**After Consolidation**:
- `.kiro/specs/docker-compose-first/` (3 files)
- `.kiro/specs/documentation-strategy/` (3 files) - **Consolidated from 3 specs**
- `.kiro/specs/website-redesign/` (3 files)

**Problem**:
- Hard to find specs
- Hard to see all features
- Hard to understand dependencies
- Violates Single Source of Truth principle

**After**: One file (`SPECIFICATIONS.md`)
- All requirements in one place
- All designs in one place
- All tasks in one place
- Easy to search, read, maintain

### Consolidation Rules

**Rule 1: This File Is The Source of Truth**
- When requirements conflict, THIS file wins
- Individual spec files are for reference only
- Update THIS file first, then sync to individual files if needed

**Rule 2: Keep It Simple**
- Requirements: WHAT and WHY (not HOW)
- Design: HOW (not WHAT or WHY)
- Tasks: Implementation steps (reference requirements)

**Rule 3: Use Plain Language**
- No jargon unless necessary
- Explain WHY, not just WHAT
- Assume reader might not understand context
- Test: "Can someone new understand this?"

**Rule 4: Make It Testable**
- Every requirement has a clear test
- Test format: "Can X do Y? Yes or no."
- No vague requirements ("should be good")
- Specific, measurable criteria

**Rule 5: Update Timestamps**
- Update "Last Updated" when you change anything
- Document what changed in QUEUE.md
- Keep CHANGELOG.md in sync

### How to Add New Specs

**Step 1: Add to Table of Contents**
```markdown
4. [Your Feature Name](#4-your-feature-name)
```

**Step 2: Add Requirements Section**
```markdown
## 4. Your Feature Name

### Requirements

**Why This Matters**: [Explain the problem]

**Terms**:
- **Term1**: Definition
- **Term2**: Definition

**What We Need**:

#### 4.1 Requirement Name
**Why**: [Explain why this matters]

**What**:
- Specific thing 1
- Specific thing 2
- Specific thing 3

**Test**: [Clear yes/no test]
```

**Step 3: Add Design Section**
```markdown
### Design

**The Plan**:
1. Step 1
2. Step 2
3. Step 3

**Why each step**:
- Step 1 = reason
- Step 2 = reason
- Step 3 = reason
```

**Step 4: Add Tasks Section**
```markdown
### Tasks

- [ ] 1. Task name
- [ ] 2. Task name
- [ ] 3. Task name
```

**Step 5: Update "Last Updated"**
```markdown
**Last Updated**: December 8, 2025
```

### How to Update Existing Specs

**Step 1: Read Absolute Rule #1**
- Understand WHY before changing WHAT
- Don't change requirements without understanding impact

**Step 2: Update the Relevant Section**
- Requirements: Change WHAT or WHY
- Design: Change HOW
- Tasks: Change implementation steps

**Step 3: Check Dependencies**
- Does this change affect other features?
- Do tasks need to be updated?
- Does QUEUE.md need updating?

**Step 4: Update Timestamp**
- Change "Last Updated" date
- Document change in QUEUE.md

**Step 5: Notify Team**
- If requirements changed, notify everyone
- If design changed, notify implementers
- If tasks changed, update task tracking

### Syncing with Individual Spec Files

**When to sync**:
- After major changes to THIS file
- Before starting implementation
- When creating releases

**How to sync**:
1. Copy relevant sections from THIS file
2. Paste into individual spec files
3. Verify formatting is correct
4. Commit both THIS file and individual files

**Why keep individual files**:
- Kiro IDE expects them in `.kiro/specs/`
- Easier to work on one feature at a time
- Can be used for feature-specific documentation
- Backup if THIS file gets corrupted

**Rule**: THIS file is source of truth, individual files are copies.

### Common Mistakes

**Mistake 1: Updating Individual Files Only**
- ❌ BAD: Update `.kiro/specs/feature/requirements.md` only
- ✅ GOOD: Update `SPECIFICATIONS.md` first, then sync

**Mistake 2: Vague Requirements**
- ❌ BAD: "System should be fast"
- ✅ GOOD: "Page loads in <2 seconds on 3G connection"

**Mistake 3: Missing WHY**
- ❌ BAD: "Add caching"
- ✅ GOOD: "Add caching (WHY: reduce server load by 80%)"

**Mistake 4: No Test Criteria**
- ❌ BAD: "Feature should work well"
- ✅ GOOD: "Can user complete task in <5 minutes? Yes or no."

**Mistake 5: Forgetting to Update Timestamp**
- ❌ BAD: Change content, leave old date
- ✅ GOOD: Change content, update "Last Updated"

### Maintenance Schedule

**Daily**:
- Update task status as work progresses
- Add new requirements as they're discovered
- Fix typos and formatting issues

**Weekly**:
- Review all specs for accuracy
- Update designs if implementation reveals issues
- Sync with individual spec files

**Monthly**:
- Major review of all specifications
- Archive completed features
- Update based on lessons learned

**Per Release**:
- Verify all specs match implementation
- Update based on testing results
- Document any deviations

---

## Spec File History

### December 8, 2025 - Initial Consolidation
- Consolidated 4 spec directories into single file
- Added Docker Compose First Architecture
- Added AI Transparency
- Added Website Redesign
- Added Infrastructure as Code (stub)
- Created consolidation strategy section
- Established rules for maintenance

### Future Updates
- Will be documented here
- Format: Date - What changed - Why

---

---

## Document Dependencies

**Before updating this file**: Check DOCUMENT_LINKS.md

This file depends on:
- **ABOUT.md** - Requirements must serve the mission
- **DEVELOPMENT_RULES.md** - Requirements must follow principles

When you update this file, also update:
1. QUEUE.md - Add/update tasks
2. README.md - Update feature list
3. CHANGELOG.md - Document spec changes
4. Individual spec files in `.kiro/specs/` - Sync if needed

**Rule**: Requirements flow from philosophy and principles. Check both before changing specs.

---

*Last updated: December 8, 2025*
*Single source of truth for all Ahab specifications*
*Follow Absolute Rule #1: Read this BEFORE coding*
*Check DOCUMENT_LINKS.md BEFORE updating*
