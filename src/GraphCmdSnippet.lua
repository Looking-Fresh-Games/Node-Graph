--[[
    GraphCmdSnippet.lua
    Author: Zach Curtis (InfinityDesign)

    Description: Command line snippet for visualizating the graph as you set up the node parts
]]
--

-- Copy and paste between whitespace blocks
-- and paste into command line ONE TIME!! per studio instance

local NODE_ROOT_TAG = "NODE_"

local CollectionService = game:GetService("CollectionService")

local NodeGraph = require(script.Parent)
local Visualization = require(script.Parent.Visualization)

local nodeRoots = CollectionService:GetTagged(NODE_ROOT_TAG)

local navGraph = NodeGraph.new()
local nodes = {}
local DebugParts = {}

local refConnections = {}

local function makeEdges(nodeRoot, refsFolder, node, draw: boolean?)
	for _, valueRef in refsFolder:GetChildren() do
		local refRoot = valueRef.Value

		if not refRoot then
			warn(
				`No Value for connected node {valueRef.Parent.Parent.Name}. Node name: PROBLEM_REF_NIL`
			)

			refRoot.Name = "PROBLEM_REF_NIL"
			valueRef.Name = "PROBLEM_REF_NIL"
			nodeRoot.Name = "PROBLEM_REF_NIL"
			continue
		end

		if node == nodes[refRoot] then
			warn(
				"Cannot make edge between the same node. Node name: PROBLEM_EDGE_SAME_NODE"
			)

			refRoot.Name = "PROBLEM_EDGE_SAME_NODE"
			valueRef.Name = "PROBLEM_EDGE_SAME_NODE"
			continue
		end

		if not nodes[refRoot] then
			warn(`{refRoot.Name} is not a Node. Node name: PROBLEM_REF_NOT_NODE`)

			valueRef.Name = "PROBLEM_REF_NOT_NODE"
			nodeRoot.Name = "PROBLEM_REF_NOT_NODE"
			continue
		end

		local edgeWeight = (refRoot.Position - nodeRoot.Position).Magnitude

		local edge = navGraph:AddEdge(node, nodes[refRoot], edgeWeight)

		if edge and draw then
			DebugParts[edge] = Visualization:DrawEdge(edge)
		end
	end
end

local function listenToNodeRoot(nodeRoot: BasePart)
	local refsFolder = nodeRoot:FindFirstChild("ConnectedNodes")

	if not refsFolder then
		warn(`No Configuration named "ConnectedNodes" exists in {nodeRoot.Name}`)
		return
	end

	local changed = nodeRoot:GetPropertyChangedSignal("Position"):Connect(function()
		local node = navGraph:GetNode(nodeRoot)

		if node then
			local edges = navGraph:GetEdgesForNode(node)

			for _, edge in edges do
				local debugPart = DebugParts[edge]
				if not debugPart then
					continue
				end

				debugPart:Destroy()
				DebugParts[edge] = nil

				navGraph:RemoveEdge(edge)
			end

			makeEdges(nodeRoot, refsFolder, node, true)
		end
	end)

	table.insert(refConnections[nodeRoot], changed)
end

local function listenToRefConfig(nodeRoot: BasePart)
	local refsFolder = nodeRoot:FindFirstChild("ConnectedNodes")

	if not refsFolder then
		warn(`No Configuration named "ConnectedNodes" exists in {nodeRoot.Name}`)
		return
	end

	local node = navGraph:GetNode(nodeRoot)

	if not node then
		return
	end

	refConnections[nodeRoot] = {}

	local childAdded = refsFolder.ChildAdded:Connect(function(child)
		if not child:IsA("ObjectValue") then
			warn(`All children of Configuration must be an ObjectValue`)
			return
		end

		local valueChanged = child.Changed:Connect(function(_newRef)
			local edges = navGraph:GetEdgesForNode(node)

			for _, edge in edges do
				local debugPart = DebugParts[edge]
				if not debugPart then
					continue
				end

				debugPart:Destroy()
				DebugParts[edge] = nil

				navGraph:RemoveEdge(edge)
			end

			makeEdges(nodeRoot, refsFolder, node, true)
		end)

		table.insert(refConnections[nodeRoot], valueChanged)
	end)

	local childRemoved = refsFolder.ChildRemoved:Connect(function(_child)
		local edges = navGraph:GetEdgesForNode(node)

		for _, edge in edges do
			local debugPart = DebugParts[edge]
			if not debugPart then
				continue
			end

			debugPart:Destroy()
			DebugParts[edge] = nil

			navGraph:RemoveEdge(edge)
		end

		makeEdges(nodeRoot, refsFolder, node, true)
	end)

	table.insert(refConnections[nodeRoot], childAdded)
	table.insert(refConnections[nodeRoot], childRemoved)
end

for _, nodeRoot in nodeRoots do
	local node = navGraph:AddNode(nodeRoot, nodeRoot.Position)

	nodes[nodeRoot] = node
end

for nodeRoot, node in nodes do
	local refsFolder = nodeRoot:FindFirstChild("ConnectedNodes")

	if not refsFolder then
		warn(`No Configuration named "ConnectedNodes" exists in {nodeRoot.Name}`)
		continue
	end

	makeEdges(nodeRoot, refsFolder, node)
	listenToRefConfig(nodeRoot)
	listenToNodeRoot(nodeRoot)
end

DebugParts = Visualization:DrawGraph(navGraph)

CollectionService:GetInstanceAddedSignal(NODE_ROOT_TAG)
	:Connect(function(nodeRoot: BasePart)
		local refsFolder = nodeRoot:FindFirstChild("ConnectedNodes")

		if not refsFolder then
			warn(`No Configuration named "ConnectedNodes" exists in {nodeRoot.Name}`)
			return
		end

		local node = navGraph:AddNode(nodeRoot, nodeRoot.Position)

		makeEdges(nodeRoot, refsFolder, node, true)
		listenToRefConfig(nodeRoot)
		listenToNodeRoot(nodeRoot)
	end)

CollectionService:GetInstanceRemovedSignal(NODE_ROOT_TAG)
	:Connect(function(nodeRoot: BasePart)
		if refConnections[nodeRoot] then
			for _, connection in refConnections[nodeRoot] do
				connection:Disconnect()
			end
		end

		warn("removing part")
		local node = navGraph:GetNode(nodeRoot)

		if not node then
			warn("No node")
			return
		end

		local edges = navGraph:GetEdgesForNode(node)

		for _, edge in edges do
			local debugPart = DebugParts[edge]
			if not debugPart then
				continue
			end

			debugPart:Destroy()

			DebugParts[edge] = nil
		end

		navGraph:RemoveNode(node)
	end)

return nil
