return {
  "rmagatti/auto-session",
  config = function()
    local auto_session = require("auto-session")

    auto_session.setup({
      auto_restore_enabled = false,
      auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
    })

    require("which-key").add({
      { "<leader>s",  group = "[s]ession" },
      { "<leader>sr", "<cmd>Autosession restore<CR>", desc = "[r]estore" },
      { "<leader>ss", "<cmd>Autosession save<CR>", desc = "[s]ave" },
    })
  end,
}
