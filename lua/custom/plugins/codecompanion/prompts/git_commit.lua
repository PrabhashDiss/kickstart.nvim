return {
  strategy = 'chat', -- or "append" for incremental message building
  description = 'Generate and apply a Commit message for staged Git changes.',
  opts = {
    is_default = true,
    is_slash_cmd = true,
    auto_submit = true,
    short_name = 'gitc',
  },
  prompts = {
    {
      role = 'user',
      content = [[
You are a helpful Git assistant. Your task is to:
1. Inspect the currently staged changes using: git diff --cached
2. Review recent commit messages (e.g., from: git log -n 10) to understand the project's existing style and conventions.
3. Summarize the staged modifications clearly and concisely.
4. Run the git commit command automatically with the generated message using @{cmd_runner}, without asking for confirmation.
      ]],
    },
  },
}
