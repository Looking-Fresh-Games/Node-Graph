--!strict

--[[
    Node.lua
    Author: Zach (InfinityDesign)

    Description: Node class for NodeGraph.lua
]]
--

type NodeProps = {
	Data: { [unknown]: unknown },
}

local Node = {}
Node.__index = Node
export type Node = typeof(setmetatable({} :: NodeProps, Node))

function Node.new(dataRecord)
	local self = setmetatable({} :: NodeProps, Node)

	self.Data = dataRecord

	return self
end

function Node:Destroy()
	self.Data = nil
end

return Node
