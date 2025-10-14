return {
  {
    "neovim/nvim-lspconfig",
    lazy = true,
    opts = {
      -- make sure mason installs the server
      servers = {
        jdtls = {},
      },
      setup = {
        jdtls = function()
          return true -- avoid duplicate servers
        end,
      },
    },
    event = { "BufReadPre", "BufNewFile" }, -- loads for new files or new buffers
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp" },
      { "SmiteshP/nvim-navic" },
      { "p00f/clangd_extensions.nvim" },
      { "lukas-reineke/lsp-format.nvim" },
    },
    config = function()
      local keymap = vim.keymap -- for conciseness

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          local opts = {  }

          -- set keybinds
          require 'which-key'.add({
            { "gR", "<cmd>Telescope lsp_references<CR>", desc = "Show LSP references", buffer = ev.buf, silent = true }, -- show definition, references
            { "gD", vim.lsp.buf.declaration, desc = "Go to declaration", buffer = ev.buf, silent = true }, -- go to declaration
            { "gd", "<cmd>Telescope lsp_definitions<CR>", desc = "Show LSP definitions", buffer = ev.buf, silent = true }, -- show lsp definitions
            { "gi", "<cmd>Telescope lsp_implementations<CR>", desc = "Show LSP implementations", buffer = ev.buf, silent = true }, -- show lsp implementations
            { "gt", "<cmd>Telescope lsp_type_definitions<CR>", desc = "Show LSP type definitions", buffer = ev.buf, silent = true }, -- show lsp type definitions
            { "<leader>ca", vim.lsp.buf.code_action, desc = "See available code actions", buffer = ev.buf, silent = true }, -- see available code actions, in visual mode will apply to selection
            { "<leader>rn", vim.lsp.buf.rename, desc = "Smart rename", buffer = ev.buf, silent = true }, -- smart rename
            { "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", desc = "Show buffer diagnostics", buffer = ev.buf, silent = true }, -- show  diagnostics for file
            { "<leader>d", vim.diagnostic.open_float, desc = "Show buffer diagnostics", buffer = ev.buf, silent = true }, -- show  diagnostics for file
            { "[d", vim.diagnostic.goto_prev, desc = "Go to previous diagnostic", buffer = ev.buf, silent = true }, -- jump to previous diagnostic in buffer
            { "]d", vim.diagnostic.goto_next, desc = "Go to next diagnostic", buffer = ev.buf, silent = true }, -- jump to next diagnostic in buffer
            { "K", vim.lsp.buf.hover, desc = "Show documentation for what is under cursor", buffer = ev.buf, silent = true }, -- show documentation for what is under cursor
            { "<leader>lr", ":LspRestart<CR>", desc = "Restart LSP", buffer = ev.buf, silent = true }, -- mapping to restart lsp if necessary
          })
        end,
      })
      -- Error icons
      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }

      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      vim.lsp.enable({
        'clangd',
        'gopls',
        'html',
        'lua_ls',
        'pyright',
      })

      vim.lsp.config('lua_ls', {

        settings = { -- custom settings for lua
          Lua = {
            -- make the language server recognize "vim" global
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              -- make language server aware of runtime files
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
              },
            },
          },
        },
      })
    end,
  }
}
