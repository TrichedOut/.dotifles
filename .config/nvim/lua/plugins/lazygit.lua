return {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = function()
    require("which-key").add({
      { "<leader>l",  group = "[l]azygit" },
      { "<leader>lg", "<cmd>LazyGit<cr>",  desc = "lazy[g]it" },
      { "<leader>lc", "<cmd>LazyGitCurrentFile<cr>", desc = "[c]urrent file" },
    })
  end
}
