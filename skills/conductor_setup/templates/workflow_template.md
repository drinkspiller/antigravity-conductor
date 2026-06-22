# Project Workflow

## Guiding Principles

1. **The Plan is the Source of Truth:** All work must be tracked in `plan.md`
2. **The Tech Stack is Deliberate:** Changes to the tech stack must be documented in `tech-stack.md` *before* implementation
3. **Test-Driven Development:** Write unit tests before implementing functionality
4. **High Code Coverage:** Aim for >80% code coverage for all modules
5. **User Experience First:** Every decision should prioritize user experience
6. **Non-Interactive & CI-Aware:** Prefer non-interactive commands. Use `CI=true` for watch-mode tools (tests, linters) to ensure single execution.

## Task Workflow

All tasks follow a strict lifecycle:

### Standard Task Workflow

1. **Select Task:** Choose the next available task from `plan.md` in sequential order

2. **Mark In Progress:** Before beginning work, edit `plan.md` and change the task from `[ ]` to `[~]`

3. **Write Failing Tests (Red Phase):**
   - Create a new test file for the feature or bug fix.
   - Write one or more unit tests that clearly define the expected behavior and acceptance criteria for the task.
   - **CRITICAL:** Run the tests and confirm that they fail as expected. This is the "Red" phase of TDD. Do not proceed until you have failing tests.

4. **Implement to Pass Tests (Green Phase):**
   - Write the minimum amount of application code necessary to make the failing tests pass.
   - Run the test suite again and confirm that all tests now pass. This is the "Green" phase.

5. **Refactor (Optional but Recommended):**
   - With the safety of passing tests, refactor the implementation code and the test code to improve clarity, remove duplication, and enhance performance without changing the external behavior.
   - Rerun tests to ensure they still pass after refactoring.

6. **Verify Coverage:** Run coverage reports using the project's chosen tools.
   Target: >80% coverage for new code. The specific tools and commands will vary by language and framework.

7. **Document Deviations:** If implementation differs from tech stack:
   - **STOP** implementation
   - Update `tech-stack.md` with new design
   - Add dated note explaining the change
   - Resume implementation

8. **Commit Code Changes:**
   - Stage all code changes related to the task.
   - Propose a clear, concise commit message following the format below.
   - Perform the commit.

9. **Update Plan:**
   - Read `plan.md`, find the line for the completed task.
   - Update its status from `[~]` to `[x]`.
   - Append the first 7 characters of the commit hash.
   - Write the updated content back to `plan.md`.
   - Commit the plan update: `conductor(plan): Mark task '<TASK NAME>' as complete`

### Phase Completion Verification and Checkpointing Protocol

**Trigger:** Execute this protocol immediately after completing the last task in a phase.

1. **Announce Protocol Start:** Inform the user that the phase is complete and the verification protocol has begun.

2. **Ensure Test Coverage for Phase Changes:**
   - Determine the phase scope by finding the previous checkpoint SHA in `plan.md`.
   - List all changed files since the last checkpoint.
   - For each code file, verify a corresponding test file exists. If missing, create one following the project's testing conventions.

3. **Execute Automated Tests:**
   - Announce the exact command you will run before executing it.
   - Execute the test command.
   - If tests fail, inform the user and attempt to fix (maximum two attempts). If still failing, stop and ask for guidance.

4. **Propose Manual Verification Plan:**
   Generate step-by-step instructions for the user to manually verify the phase:
   - For frontend: dev server commands, URLs, expected visual outcomes.
   - For backend: curl commands, expected responses, database checks.

5. **Await User Feedback:**
   Ask: "**Does this meet your expectations? Please confirm with yes or provide feedback.**"
   **PAUSE** and wait for the user's explicit confirmation. Do not proceed without it.

6. **Create Checkpoint Commit:**
   - Stage all changes and commit: `conductor(checkpoint): Checkpoint end of Phase X`
   - Record the checkpoint SHA in `plan.md`.
   - Commit the plan update.

### Quality Gates

Before marking any task complete, verify:

- [ ] All tests pass
- [ ] Code coverage meets requirements (>80%)
- [ ] Code follows project's style guidelines (as defined in `code_styleguides/`)
- [ ] All public functions/methods are documented
- [ ] Type safety is enforced
- [ ] No linting or static analysis errors
- [ ] Works correctly on mobile (if applicable)
- [ ] Documentation updated if needed
- [ ] No security vulnerabilities introduced

## Development Commands

**AI AGENT INSTRUCTION: Customize this section with the project's specific language, framework, and build tools during `/conductor_setup`.**

### Setup
```bash
# Example — replace with actual project commands
npm install
```

### Daily Development
```bash
# Example — replace with actual project commands
npm run dev
```

### Before Committing
```bash
# Example — replace with actual project commands
npm run lint
npm test
```

## Testing Requirements

### Unit Testing
- Write unit tests for all new functions and methods
- Test edge cases and error handling
- Mock external dependencies appropriately

### Integration Testing
- Test component interactions where applicable
- Verify API contracts

## Commit Guidelines

### Message Format
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests
- `chore`: Maintenance tasks

### Examples
```bash
git commit -m "feat(auth): Add remember me functionality"
git commit -m "fix(posts): Correct excerpt generation for short posts"
git commit -m "test(comments): Add tests for emoji reaction limits"
```

## Definition of Done

A task is complete when:

1. All code implemented to specification
2. Unit tests written and passing
3. Code coverage meets project requirements
4. Documentation complete (if applicable)
5. Code passes all configured linting and static analysis checks
6. Works correctly on mobile (if applicable)
7. Implementation notes added to `plan.md`
8. Changes committed with proper message
