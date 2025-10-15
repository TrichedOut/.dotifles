require "config.options"
require "config.lazy"
require "config.color"

vim.g.editorconfig = false
vim.api.nvim_set_keymap('n', '<F1>', '<nop>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<F1>', '<nop>', { noremap = true, silent = true })
