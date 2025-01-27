local M = {}
local api = vim.api

local function node_relative_path()
	local node = require('nvim-tree.api').tree.get_node_under_cursor()
	return vim.fn.fnamemodify(node.absolute_path, ':~:.')
end

local function search_in_path()
	opts = {}
	opts.default_text = '-g"' .. node_relative_path() .. '/**" "'
	require('telescope').extensions.live_grep_args.live_grep_args(opts)
end

local function find_in_path()
	vim.api.nvim_exec2('Telescope find_files cwd=' .. node_relative_path(), {})
end

local function git_hist_path()
	vim.fn.execute('DiffviewFileHistory ' .. node_relative_path())
end

-- Color scheme
table.insert(M, {
	'ofirgall/ofirkai.nvim',
	lazy = false, -- make sure we load this during startup if it is your main colorscheme
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function()
		if NVLOG then
			vim.o.termguicolors = true
			vim.cmd('colorscheme pablo')
			return
		end
		require('ofirkai').setup {
			scheme = {
				-- background = '#232323', -- Gray -5
				-- background = '#1e1e1e', -- Gray -10
				-- background = '#282923', -- Original
				-- background = '#252520', -- Original -5
				-- background = '#262620', -- Original -5, +1 for RG
				-- background = '#25251f', -- Original -6, +1 for RG
				background = '#23231d', -- Original -8, +1 for RG
				-- background = '#22221c', -- Original -9, +1 for RG
				-- background = '#21211b', -- Original -10, +1 for RG
				-- background = '#20201a', -- Original -11, +1 for RG

				winbar_bg = '#1d1d14', -- Original -5
			},
		}
	end,
})

-- Indent guides
table.insert(M, {
	'lukas-reineke/indent-blankline.nvim',
	event = { 'BufReadPost', 'BufNewFile' },
	opts = {
		use_treesitter = true,
		show_trailing_blankline_indent = false,
		space_char_blankline = ' ',
		show_current_context = true,
		show_current_context_start = false,
		context_highlight_list = { 'InlayHints' },
	},
	init = function()
		-- dots to indicate spaces
		vim.opt.list = true
		vim.opt.listchars:append('lead:⋅')
	end,
})

-- Add ui for default vim.ui.input
table.insert(M, {
	'stevearc/dressing.nvim',
	lazy = true,
	init = function()
		---@diagnostic disable-next-line: duplicate-set-field
		vim.ui.select = function(...)
			require('lazy').load({ plugins = { 'dressing.nvim' } })
			return vim.ui.select(...)
		end
		---@diagnostic disable-next-line: duplicate-set-field
		vim.ui.input = function(...)
			require('lazy').load({ plugins = { 'dressing.nvim' } })
			return vim.ui.input(...)
		end
	end,
	config = function()
		require('dressing').setup {
			input = {
				insert_only = false,
				start_in_insert = false,
				max_width = { 140, 0.9 },
				min_width = { 60, 0.2 },
				mappings = {
					n = {
						['q'] = 'Close',
						['<Esc>'] = 'Close',
						['<CR>'] = 'Confirm',
						['<C-p>'] = 'HistoryPrev',
						['<C-n>'] = 'HistoryNext',
					},
					i = {
						['<M-q>'] = 'Close',
						['<C-c>'] = 'Close',
						['<CR>'] = 'Confirm',
						['<Up>'] = 'HistoryPrev',
						['<Down>'] = 'HistoryNext',
						['<C-p>'] = 'HistoryPrev',
						['<C-n>'] = 'HistoryNext',
					},
				},
				win_options = {
					winblend = 0,
					winhighlight = require('ofirkai.plugins.dressing').winhighlight,
				},
			},
		}
	end,
})

-- File explorer
table.insert(M, {
	'kyazdani42/nvim-tree.lua',
	cmd = 'NvimTreeOpen',
	keys = {
		{
			'<M-m>',
			function()
				require('nvim-tree.api').tree.toggle()
			end,
			desc = 'Toggle file tree',
		},
		{
			'<M-M>',
			function()
				require('nvim-tree.api').tree.toggle({ find_file = true })
			end,
			desc = 'Locate file',
		},
	},
	deactivate = function()
		vim.cmd([[NvimTreeClose]])
	end,
	config = function()
		local function on_attach(bufnr)
			local tree_api = require('nvim-tree.api')
			tree_api.config.mappings.default_on_attach(bufnr)

			require('KoalaVim.utils.map').map_buffer(bufnr, 'n', '<Escape>', tree_api.node.navigate.parent_close,
				'Nvimtree: close node')
			require('KoalaVim.utils.map').map_buffer(bufnr, 'n', 'fw', search_in_path, 'Nvimtree: find word in current path')
			require('KoalaVim.utils.map').map_buffer(bufnr, 'n', 'ff', find_in_path, 'Nvimtree: find files in current path')
			require('KoalaVim.utils.map').map_buffer(bufnr, 'n', 'gh', git_hist_path, 'Nvimtree: view git history in current path')
		end

		require('nvim-tree').setup {
			on_attach = on_attach,
			view = {
				adaptive_size = true,
				relativenumber = true,
				number = false,
				signcolumn = 'no'
			},
			renderer = {
				symlink_destination = false,
				icons = {
					git_placement = 'after',
					modified_placement = 'after',
					glyphs = {
						git = {
							unstaged = '',
							staged = '',
							untracked = '',
							deleted = '',
						},
					},
				},
			},
		}
	end,
})

-- statusline
table.insert(M, {
	'nvim-lualine/lualine.nvim',
	event = 'VeryLazy',
	config = function()
		require('KoalaVim.utils.ui').setup_lualine(false)

		-- Refresh lualine for recording macros
		api.nvim_create_autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
			callback = require('lualine').refresh,
		})
	end,
})

-- Git blame (for status line)
table.insert(M, {
	'f-person/git-blame.nvim',
	event = 'VeryLazy',
	init = function()
		if vim.fn.has('wsl') == 1 then -- don't use git blame in wsl because of performance
			vim.g.gitblame_enabled = 0
		else
			vim.g.gitblame_display_virtual_text = 0
			vim.g.gitblame_message_template = '<author> • <date>'
			vim.g.gitblame_date_format = '%d/%m/%Y'
		end
	end,
})


-- Shows context in status line (with lsp)
table.insert(M, {
	'SmiteshP/nvim-navic',
	lazy = true,
	init = function()
		vim.g.navic_silence = true
	end,
	opts = function()
		return {
			separator = '  '
		}
	end,
})

-- bufferline
table.insert(M, {
	'akinsho/bufferline.nvim',
	event = 'VeryLazy',
	config = function()
		require('bufferline').setup {
			options = {
				separator_style = 'slant',
				offsets = { { filetype = 'NvimTree', text = 'File Explorer', text_align = 'center' } },
				show_buffer_icons = true,
				themable = true,
				numbers = 'ordinal',
				max_name_length = 40,
			},
			highlights = require('ofirkai.tablines.bufferline').highlights,
		}
	end,
})

-- Better `vim.notify()`
table.insert(M, {
	'rcarriga/nvim-notify',
	config = function()
		require('notify').setup {
			background_colour = require('ofirkai.design').scheme.ui_bg,
			fps = 60,
			stages = 'slide',
			timeout = 1000,
			max_width = 50,
			max_height = 20,
		}
	end,
})

-- Nice ui for notify, :messages, and better cmdline
table.insert(M, {
	'folke/noice.nvim',
	event = 'VeryLazy',
	config = function()
		require('noice').setup {
			popupmenu = {
				enabled = false,
			},
			lsp = {
				signature = {
					enabled = false, -- I prefer to use cmp-nvim-lsp-signature-help with minimal design
				},
				override = {
					-- Override `vim.lsp.buf.hover` and `nvim-cmp` doc formatter with `noice` doc formatter.
					['vim.lsp.util.convert_input_to_markdown_lines'] = true,
					['vim.lsp.util.stylize_markdown'] = true,
					['cmp.entry.get_documentation'] = true,
				},
			},
			routes = require('KoalaVim.misc.noice_routes'),
		}
	end,
	keys = {
		{
			'<c-u>',
			function()
				if not require('noice.lsp').scroll(-4) then
					return '<c-u>zz'
				end
			end,
			'Scroll up in hover',
			silent = true,
			expr = true,
		},
		{
			'<c-d>',
			function()
				if not require('noice.lsp').scroll(4) then
					return '<c-d>zz'
				end
			end,
			'Scroll down in hover',
			silent = true,
			expr = true,
		},
	},
})

-- Highlight current window seperator
table.insert(M, {
	'nvim-zh/colorful-winsep.nvim',
	config = function()
		local scheme = require('ofirkai.design').scheme
		require('colorful-winsep').setup {
			highlight = {
				bg = scheme.background,
				fg = scheme.vert_split_fg_active,
			},
		}
	end,
})

-- Floating bufferline
table.insert(M, {
	'b0o/incline.nvim',
	event = 'BufReadPre',
	config = function()
		require('incline').setup {
			render = function(props)
				local relative_name = vim.fn.fnamemodify(api.nvim_buf_get_name(props.buf), ':~:.')
				local filename = vim.fn.fnamemodify(api.nvim_buf_get_name(props.buf), ':t')
				local ft_icon, ft_color = require('nvim-web-devicons').get_icon_color(filename)
				local modified = vim.api.nvim_buf_get_option(props.buf, 'modified') and 'bold,italic' or 'bold'

				return {
					-- { get_diagnostic_label(props) },
					-- { get_git_diff(props) },
					{ ft_icon, guifg = ft_color }, { ' ' },
					{ relative_name, gui = modified },
				}
			end,
			window = {
				margin = {
					horizontal = 0,
					vertical = 0,
				},
				zindex = 4, -- Below NeoZoom.lua (5)
			},
			hide = {
				focused_win = true,
				only_win = true,
			},
		}
	end,
})

-- Status column line
table.insert(M, {
	'luukvbaal/statuscol.nvim',
	event = 'VeryLazy',
	opts = {
		setopt = true,
	},
})

-- icons
table.insert(M, {
	'kyazdani42/nvim-web-devicons',
	lazy = true,
})

-- ui components
table.insert(M, {
	'MunifTanjim/nui.nvim',
	lazy = true,
})

return M
