return {
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPre", "BufNewFile" },
  main = "ibl",
  opts = {
    enabled = true,
    indent = {
      char = '┆',
    },
    scope = {
      char = '│',
      show_start = false,
    }
  },
}
