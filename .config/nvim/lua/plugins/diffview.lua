return {
  'sindrets/diffview.nvim',
  config = function()
    local wk = require('which-key')
    wk.add({
      { '<leader>v',  group = 'diff[V]iew' },
      { '<leader>vo', '<cmd>DiffviewOpen<CR>',  desc = "Open Diffview" },
      { '<leader>vc', '<cmd>DiffviewClose<CR>', desc = "Close Diffview" },
      {
        '<leader>vh',
        function()
          local path = vim.fn.expand('%')
          vim.cmd { cmd = "DiffviewFileHistory", args = { path } }
        end,
        desc = "Current buffer file history "
      },
      { '<leader>vf', '<cmd>DiffviewFocusFiles<CR>', desc = 'Focus files' },
    })
    vim.opt.fillchars:append { diff = "/" }
  end
}
