require "gn32/test/test"

require "gn32/schema"

test("schema", function()
	local sch = {
		_fields = {
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
			},
			kv = {
				_type = "table",
				_default = function() return {} end,
				_keys = {_type = "string"},
				_values = {_type = "number"},
			},
			kvkv = {
				_type = "table",
				_default = function() return {} end,
				_keys = {_type = "string"},
				_values = {
					_type = "table",
					_keys = {_type = "string"},
					_values = {_type = "number"},
				},
			},
		}
	}

	assert.equal(schema.checkValue({},                sch), "nodefault: field is required, expected number")
	assert.equal(schema.checkValue({nodefault="foo"}, sch), "nodefault: bad type string: expected number")
	assert.equal(schema.checkValue({nodefault=2},     sch), nil)

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

			assert.equal(schema.checkValue({nodefault=2, [field]=d.v}, sch), msg)
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

	assert.equal(schema.checkValue({undef=1},                  sch), "undef: field not defined")

	assert.equal(schema.checkValue({nodefault=2, nested={foo=""}}, sch), "nested: bar: field is required, expected number")
	assert.equal(schema.checkValue({nodefault=2, nested={bar=0}},  sch), "nested: foo: field is required, expected string")
	assert.equal(schema.checkValue({nodefault=2, nested={baz=42}}, sch), "nested: baz: field not defined")

	assert.equal(schema.checkValue({nodefault=2, kv={foo="x", bar=2}}, sch), "kv: foo: bad type string: expected number")
	assert.equal(schema.checkValue({nodefault=2, kv={1, bar=2}}, sch), "kv: 1 (key): bad type number: expected string")
	assert.equal(schema.checkValue({nodefault=2, kv={foo=1, bar=2}}, sch), nil)
	assert.equal(schema.checkValue({nodefault=2, kvkv={foo={bar=2}, baz={stuff=3,more=4}}}, sch), nil)
	assert.equal(schema.checkValue({nodefault=2, kvkv={foo={bar=2}, baz=42}}, sch), "kvkv: baz: bad type number: expected table")
	assert.equal(schema.checkValue({nodefault=2, kvkv={foo={bar=2}, baz={stuff=3,more="x"}}}, sch), "kvkv: baz: more: bad type string: expected number")
	assert.equal(schema.checkValue({nodefault=2, kvkv={foo={bar=2}, baz={3, more=4}}}, sch), "kvkv: baz: 1 (key): bad type number: expected string")

	local t = schema.makeTable(sch)

	t.nodefault = 42
	t.with_ge = 1
	t.with_le = 100
	t.nested = {foo="x", bar=2}
	t.kv = {foo=1, bar=2}
	t.kvkv = {foo={bar=2}, baz={stuff=3,more=4}}
	t.kvkv = {foo={bar=2}}

	local ok = false
	for k1, v1 in pairs(t.kvkv) do
		assert.equal(k1, "foo")
		assert.equal(v1, t.kvkv.foo)
		for k2, v2 in pairs(v1) do
			assert.equal(k2, "bar")
			assert.equal(v2, 2)
			ok = true
		end
	end
	assert(ok, "did not hit expected iterations")

	assert.error(function() t.nodefault = "foo"  end, "./gn32/test/schema.lua:%d+: nodefault: bad type string: expected number")
	assert.error(function() t.with_ge = 0        end, "./gn32/test/schema.lua:%d+: with_ge: bad value 0: expected value >= 1")
	assert.error(function() t.with_le = 101      end, "./gn32/test/schema.lua:%d+: with_le: bad value 101: expected value <= 100")
	assert.error(function() t.nested = {foo="y"} end, "./gn32/test/schema.lua:%d+: nested: bar: field is required, expected number")
	assert.error(function() t.nested.foo = 3     end, "./gn32/test/schema.lua:%d+: nested%.foo: bad type number: expected string")
	assert.error(function() t.nested.baz = 4     end, "./gn32/test/schema.lua:%d+: nested%.baz: field not defined")
	assert.error(function() t.kv = {1}           end, "./gn32/test/schema.lua:%d+: kv.1 %(key%): bad type number: expected string")
	assert.error(function() t.kv.foo = "bar"     end, "./gn32/test/schema.lua:%d+: kv.foo: bad type string: expected number")
	assert.error(function() t.kv[1] = 1          end, "./gn32/test/schema.lua:%d+: kv.1 %(key%): bad type number: expected string")
	assert.error(function() t.kvkv = {f=1}       end, "./gn32/test/schema.lua:%d+: kvkv.f: bad type number: expected table")
	assert.error(function() t.kvkv = {f={1}}     end, "./gn32/test/schema.lua:%d+: kvkv.f: 1 %(key%): bad type number: expected string")
	assert.error(function() t.kvkv = {f={b="x"}} end, "./gn32/test/schema.lua:%d+: kvkv.f: b: bad type string: expected number")
	assert.error(function() t.kvkv.f = {1}       end, "./gn32/test/schema.lua:%d+: kvkv.f: 1 %(key%): bad type number: expected string")
	assert.error(function() t.kvkv.f = {b="x"}   end, "./gn32/test/schema.lua:%d+: kvkv.f: b: bad type string: expected number")

	assert.equal(t.nodefault, 42)
	assert.equal(t.with_ge, 1)
	assert.equal(t.with_le, 100)
	assert.equal(t.nested.foo, "x")
	assert.equal(t.nested.bar, 2)
	assert.equivalent(t.kv, {foo=1, bar=2})
	assert.equivalent(t.kvkv, {foo={bar=2}})

	local t = schema.makeTable(sch)
	assert.equal(t.nodefault, nil)
	assert.equal(t.with_ge, 10)
	assert.equal(t.with_le, 10)
	assert.equal(t.nested.foo, "")
	assert.equal(t.nested.bar, 0)
end)
