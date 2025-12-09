return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
  opts = {
    focus = true,
  },
  cmd = "Trouble",
  keys = function()
    require("which-key").add({
      { "<leader>x",  group = "diagnose" },
      { "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", desc = "[w]orkspace" },
      { "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "[t]odos" },
    })
  end
}
