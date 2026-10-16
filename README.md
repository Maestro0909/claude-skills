# claude-skills

Backup of my Claude Code skills. Each folder is one skill (contains a `SKILL.md`).

## Use on a PC (all projects)
Clone straight into the personal skills folder:

    git clone https://github.com/Maestro0909/claude-skills ~/.claude/skills

(Windows: `%USERPROFILE%\.claude\skills`)

## Add a new skill
1. Vet it first (see `vet-before-use`).
2. Install it into `~/.claude/skills`, e.g. `npx skills add <repo> --skill <name> -g`.
3. `git add . && git commit -m "add <name>" && git push`
