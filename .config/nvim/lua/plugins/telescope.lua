return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local builtin = require("telescope.builtin")

    telescope.setup({
      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
        },
      },
    })

    telescope.load_extension("fzf")

    -- set keymaps
    local tele = require 'telescope.builtin'

    require("which-key").add({
      { "<leader>f",  group = "[f]ind" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "[f]iles" },
      { "<leader>fs", "<cmd>Telescope live_grep<cr>", desc = "[s]tring" },
      { "<leader>fc", "<cmd>Telescope grep_string<cr>", desc = "[c]urrent" },
      { "<leader>fr", "<cmd>Telescope resume<cr>", desc = "[r]esume" },
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "[t]odo" },
      { "<leader>fm", 
        function()
          tele.man_pages({ sections = { "1", "2", "3" } })
        end, 
        desc = "[m]an page" },
    })
  end,
}
