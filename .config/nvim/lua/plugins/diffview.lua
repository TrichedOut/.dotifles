return {
  'sindrets/diffview.nvim',
  config = function()
    require("which-key").add({
      { "<leader>v",  group = "diff[V]iew" },
      { "<leader>vd", "<cmd>DiffviewOpen<CR>",  desc = "[d]iff" },
      { "<leader>vc", "<cmd>DiffviewClose<CR>", desc = "[c]lose" },
      {
        "<leader>vh",
        function()
          local path = vim.fn.expand("%")
          vim.cmd { cmd = "DiffviewFileHistory", args = { path } }
        end,
        desc = "[h]istory"
      },
    })
    vim.opt.fillchars:append { diff = "/" }
  end
}
