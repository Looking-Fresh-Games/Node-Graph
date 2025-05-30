--!strict

--[[
    NodeGraph.lua
    Author: Zach (InfinityDesign)

    Description: Node graph class.
]]
--

-- Modules
local Edge = require(script:WaitForChild("Edge"))
local Node = require(script:WaitForChild("Node"))

export type Node = Node.Node
export type Edge = Edge.Edge

type NodeGraphProps = {
	Nodes: { [number]: Node.Node },
	Edges: { [number]: Edge.Edge },
	NodeEdges: { [Node.Node]: { [number]: Edge.Edge } },
}

local NodeGraph = {}
NodeGraph.__index = NodeGraph
export type NodeGraph = typeof(setmetatable({} :: NodeGraphProps, NodeGraph))

function NodeGraph.new()
	local self = setmetatable({} :: NodeGraphProps, NodeGraph)

	self.Nodes = {}
	self.Edges = {}
	self.NodeEdges = {}

	return self
end

function NodeGraph:GetNode(nodeDataItem: unknown): Node.Node?
	for _, node in self.Nodes do
		for _, thisNodeDataItem in node.Data do
			if nodeDataItem == thisNodeDataItem then
				return node
			end
		end
	end

	return
end

function NodeGraph:GetEdgesForNode(node: Node.Node): { [number]: Edge.Edge }
	return self.NodeEdges[node]
end

function NodeGraph:GetEdgeForNodes(node0: Node.Node, node1: Node.Node): Edge.Edge?
	local edges = self:GetEdgesForNode(node0)

	for _, edge in edges do
		if edge.Node0 == node1 or edge.Node1 == node1 then
			return edge
		end
	end

	return
end

function NodeGraph:AddNode(dataRecord: { [unknown]: unknown }): Node.Node
	local node = Node.new(dataRecord)
	table.insert(self.Nodes, node)
	self.NodeEdges[node] = {}

	return node
end

function NodeGraph:RemoveNode(node: Node.Node): boolean
	-- Remove all edges this node belongs to
	for _, edge in self:GetEdgesForNode(node) do
		self:RemoveEdge(edge)
	end

	self.NodeEdges[node] = nil

	for index, thisNode in self.Nodes do
		if thisNode == node then
			table.remove(self.Nodes, index)
			return true
		end
	end

	return false
end

function NodeGraph:AddEdge(
	node0: Node.Node,
	node1: Node.Node,
	weight: number?
): Edge.Edge?
	assert(node0 ~= node1, `Can't make an edge between the same node!`)

	local edges = self:GetEdgesForNode(node0)

	-- Exit if edge already exists between these two nodes
	for _, oldEdge in edges do
		if oldEdge:HasNode(node1) then
			return
		end
	end

	local edge = Edge.new(node0, node1, weight)
	table.insert(self.Edges, edge)

	table.insert(self.NodeEdges[node0], edge)
	table.insert(self.NodeEdges[node1], edge)

	return edge
end

function NodeGraph:RemoveEdge(edge: Edge.Edge): boolean
	for index, thisEdge in self.Edges do
		if thisEdge == edge then
			table.remove(self.Edges, index)
			return true
		end
	end

	for node, edges in self.NodeEdges do
		for index, otherEdge in edges do
			if edge == otherEdge then
				table.remove(self.NodeEdges[node], index)
			end
		end
	end

	return false
end

return NodeGraph
