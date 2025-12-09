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
            { "g",  group = "[g]o" },
            { "gR", "<cmd>Telescope lsp_references<CR>", desc = "[R]eferences", buffer = ev.buf, silent = true }, -- show definition, references
            { "gD", vim.lsp.buf.declaration, desc = "[D]eclarations", buffer = ev.buf, silent = true }, -- go to declaration
            { "gd", "<cmd>Telescope lsp_definitions<CR>", desc = "[d]efinitions", buffer = ev.buf, silent = true }, -- show lsp definitions
            { "gi", "<cmd>Telescope lsp_implementations<CR>", desc = "[i]mplementations", buffer = ev.buf, silent = true }, -- show lsp implementations
            { "gt", "<cmd>Telescope lsp_type_definitions<CR>", desc = "[t]ype definitions", buffer = ev.buf, silent = true }, -- show lsp type definitions
            { "<leader>c",  group = "[c]ode" },
            { "<leader>ca", vim.lsp.buf.code_action, desc = "[a]ctions", buffer = ev.buf, silent = true }, -- see available code actions, in visual mode will apply to selection
            { "<leader>r",  group = "[r]e-" },
            { "<leader>rn", vim.lsp.buf.rename, desc = "re[n]ame", buffer = ev.buf, silent = true }, -- smart rename
            { "<leader>rl", ":LspRestart<CR>", desc = "restart [l]sp", buffer = ev.buf, silent = true }, -- mapping to restart lsp if necessary
            { "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", desc = "[D]iagnose file", buffer = ev.buf, silent = true }, -- show  diagnostics for file
            { "<leader>d", vim.diagnostic.open_float, desc = "[d]iagnose line", buffer = ev.buf, silent = true }, -- show  diagnostics for file
            { "K", vim.lsp.buf.hover, desc = "do[k]umentation", buffer = ev.buf, silent = true }, -- show documentation for what is under cursor
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
