local CollectionService = game:GetService("CollectionService")
local NODE_TAG = "NODE_" -- added the _ to prevent it from clashing with other instances
local RENDERER_TAG = "RENDERER" -- added the _ to prevent it from clashing with other instances . Given to any object that helps in the rendering
local LINKED_NODES = "LINKEDNODES_"
local NODE_ID = "NODEID_"

local LinkRenderer = {}
local isRendering = false

function LinkRenderer.RemoveExistingConnections()
	local stuffToDestroy = CollectionService:GetTagged(RENDERER_TAG)
	for _, x in stuffToDestroy do
		x:Destroy()
	end
end

function LinkRenderer.RenderAllConnections()
	LinkRenderer.RemoveExistingConnections()

	local allNodes = CollectionService:GetTagged(NODE_TAG)
	for _, node in allNodes do
		for id in node:GetAttribute(LINKED_NODES):gmatch("{.-}") do
			local foundNode = LinkRenderer.FindNodeWithId(id)
			LinkRenderer.DrawConnection(node, foundNode)
		end
	end
end

function LinkRenderer.FindNodeWithId(id)
	local allNodes = CollectionService:GetTagged(NODE_TAG)

	for _, node in allNodes do
		if node:GetAttribute(NODE_ID) == id then
			return node
		end
	end
end

function LinkRenderer.DrawConnection(nodeA, nodeB)
	if not isRendering then
		return
	end

	local attachmentA = Instance.new("Attachment")
	attachmentA.Parent = nodeA
	attachmentA:AddTag(RENDERER_TAG)

	local attachmentB = attachmentA:Clone()
	attachmentB.Parent = nodeB

	local beam = Instance.new("Beam")
	beam.Parent = nodeA
	beam.Attachment0 = attachmentA
	beam.Attachment1 = attachmentB
	beam.FaceCamera = true

	beam:AddTag(RENDERER_TAG)
end

function LinkRenderer.Toggle()
	isRendering = not isRendering
	if isRendering then
		LinkRenderer.RenderAllConnections()
	else
		LinkRenderer.RemoveExistingConnections()
	end
end

return LinkRenderer
