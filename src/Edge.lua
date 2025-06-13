--!strict

--[[
    Edge.lua
    Author: Zach (InfinityDesign)

    Description: Edge class for NodeGraph.lua
]]
--

-- Modules
local Node = require(script.Parent:WaitForChild("Node"))

-- Types
type EdgeProps = {
	Node0: Node.Node,
	Node1: Node.Node,
	Weight: number?,
}

local Edge = {}
Edge.__index = Edge

export type Edge = typeof(setmetatable({} :: EdgeProps, Edge))

function Edge.new(node0: Node.Node, node1: Node.Node, weight: number?)
	local self = setmetatable({} :: EdgeProps, Edge)

	self.Node0 = node0
	self.Node1 = node1
	self.Weight = weight

	return self
end

function Edge.HasNode(self: Edge, node: Node.Node): boolean
	return node == self.Node0 or node == self.Node1
end

return Edge
