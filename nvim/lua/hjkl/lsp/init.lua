local neodev = vim.F.npcall(require, "neodev")
if neodev then
  neodev.setup {
    override = function(root_dir, library)
      library.enabled = true
      library.plugins = true
    end,
  }
end

local semantic = vim.F.npcall(require, "nvim-semantic-tokens")

local is_linux = vim.fn.has "Linux" == 1

local lspconfig = vim.F.npcall(require, "lspconfig")
if not lspconfig then
  return
end

local imap = require("hjkl.keymap").imap
local nmap = require("hjkl.keymap").nmap
local autocmd = require("hjkl.auto").autocmd
local autocmd_clear = vim.api.nvim_clear_autocmds



local lspconfig_util = require "lspconfig.util"

-- local telescope_mapper = require "hjkl.telescope.mappings"
-- local handlers = require "hjkl.lsp.handlers"

local inlays = require "hjkl.lsp.inlay"

local custom_init = function(client)
  client.config.flags = client.config.flags or {}
  client.config.flags.allow_incremental_sync = true
end

local buf_nnoremap = function(opts)
  if opts[3] == nil then
    opts[3] = {}
  end
  opts[3].buffer = 0

  nmap(opts)
end

local buf_inoremap = function(opts)
  if opts[3] == nil then
    opts[3] = {}
  end
  opts[3].buffer = 0

  imap(opts)
end

local custom_attach = function(client, bufnr)
    if client.nvim == "copilot" then
        return
    end

  local filetype = vim.api.nvim_buf_get_option(0, "filetype")

  buf_inoremap { "<c-s>", vim.lsp.buf.signature_help }
  buf_nnoremap { "<space>cr", vim.lsp.buf.rename }
  buf_nnoremap { "<space>ca", vim.lsp.buf.code_action }

  buf_nnoremap { "gd", vim.lsp.buf.definition }
  buf_nnoremap { "gD", vim.lsp.buf.declaration }
  buf_nnoremap { "gT", vim.lsp.buf.type_definition }
  buf_nnoremap { "K", vim.lsp.buf.hover, { desc = "lsp:hover" } }

  buf_nnoremap { "<space>rr", "LspRestart" }

  -- telescope_mapper("gr", "lsp_references", nil, true)
  -- telescope_mapper("gI", "lsp_implementations", nil, true)
  -- telescope_mapper("<space>wd", "lsp_document_symbols", { ignore_filename = true }, true)
  -- telescope_mapRestartper("<space>ww", "lsp_dynamic_workspace_symbols", { ignore_filename = true }, true)


  -- Set autocommands conditional on server_capabilities
  if client.server_capabilities.documentHighlightProvider then
    autocmd_clear { group = augroup_highlight, buffer = bufnr }
    autocmd { "CursorHold", augroup_highlight, vim.lsp.buf.document_highlight, bufnr }
    autocmd { "CursorMoved", augroup_highlight, vim.lsp.buf.clear_references, bufnr }
  end

  if false and client.server_capabilities.codeLensProvider then
    if filetype ~= "elm" then
      autocmd_clear { group = augroup_codelens, buffer = bufnr }
      autocmd { "BufEnter", augroup_codelens, vim.lsp.codelens.refresh, bufnr, once = true }
      autocmd { { "BufWritePost", "CursorHold" }, augroup_codelens, vim.lsp.codelens.refresh, bufnr }
    end
  end

  local caps = client.server_capabilities
  if semantic and caps.semanticTokensProvider and caps.semanticTokensProvider.full then
    autocmd_clear { group = augroup_semantic, buffer = bufnr }
    autocmd { "TextChanged", augroup_semantic, vim.lsp.buf.semantic_tokens_full, bufnr }
  end

  -- Attach any filetype specific options to the client
end

local updated_capabilities = vim.lsp.protocol.make_client_capabilities()

-- Completion configuration
vim.tbl_deep_extend("force", updated_capabilities, require("cmp_nvim_lsp").default_capabilities())
updated_capabilities.textDocument.completion.completionItem.insertReplaceSupport = false

-- Semantic token configuration
if semantic then
  semantic.setup {
    preset = "default",
    highlighters = { require "nvim-semantic-tokens.table-highlighter" },
  }

  semantic.extend_capabilities(updated_capabilities)
end

updated_capabilities.textDocument.codeLens = { dynamicRegistration = false }

local servers = {
  -- Also uses `shellcheck` and `explainshell`
  bashls = true,

  -- graphql = true,
  pyright = true,
  vimls = true,

  -- TODO: Test the other Ruby LSPs?
  -- solargraph = { cmd = { "bundle", "exec", "solargraph", "stdio" } },
  -- sorbet = true,

  cmake = (1 == vim.fn.executable "cmake-language-server"),

  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--suggest-missing-includes",
      "--clang-tidy",
      "--header-insertion=iwyu",
    },
    init_options = {
      clangdFileStatus = true,
    },
  },

}



  require("mason").setup()

  local setup_server = function(server, config)
  if not config then
    return
  end

  if type(config) ~= "table" then
    config = {}
  end

  config = vim.tbl_deep_extend("force", {
    on_init = custom_init,
    on_attach = custom_attach,
    capabilities = updated_capabilities,
    flags = {
      debounce_text_changes = nil,
    },
  }, config)

  lspconfig[server].setup(config)
end



if is_linux then

  Lua_ls_cmd = {
    vim.fn.stdpath "data" .. "/lsp_server/lua-language-server/bin/lua-language-server",
  }


  setup_server("lua_ls", {
    settings = {
      Lua = {
        diagnostics = {
          globals = {
            -- vim
            "vim",

            -- Busted
            "describe",
            "it",
            "before_each",
            "after_each",
            "teardown",
            "pending",
            "clear",

            -- Colorbuddy
            "Color",
            "c",
            "Group",
            "g",
            "s",

            -- Custom
            "RELOAD",
          },
        },

        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
        },
      },
    },
  })
else
  -- Load lua configuration from nlua.
  require("lspconfig").sumneko_lua.setup {
    on_init = custom_init,
    on_attach = custom_attach,
    capabilities = updated_capabilities,
    settings = {
      Lua = { workspace = { checkThirdParty = false }, semantic = { enable = false } },
    },
  }
end


for server, config in pairs(servers) do
    setup_server(server, config)
end

