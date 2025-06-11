local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local SelectionService = game:GetService("Selection")

local LinkRenderer = require(script.LinkRenderer)

for _, x in CoreGui:GetChildren() do
	if x.Name == "PathUI" then
		x:Destroy()
	end
end --Removes existing instances of the UI

local Camera = workspace.CurrentCamera

local NODE_TAG = "NODE_" -- added the _ to prevent it from clashing with other instances
local NODE_ID = "NODEID_"
local LINKED_NODES = "LINKEDNODES_"

local PluginFolder = script.Parent

local UI = PluginFolder.PathUI
local MainFrame = UI.Main
local Options = MainFrame.Options

UI.Enabled = false
UI.Parent = CoreGui

local isRendering = false

local toolbar = plugin:CreateToolbar("Path Creator")
local pluginButton =
	toolbar:CreateButton("Path Creator", "Path Creator", "rbxassetid://8740888472")

pluginButton.Click:Connect(function()
	UI.Enabled = not UI.Enabled
end)

-----------
--el functions

function FindNodeWithId(id)
	local allNodes = CollectionService:GetTagged(NODE_TAG)

	for _, node in allNodes do
		if node:GetAttribute(NODE_ID) == id then
			return node
		end
	end
end

local function CreateNode(dontSetSelection)
	local node = Instance.new("Part")
	node.Name = NODE_TAG
	node:AddTag(NODE_TAG)
	node.Size = Vector3.new(3, 3, 3)
	node.Position = Camera.CFrame.p + Camera.CFrame.lookVector * 10
	node.Parent = workspace

	node.Locked = isRendering

	node:SetAttribute(LINKED_NODES, "")
	node:SetAttribute(NODE_ID, HttpService:GenerateGUID())

	if not dontSetSelection then
		SelectionService:Set({ node })
	end

	return node
end

local function LinkNodes(nodeA, nodeB)
	if nodeA == nodeB then
		return
	end

	--todo make sure we're not relinking them
	local nodeALinks = nodeA:GetAttribute(LINKED_NODES)
	local nodeBLinks = nodeB:GetAttribute(LINKED_NODES)

	for testId in nodeALinks:gmatch("{.-}") do
		if testId == nodeB:GetAttribute(NODE_ID) then
			print("caught")
			return
		end
	end

	for testId in nodeBLinks:gmatch("{.-}") do
		if testId == nodeA:GetAttribute(NODE_ID) then
			print("caught")
			return
		end
	end

	local newLinksA = string.format("%s%s", nodeALinks, nodeB:GetAttribute(NODE_ID))
	nodeA:SetAttribute(LINKED_NODES, newLinksA)

	local newLinksB = string.format("%s%s", nodeBLinks, nodeA:GetAttribute(NODE_ID))
	nodeB:SetAttribute(LINKED_NODES, newLinksB)

	LinkRenderer.DrawConnection(nodeA, nodeB)
end

local function LinkNodeListTo(list, target)
	for _, node in list do
		if node:HasTag(NODE_TAG) then
			LinkNodes(node, target)
		end
	end
end

local function CreateLinkedNode()
	local node = CreateNode(true)
	local selectedNodes = SelectionService:Get()
	LinkNodeListTo(selectedNodes, node)

	SelectionService:set({ node })
end

local function LinkSelectedNodesToFirst()
	local selectedNodes = SelectionService:Get()
	local targeted = selectedNodes[1]
	for i = 2, #selectedNodes do
		LinkNodes(selectedNodes[i], targeted)
	end
end

local function LinkNodesInOrder()
	local selectedNodes = SelectionService:Get()
	if #selectedNodes < 2 then
		return
	end

	for i = 1, #selectedNodes - 1 do
		LinkNodes(selectedNodes[i], selectedNodes[i + 1])
	end
end

local function RemoveNodeIdFromString(str, id)
	local newStr = ""
	for testId in str:gmatch("{.-}") do
		if not (testId == id) then
			newStr = newStr .. testId
		end
	end

	return newStr
end

local function ClearConnectionBetweenNodes(nodeA, nodeB)
	nodeA:SetAttribute(
		LINKED_NODES,
		RemoveNodeIdFromString(
			nodeA:GetAttribute(LINKED_NODES),
			nodeB:GetAttribute(NODE_ID)
		)
	)
	nodeB:SetAttribute(
		LINKED_NODES,
		RemoveNodeIdFromString(
			nodeB:GetAttribute(LINKED_NODES),
			nodeA:GetAttribute(NODE_ID)
		)
	)
end

local function ClearNodesConnections(node)
	for nodeId in node:GetAttribute(LINKED_NODES):gmatch("{.-}") do
		local targetNode = FindNodeWithId(nodeId)
		if targetNode then
			ClearConnectionBetweenNodes(node, targetNode)
		end
	end
end

local function ClearAllSelectedConnections()
	for _, node in SelectionService:Get() do
		ClearNodesConnections(node)
	end

	LinkRenderer.RenderAllConnections()
end

local function ClearBetweenSelectedNodes()
	local selectedNodes = SelectionService:Get()
	for _, node in selectedNodes do
		for targetId in node:GetAttribute(LINKED_NODES):gmatch("{.-}") do
			local targetNode = FindNodeWithId(targetId)
			if targetNode then
				local isSelected = false
				for _, testNode2 in selectedNodes do
					if testNode2 == targetNode then
						isSelected = true
						break
					end
				end

				if isSelected then
					ClearConnectionBetweenNodes(targetNode, node)
				end
			end
		end
	end

	LinkRenderer.RenderAllConnections()
end

-----------
--listening to el buttons
MainFrame.SingleNode.MouseButton1Click:Connect(CreateNode)
MainFrame.LinkedNode.MouseButton1Click:Connect(CreateLinkedNode)
Options.ToFirstLink.MouseButton1Click:Connect(LinkSelectedNodesToFirst)
Options.OrderLink.MouseButton1Click:Connect(LinkNodesInOrder)
Options.Toggle.MouseButton1Click:Connect(LinkRenderer.Toggle)
Options.ClearAll.MouseButton1Click:Connect(ClearAllSelectedConnections)
Options.ClearBetweenSelected.MouseButton1Click:Connect(ClearBetweenSelectedNodes)
