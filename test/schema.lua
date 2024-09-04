require "gn32/test/test"

require "gn32/schema"

test("schema", function()
	local sch = {
		nodefault     = {_type="number"},
		with_ge       = {_type="number", _default=10, _ge=1},
		with_gt       = {_type="number", _default=10, _gt=0},
		with_le       = {_type="number", _default=10,        _le=100},
		with_lt       = {_type="number", _default=10,        _lt=101},
		with_gele     = {_type="number", _default=10, _ge=1, _le=100},
		with_gelt     = {_type="number", _default=10, _ge=1, _lt=101},
		with_gtle     = {_type="number", _default=10, _gt=0, _le=100},
		with_gtlt     = {_type="number", _default=10, _gt=0, _lt=101},
		with_gtlt_dup = {_type="number", _default=10, _gt=0, _lt=101, _ge=0, _le=101},
		with_gele_dup = {_type="number", _default=10, _ge=1, _le=100, _gt=0, _lt=101},
		nested = {
			_type = "table",
			_default = function() return {foo="", bar=0} end,
			_fields = {
				foo = {_type="string"},
				bar = {_type="number"},
			}
		}
	}

	assert.equal(schema.checkTable({},                sch), "nodefault: field is required, expected number")
	assert.equal(schema.checkTable({nodefault="foo"}, sch), "nodefault: bad type string: expected number")
	assert.equal(schema.checkTable({nodefault=2},     sch), nil)

	local function doBoundsTest(field, lo, hi, expect)
		for _, d in ipairs{
			{v=0,   lo=false, hi=true},
			{v=1,   lo=true,  hi=true},
			{v=100, lo=true,  hi=true},
			{v=101, lo=true,  hi=false},
		} do
			local msg = nil
			if (lo and not d.lo) or (hi and not d.hi) then
				msg = field .. ": bad value " .. tostring(d.v) .. ": expected " .. expect
			end

			assert.equal(schema.checkTable({nodefault=2, [field]=d.v}, sch), msg)
		end
	end

	--           Field            Lo?    Hi?         Expect
	doBoundsTest("with_ge",       true,  false,     "value >= 1")
	doBoundsTest("with_gt",       true,  false,     "value > 0")
	doBoundsTest("with_le",       false, true,      "value <= 100")
	doBoundsTest("with_lt",       false, true,      "value < 101")
	doBoundsTest("with_gelt",     true,  true, "1 <= value < 101")
	doBoundsTest("with_gele",     true,  true, "1 <= value <= 100")
	doBoundsTest("with_gele_dup", true,  true, "1 <= value <= 100")
	doBoundsTest("with_gtle",     true,  true,  "0 < value <= 100")
	doBoundsTest("with_gtlt",     true,  true,  "0 < value < 101")
	doBoundsTest("with_gtlt_dup", true,  true,  "0 < value < 101")

	assert.equal(schema.checkTable({undef=1},                  sch), "undef: field not defined")

	assert.equal(schema.checkTable({nodefault=2, nested={foo=""}}, sch), "nested: bar: field is required, expected number")
	assert.equal(schema.checkTable({nodefault=2, nested={bar=0}},  sch), "nested: foo: field is required, expected string")
	assert.equal(schema.checkTable({nodefault=2, nested={baz=42}}, sch), "nested: baz: field not defined")

	local t = schema.makeTable(sch)

	t.nodefault = 42
	t.with_ge = 1
	t.with_le = 100
	t.nested = {foo="x", bar=2}

	assert.error(function() t.nodefault = "foo"  end, "./gn32/test/schema.lua:%d+: nodefault: bad type string: expected number")
	assert.error(function() t.with_ge = 0        end, "./gn32/test/schema.lua:%d+: with_ge: bad value 0: expected value >= 1")
	assert.error(function() t.with_le = 101      end, "./gn32/test/schema.lua:%d+: with_le: bad value 101: expected value <= 100")
	assert.error(function() t.nested = {foo="y"} end, "./gn32/test/schema.lua:%d+: nested: bar: field is required, expected number")
	assert.error(function() t.nested.foo = 3     end, "./gn32/test/schema.lua:%d+: nested%.foo: bad type number: expected string")
	assert.error(function() t.nested.baz = 4     end, "./gn32/test/schema.lua:%d+: nested%.baz: field not defined")

	assert.equal(t.nodefault, 42)
	assert.equal(t.with_ge, 1)
	assert.equal(t.with_le, 100)
	assert.equal(t.nested.foo, "x")
	assert.equal(t.nested.bar, 2)

	local t = schema.makeTable(sch)
	assert.equal(t.nodefault, nil)
	assert.equal(t.with_ge, 10)
	assert.equal(t.with_le, 10)
	assert.equal(t.nested.foo, "")
	assert.equal(t.nested.bar, 0)
end)
