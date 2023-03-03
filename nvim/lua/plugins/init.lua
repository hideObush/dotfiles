return{
    {
        "folke/tokyonight.nvim",
        lazy = false ,
        priority = 1000,
        config = function()
            vim.cmd([[colorscheme tokyonight]])
        end,
    },
    "tpope/vim-surround",
    "godlygeek/tabular",
    "tpope/vim-repeat",
    "tpope/vim-characterize",
    "romainl/vim-qf",
    "romgrk/barbar.nvim",
    "nvim-tree/nvim-web-devicons",
    "neovide/neovide",

    {
    'glacambre/firenvim',

    -- Lazy load firenvim
    -- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
    cond = not not vim.g.started_by_firenvim,
    build = function()
        require("lazy").load({ plugins = "firenvim", wait = true })
        vim.fn["firenvim#install"](0)
    end
},
    "tjdevries/express_line.nvim"

    
    

}
