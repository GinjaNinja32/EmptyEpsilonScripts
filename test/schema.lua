require "gn32/test/test"

require "gn32/schema"

test("schema", function()
	local sch = {
		nodefault = {_type="number"},
		withmin   = {_type="number", _default=10, _min=0},
		withmax   = {_type="number", _default=10, _max=100},
		nested = {
			_type = "table",
			_default = function() return {foo="", bar=0} end,
			_fields = {
				foo = {_type="string"},
				bar = {_type="number"},
			}
		}
	}

	assert.equal(schema.checkTable({},                         sch), "nodefault: bad type nil: expected number")
	assert.equal(schema.checkTable({nodefault="foo"},          sch), "nodefault: bad type string: expected number")
	assert.equal(schema.checkTable({nodefault=2},              sch), nil)

	assert.equal(schema.checkTable({nodefault=2, withmin=-1},  sch), "withmin: bad value -1: expected value >= 0")
	assert.equal(schema.checkTable({nodefault=2, withmin=0},   sch), nil)

	assert.equal(schema.checkTable({nodefault=2, withmax=101}, sch), "withmax: bad value 101: expected value <= 100")
	assert.equal(schema.checkTable({nodefault=2, withmax=100}, sch), nil)

	assert.equal(schema.checkTable({undef=1},                  sch), "undef: field not defined")

	assert.equal(schema.checkTable({nodefault=2, nested={foo=""}}, sch), "nested: bar: bad type nil: expected number")
	assert.equal(schema.checkTable({nodefault=2, nested={bar=0}},  sch), "nested: foo: bad type nil: expected string")
	assert.equal(schema.checkTable({nodefault=2, nested={baz=42}}, sch), "nested: baz: field not defined")

	local t = schema.makeTable(sch)

	t.nodefault = 42
	t.withmin = 0
	t.withmax = 100
	t.nested = {foo="x", bar=2}

	assert.error(function() t.nodefault = "foo" end,  "./gn32/test/schema.lua:%d+: nodefault: bad type string: expected number")
	assert.error(function() t.withmin = -1 end,       "./gn32/test/schema.lua:%d+: withmin: bad value %-1: expected value >= 0")
	assert.error(function() t.withmax = 101 end,      "./gn32/test/schema.lua:%d+: withmax: bad value 101: expected value <= 100")
	assert.error(function() t.nested = {foo="x"} end, "./gn32/test/schema.lua:%d+: nested: bar: bad type nil: expected number")
	assert.error(function() t.nested.foo = 1 end,     "./gn32/test/schema.lua:%d+: nested%.foo: bad type number: expected string")
	assert.error(function() t.nested.baz = 1 end,     "./gn32/test/schema.lua:%d+: nested%.baz: field not defined")

	local t = schema.makeTable(sch)
	assert.equal(t.nodefault, nil)
	assert.equal(t.withmin, 10)
	assert.equal(t.withmax, 10)
	assert.equal(t.nested.foo, "")
	assert.equal(t.nested.bar, 0)
end)
