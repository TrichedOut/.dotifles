return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
      end

      require("which-key").add({
        { "<leader>h",  group = "[h]unk" },
        { "<leader>hr", gs.reset_hunk,  desc = "[r]eset hunk" },
        { "<leader>hR", gs.reset_buffer,  desc = "[R]eset buffer" },
        { "<leader>hp", gs.preview_hunk,  desc = "[p]review" },
        { "<leader>hB", gs.toggle_current_line_blame,  desc = "toggle [B]lame" },
        { "<leader>hd", gs.diffthis,  desc = "[d]iff" },
        {
          "<leader>hb",
          function()
            gs.blame_line({ full = true })
          end,
          desc = "[b]lame line"
        },
      })
    end,
  },
}
