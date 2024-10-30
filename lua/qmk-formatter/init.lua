local M = {}

M.format = function()
	local query_string = [[
        (
             (identifier) @identifier (#eq? @identifier "LAYOUT_split_3x5_2")
             (argument_list) @arguments
        )
    ]]

	local language_tree = require("nvim-treesitter.parsers").get_parser()
	local Query = require("vim.treesitter.query")
	local ok, query = pcall(Query.new, language_tree:lang(), query_string)
	print(ok)
	print(query)
	if not ok then
		return
	end

	local syntax_tree = language_tree:parse()
	local root = syntax_tree[1]:root()

	local run_formatter = function(text)
		local script_path = vim.fn.stdpath("data") .. "/lazy/qmk-formatter.nvim"
		local command =
			string.format("%s/qmk-formatter -i %s", vim.fn.shellescape(script_path), vim.fn.shellescape(text))
		local formatted = vim.fn.systemlist(command)
		return formatted
	end

	local changes = {}

	for _, match in query:iter_matches(root, 0) do
		for _, node in pairs(match) do
			if node:type() == "argument_list" then
				local text = vim.treesitter.query.get_node_text(node, 0)

				local row1, col1, row2, col2 = node:range()

				local formatted = run_formatter(text)

				for i, line in ipairs(formatted) do
					formatted[i] = "\t\t" .. line
				end

				table.insert(formatted, 1, "(")
				table.insert(formatted, "\t)")

				table.insert(changes, 1, {
					formatted = formatted,
					row1 = row1,
					col1 = col1,
					row2 = row2,
					col2 = col2,
				})
			end
		end
	end

	for _, change in ipairs(changes) do
		vim.api.nvim_buf_set_text(0, change.row1, change.col1, change.row2, change.col2, change.formatted)
	end
end

M.setup = function(opts)
	vim.api.nvim_create_user_command("QmkFormat", function()
		M.format()
	end, {})
end

return M
