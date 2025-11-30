-- C snippets for LuaSnip
-- Place this file in: ~/.config/nvim/LuaSnip/c.lua
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

-- Helper function to get filename without extension
local function get_filename()
  local filename = vim.fn.expand("%:t:r")
  return filename:upper()
end

-- Helper function to get current date
local function get_date()
  return os.date("%Y-%m-%d")
end

-- Helper function to get current year
local function get_year()
  return os.date("%Y")
end

return {
  -- ============================================================
  -- MAIN FUNCTION & PROGRAM STRUCTURE
  -- ============================================================

  -- Basic main function
  s("main", fmt([[
int main(void) {{
	{}
	return 0;
}}
]], { i(1) })),

  -- Main with arguments
  s("maina", fmt([[
int main(int argc, char *argv[]) {{
	{}
	return 0;
}}
]], { i(1) })),

  -- Complete program template
  s("prog", fmt([[
#include <stdio.h>
#include <stdlib.h>

int main(void) {{
	{}
	return 0;
}}
]], { i(1) })),

  -- Complete program with args
  s("proga", fmt([[
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {{
	if (argc < {}) {{
		fprintf(stderr, "Usage: %s {}\n", argv[0]);
		return 1;
	}}

	{}
	return 0;
}}
]], {
    i(1, "2"),
    i(2, "<arg>"),
    i(3)
  })),

  -- ============================================================
  -- PREPROCESSOR DIRECTIVES
  -- ============================================================

  -- Include standard library
  s("inc", fmt("#include <{}>", { i(1, "stdio.h") })),

  -- Include custom header
  s("inc\"", fmt('#include "{}"', { i(1, "header.h") })),

  -- Define macro
  s("def", fmt("#define {} {}", {
    i(1, "MACRO"),
    i(2, "value")
  })),

  -- Header guard
  s("guard", fmt([[
#ifndef {}_H
#define {}_H

{}

#endif /* {}_H */
]], {
    f(function() return get_filename() end, {}),
    f(function() return get_filename() end, {}),
    i(1),
    f(function() return get_filename() end, {})
  })),

  -- Pragma once
  s("pragma", t("#pragma once")),

  -- Ifdef block
  s("ifdef", fmt([[
#ifdef {}
{}
#endif
]], {
    i(1, "MACRO"),
    i(2)
  })),

  -- Ifndef block
  s("ifndef", fmt([[
#ifndef {}
{}
#endif
]], {
    i(1, "MACRO"),
    i(2)
  })),

  -- ============================================================
  -- CONTROL STRUCTURES
  -- ============================================================

  -- If statement
  s("if", fmt([[
if ({}) {{
	{}
}}
]], {
    i(1, "condition"),
    i(2)
  })),

  -- If-else
  s("ife", fmt([[
if ({}) {{
	{}
}} else {{
	{}
}}
]], {
    i(1, "condition"),
    i(2),
    i(3)
  })),

  -- If-else if-else
  s("ifel", fmt([[
if ({}) {{
	{}
}} else if ({}) {{
	{}
}} else {{
	{}
}}
]], {
    i(1, "condition1"),
    i(2),
    i(3, "condition2"),
    i(4),
    i(5)
  })),

  -- Switch statement
  s("switch", fmt([[
switch ({}) {{
	case {}:
		{}
		break;
	case {}:
		{}
		break;
	default:
		{}
		break;
}}
]], {
    i(1, "expression"),
    i(2, "value1"),
    i(3),
    i(4, "value2"),
    i(5),
    i(6)
  })),

  -- Case statement
  s("case", fmt([[
case {}:
	{}
	break;
]], {
    i(1, "value"),
    i(2)
  })),

  -- Ternary operator
  s("tern", fmt("{} ? {} : {}", {
    i(1, "condition"),
    i(2, "true_value"),
    i(3, "false_value")
  })),

  -- ============================================================
  -- LOOPS
  -- ============================================================

  -- For loop
  s("for", fmt([[
for ({} {} = {}; {} < {}; {}++) {{
	{}
}}
]], {
    i(1, "int"),
    i(2, "i"),
    i(3, "0"),
    rep(2),
    i(4, "n"),
    rep(2),
    i(5)
  })),

  -- For loop (decreasing)
  s("ford", fmt([[
for ({} {} = {}; {} >= {}; {}--) {{
	{}
}}
]], {
    i(1, "int"),
    i(2, "i"),
    i(3, "n"),
    rep(2),
    i(4, "0"),
    rep(2),
    i(5)
  })),

  -- While loop
  s("while", fmt([[
while ({}) {{
	{}
}}
]], {
    i(1, "condition"),
    i(2)
  })),

  -- Do-while loop
  s("do", fmt([[
do {{
	{}
}} while ({});
]], {
    i(1),
    i(2, "condition")
  })),

  -- ============================================================
  -- FUNCTIONS
  -- ============================================================

  -- Function definition
  s("func", fmt([[
{} {}({}) {{
	{}
}}
]], {
    i(1, "void"),
    i(2, "function_name"),
    i(3, "void"),
    i(4)
  })),

  -- Function prototype
  s("funcp", fmt("{} {}({});", {
    i(1, "void"),
    i(2, "function_name"),
    i(3, "void")
  })),

  -- Static function
  s("sfunc", fmt([[
static {} {}({}) {{
	{}
}}
]], {
    i(1, "void"),
    i(2, "function_name"),
    i(3, "void"),
    i(4)
  })),

  -- ============================================================
  -- STRUCTS & TYPEDEFS
  -- ============================================================

  -- Struct definition
  s("struct", fmt([[
struct {} {{
	{}
}};
]], {
    i(1, "name"),
    i(2, "int member;")
  })),

  -- Typedef struct
  s("tds", fmt([[
typedef struct {} {{
	{}
}} {};
]], {
    i(1, "name"),
    i(2, "int member;"),
    rep(1)
  })),

  -- Typedef struct (anonymous)
  s("tdsa", fmt([[
typedef struct {{
	{}
}} {};
]], {
    i(1, "int member;"),
    i(2, "name_t")
  })),

  -- Enum
  s("enum", fmt([[
enum {} {{
	{}
}};
]], {
    i(1, "name"),
    i(2, "VALUE1, VALUE2")
  })),

  -- Typedef enum
  s("tde", fmt([[
typedef enum {} {{
	{}
}} {};
]], {
    i(1, "name"),
    i(2, "VALUE1, VALUE2"),
    rep(1)
  })),

  -- Union
  s("union", fmt([[
union {} {{
	{}
}};
]], {
    i(1, "name"),
    i(2, "int member;")
  })),

  -- ============================================================
  -- MEMORY MANAGEMENT
  -- ============================================================

  -- Malloc
  s("malloc", fmt("{} *{} = ({} *)malloc(sizeof({}) * {});", {
    i(1, "type"),
    i(2, "ptr"),
    rep(1),
    rep(1),
    i(3, "count")
  })),

  -- Calloc
  s("calloc", fmt("{} *{} = ({} *)calloc({}, sizeof({}));", {
    i(1, "type"),
    i(2, "ptr"),
    rep(1),
    i(3, "count"),
    rep(1)
  })),

  -- Realloc
  s("realloc", fmt("{} = ({} *)realloc({}, sizeof({}) * {});", {
    i(1, "ptr"),
    i(2, "type"),
    rep(1),
    rep(2),
    i(3, "new_count")
  })),

  -- Free
  s("free", fmt([[
free({});
{} = NULL;
]], {
    i(1, "ptr"),
    rep(1)
  })),

  -- ============================================================
  -- INPUT/OUTPUT
  -- ============================================================

  -- Printf
  s("printf", fmt('printf("{}\\n"{});', {
    i(1, "%d"),
    i(2)
  })),

  -- Fprintf
  s("fprintf", fmt('fprintf({}, "{}\\n"{});', {
    i(1, "stderr"),
    i(2, "%s"),
    i(3)
  })),

  -- Scanf
  s("scanf", fmt('scanf("{}", {});', {
    i(1, "%d"),
    i(2, "&var")
  })),

  -- Fopen
  s("fopen", fmt('FILE *{} = fopen("{}", "{}");', {
    i(1, "fp"),
    i(2, "filename"),
    i(3, "r")
  })),

  -- Fopen with error check
  s("fopenck", fmt([[
FILE *{} = fopen("{}", "{}");
if ({} == NULL) {{
	perror("fopen");
	return 1;
}}
]], {
    i(1, "fp"),
    i(2, "filename"),
    i(3, "r"),
    rep(1)
  })),

  -- Fclose
  s("fclose", fmt("fclose({});", { i(1, "fp") })),

  -- ============================================================
  -- STRING OPERATIONS
  -- ============================================================

  -- Strlen
  s("strlen", fmt("strlen({})", { i(1, "str") })),

  -- Strcpy
  s("strcpy", fmt("strcpy({}, {});", {
    i(1, "dest"),
    i(2, "src")
  })),

  -- Strncpy
  s("strncpy", fmt("strncpy({}, {}, {});", {
    i(1, "dest"),
    i(2, "src"),
    i(3, "n")
  })),

  -- Strcmp
  s("strcmp", fmt("strcmp({}, {})", {
    i(1, "str1"),
    i(2, "str2")
  })),

  -- Strcat
  s("strcat", fmt("strcat({}, {});", {
    i(1, "dest"),
    i(2, "src")
  })),

  -- ============================================================
  -- COMMON PATTERNS
  -- ============================================================

  -- Error checking pattern
  s("errck", fmt([[
if ({} < 0) {{
	perror("{}");
	return 1;
}}
]], {
    i(1, "ret"),
    i(2, "operation")
  })),

  -- Assert
  s("assert", fmt('assert({} && "{}");', {
    i(1, "condition"),
    i(2, "error message")
  })),

  -- Todo comment
  s("todo", fmt("/* TODO: {} */", { i(1, "description") })),

  -- Fixme comment
  s("fixme", fmt("/* FIXME: {} */", { i(1, "description") })),

  -- Block comment
  s("/*", fmt([[
/*
 * {}
 */
]], { i(1) })),

  -- Function comment block
  s("fcom", fmt([[
/**
 * {} - {}
 * @{}: {}
 *
 * Return: {}
 */
]], {
    i(1, "function_name"),
    i(2, "brief description"),
    i(3, "param"),
    i(4, "parameter description"),
    i(5, "return value description")
  })),

  -- File header comment
  s("fhead", fmt([[
/**
 * File: {}
 * Author: {}
 * Date: {}
 * Description: {}
 */
]], {
    f(function() return vim.fn.expand("%:t") end, {}),
    i(1, "Your Name"),
    f(function() return get_date() end, {}),
    i(2, "File description")
  })),

  -- ============================================================
  -- ARRAYS
  -- ============================================================

  -- Array declaration
  s("arr", fmt("{} {}[{}];", {
    i(1, "int"),
    i(2, "array"),
    i(3, "SIZE")
  })),

  -- Array initialization
  s("arri", fmt("{} {}[] = {{{}}};", {
    i(1, "int"),
    i(2, "array"),
    i(3, "1, 2, 3")
  })),

  -- 2D array
  s("arr2d", fmt("{} {}[{}][{}];", {
    i(1, "int"),
    i(2, "matrix"),
    i(3, "ROWS"),
    i(4, "COLS")
  })),

  -- ============================================================
  -- POINTERS
  -- ============================================================

  -- Pointer declaration
  s("ptr", fmt("{} *{};", {
    i(1, "type"),
    i(2, "ptr")
  })),

  -- Pointer to pointer
  s("ptrptr", fmt("{} **{};", {
    i(1, "type"),
    i(2, "ptr")
  })),

  -- NULL check
  s("nullck", fmt([[
if ({} == NULL) {{
	{}
}}
]], {
    i(1, "ptr"),
    i(2, "return NULL;")
  })),

  -- ============================================================
  -- COMMON ALGORITHMS
  -- ============================================================

  -- Swap
  s("swap", fmt([[
{} temp = {};
{} = {};
{} = temp;
]], {
    i(1, "int"),
    i(2, "a"),
    rep(2),
    i(3, "b"),
    rep(3)
  })),

  -- Min/Max
  s("min", fmt("{} min = ({} < {}) ? {} : {};", {
    i(1, "int"),
    i(2, "a"),
    i(3, "b"),
    rep(2),
    rep(3)
  })),

  s("max", fmt("{} max = ({} > {}) ? {} : {};", {
    i(1, "int"),
    i(2, "a"),
    i(3, "b"),
    rep(2),
    rep(3)
  })),

  -- ============================================================
  -- DEBUGGING & TESTING
  -- ============================================================

  -- Debug print
  s("debug", fmt('#ifdef DEBUG\nprintf("DEBUG: {}\\n"{});\n#endif', {
    i(1, "%s"),
    i(2)
  })),

  -- Print variable (debug)
  s("pvar", fmt('printf("{} = %{}\\n", {});', {
    i(1, "var"),
    i(2, "d"),
    rep(1)
  })),

  -- ============================================================
  -- LICENSE HEADERS
  -- ============================================================

  -- MIT License header
  s("licmit", fmt([[
/*
 * Copyright (c) {} {}
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
]], {
    f(function() return get_year() end, {}),
    i(1, "Your Name")
  })),

  -- GPL License header
  s("licgpl", fmt([[
/*
 * Copyright (C) {} {}
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
]], {
    f(function() return get_year() end, {}),
    i(1, "Your Name")
  })),
}
