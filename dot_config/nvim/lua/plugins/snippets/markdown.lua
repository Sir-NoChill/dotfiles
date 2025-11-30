-- Markdown snippets for LuaSnip Place this file in: ~/.config/nvim/LuaSnip/markdown.lua
-- or wherever your LuaSnip snippets directory is configured

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

-- Helper function to get visual selection
local get_visual = function(args, parent)
  if (#parent.snippet.env.LS_SELECT_RAW > 0) then
    return sn(nil, i(1, parent.snippet.env.LS_SELECT_RAW))
  else
    return sn(nil, i(1, ''))
  end
end

-- Helper function to transform text to title case
local function titlecase(str)
  return str:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper()..rest:lower()
  end)
end

-- Helper to get current date
local function get_date()
  return os.date("%Y-%m-%d")
end

-- Helper to get current date with day name
local function get_date_with_day()
  return os.date("%Y-%m-%d %a")
end

return {
  -- ============================================================
  -- HEADINGS
  -- ============================================================

  s("h1", fmt("# {}", { i(1, "Header") })),
  s("h2", fmt("## {}", { i(1, "Header") })),
  s("h3", fmt("### {}", { i(1, "Header") })),
  s("h4", fmt("#### {}", { i(1, "Header") })),
  s("h5", fmt("##### {}", { i(1, "Header") })),
  s("h6", fmt("###### {}", { i(1, "Header") })),

  -- ============================================================
  -- LINKS & IMAGES
  -- ============================================================

  -- Basic link
  s("link", fmt("[{}]({})", {
    i(1, "text"),
    i(2, "url")
  })),

  -- Link with title
  s("linkt", fmt('[{}]({} "{}")', {
    i(1, "text"),
    i(2, "url"),
    i(3, "title")
  })),

  -- Reference link
  s("linkr", {
    t("["), i(1, "text"), t("]["), i(2, "ref"), t("]"),
  }),

  -- Link definition
  s("linkd", fmt("[{}]: {}", {
    i(1, "ref"),
    i(2, "url")
  })),

  -- Wrap selection in link (use visual selection with <C-s>)
  s("wlink", fmt("[{}]({})", {
    i(1),
    d(2, get_visual, {})
  })),

  -- Basic image
  s("img", fmt("![{}]({})", {
    i(1, "alt text"),
    i(2, "path/to/image")
  })),

  -- Image with title
  s("imgt", fmt('![{}]({} "{}")', {
    i(1, "alt text"),
    i(2, "path/to/image"),
    i(3, "title")
  })),

  -- ============================================================
  -- TEXT FORMATTING
  -- ============================================================

  -- Bold
  s("bold", fmt("**{}**", { i(1, "bold text") })),
  s("b", fmt("**{}**", { i(1) })),

  -- Italic
  s("italic", fmt("*{}*", { i(1, "italic text") })),
  s("i", fmt("*{}*", { i(1) })),

  -- Bold + Italic
  s("bi", fmt("***{}***", { i(1, "bold italic text") })),

  -- Inline code
  s("code", fmt("`{}`", { i(1, "code") })),
  s("c", fmt("`{}`", { i(1) })),

  -- Strikethrough
  s("strike", fmt("~~{}~~", { i(1, "strikethrough") })),

  -- Highlight (using mark syntax)
  s("mark", fmt("=={}", { i(1, "highlighted text") })),

  -- ============================================================
  -- CODE BLOCKS
  -- ============================================================

  -- Fenced code block
  s("code3", fmt([[
```{}
{}
```
]], {
    i(1, "language"),
    i(2, "code")
  })),

  -- Common language code blocks
  s("codepy", fmt([[
```python
{}
```
]], { i(1) })),

  s("codejs", fmt([[
```javascript
{}
```
]], { i(1) })),

  s("codebash", fmt([[
```bash
{}
```
]], { i(1) })),

  s("codelua", fmt([[
```lua
{}
```
]], { i(1) })),

  -- ============================================================
  -- LISTS
  -- ============================================================

  -- Unordered list item
  s("ul", fmt("- {}", { i(1) })),

  -- Ordered list item
  s("ol", fmt("1. {}", { i(1) })),

  -- Task list item
  s("task", fmt("- [ ] {}", { i(1) })),
  s("taskd", fmt("- [x] {}", { i(1) })),

  -- ============================================================
  -- QUOTES & CALLOUTS
  -- ============================================================

  -- Blockquote
  s("quote", fmt("> {}", { i(1) })),
  s("bq", fmt("> {}", { i(1) })),

  -- Multi-line blockquote
  s("quote3", {
    t("> "), i(1), t({"", "> "}), i(2), t({"", "> "}), i(3)
  }),

  -- ============================================================
  -- TABLES
  -- ============================================================

  -- Simple 2-column table
  s("table2", {
    t("| "), i(1, "Header 1"), t(" | "), i(2, "Header 2"), t(" |"),
    t({"", "| --- | --- |"}),
    t({"", "| "}), i(3), t(" | "), i(4), t(" |"),
  }),

  -- 3-column table
  s("table3", {
    t("| "), i(1, "Header 1"), t(" | "), i(2, "Header 2"), t(" | "), i(3, "Header 3"), t(" |"),
    t({"", "| --- | --- | --- |"}),
    t({"", "| "}), i(4), t(" | "), i(5), t(" | "), i(6), t(" |"),
  }),

  -- ============================================================
  -- HORIZONTAL RULES
  -- ============================================================

  s("hr", t("---")),
  s("rule", t("---")),

  -- ============================================================
  -- YAML FRONTMATTER
  -- ============================================================

  -- Basic frontmatter
  s("meta", fmt([[
---
title: {}
date: {}
---

]], {
    i(1, "Title"),
    f(function() return get_date() end, {})
  })),

  -- Blog post frontmatter
  s("metablog", fmt([[
---
title: {}
date: {}
author: {}
tags: [{}]
---

]], {
    i(1, "Title"),
    f(function() return get_date() end, {}),
    i(2, "Author"),
    i(3, "tag1, tag2")
  })),

  -- Obsidian-style frontmatter
  s("metaobs", fmt([[
---
title: {}
created: {}
tags: [{}]
aliases: [{}]
---

]], {
    i(1, "Title"),
    f(function() return get_date() end, {}),
    i(2, "tag1, tag2"),
    i(3)
  })),

  -- ============================================================
  -- SPECIAL ELEMENTS
  -- ============================================================

  -- Footnote reference
  s("fn", fmt("[^{}]", { i(1, "1") })),

  -- Footnote definition
  s("fndef", fmt("[^{}]: {}", {
    i(1, "1"),
    i(2, "footnote text")
  })),

  -- HTML details/summary (collapsible)
  s("details", fmt([[
<details>
<summary>{}</summary>

{}

</details>
]], {
    i(1, "Summary"),
    i(2, "Content")
  })),

  -- ============================================================
  -- DATE/TIME SNIPPETS
  -- ============================================================

  -- Current date (YYYY-MM-DD)
  s("date", {
    f(function() return get_date() end, {})
  }),

  -- Current date with day name
  s("dateday", {
    f(function() return get_date_with_day() end, {})
  }),

  -- Timestamp
  s("time", {
    f(function() return os.date("%H:%M") end, {})
  }),

  -- Full datetime
  s("datetime", {
    f(function() return os.date("%Y-%m-%d %H:%M:%S") end, {})
  }),

  -- Bullet journal style date header
  s("bjtoday", fmt("# {}", {
    f(function() return get_date_with_day() end, {})
  })),

  -- ============================================================
  -- MATHEMATICAL EXPRESSIONS
  -- ============================================================

  -- Inline math
  s("math", fmt("${}$", { i(1) })),
  s("$", fmt("${}$", { i(1) })),

  -- Display math
  s("dm", fmt([[
$$
{}
$$
]], { i(1) })),

  s("$$", fmt([[
$$
{}
$$
]], { i(1) })),

  -- ============================================================
  -- COMMON PATTERNS
  -- ============================================================

  -- TODO item
  s("todo", fmt("- [ ] TODO: {}", { i(1) })),

  -- Note callout
  s("note", fmt([[
> [!NOTE]
> {}
]], { i(1) })),

  -- Warning callout
  s("warn", fmt([[
> [!WARNING]
> {}
]], { i(1) })),

  -- Important callout
  s("important", fmt([[
> [!IMPORTANT]
> {}
]], { i(1) })),

  -- Tip callout
  s("tip", fmt([[
> [!TIP]
> {}
]], { i(1) })),

  -- Divider with text
  s("divider", fmt([[
<!-- {} -->
---
]], { i(1, "Section") })),

  -- HTML comment
  s("comment", fmt("<!-- {} -->", { i(1) })),

  -- Embed/transclude (Obsidian style)
  s("embed", fmt("![[{}]]", { i(1, "filename") })),

  -- Wikilink (Obsidian/Wiki style)
  s("wikilink", fmt("[[{}]]", { i(1, "page") })),

  -- Wikilink with alias
  s("wikialt", fmt("[[{}|{}]]", {
    i(1, "page"),
    i(2, "alias")
  })),
}
