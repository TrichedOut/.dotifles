return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
  config = function()
    require 'which-key'.add({
      { "<leader>t", group = "[T]abs"},
      { "<leader>to", "<cmd>tabnew<CR>", desc = "new tab" },
      { "<leader>tc", "<cmd>tabclose<CR>", desc = "close tab" },
      { "<leader>tf", "<cmd>tabnew %<CR>", desc = "open in new tab" },
      { "H", "<cmd>tabp<CR>", desc = "previous tab" },
      { "L", "<cmd>tabn<CR>", desc = "next tab" },

      { "<F9>", "<cmd>:nohl<CR>", desc = "clear highlight" },
    })
  end,
}
