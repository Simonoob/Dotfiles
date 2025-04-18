local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

return {
  -- media query in styled componenent
  s(
    { trig = "@media", dscr = "media query" },
    fmta(
      [[
	@media ${(props) =>> props.theme.device.<>} {
		<>
	}
    ]],
      { i(1, "desktop"), i(0) }
    )
  ),
}
