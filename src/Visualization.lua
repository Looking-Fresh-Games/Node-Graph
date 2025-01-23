--[[
    Visualization.lua
    Author: Zach Curtis (InfinityDesign)

    Description: Visualization module for using NavigationController Node parts
]]--

-- Modules
local NodeGraph = require(script.Parent)
local Edge = require(script.Parent.Edge)

local VisualizationFolder = Instance.new("Folder")
VisualizationFolder.Name = "Graph Visualizations"
VisualizationFolder.Parent = workspace

local Visualization = {
    DebugParts = {}
}

function Visualization:DrawGraph(graph: NodeGraph.NodeGraph)
    for _, edge in graph.Edges do
        self:DrawEdge(edge)
    end

    return self.DebugParts
end

function Visualization:CreateDebugPart(color: Color3, size: Vector3?)
    local debugPart = Instance.new("Part")
    debugPart.Anchored = true
    debugPart.CanCollide = false
    debugPart.CanQuery = false
    debugPart.TopSurface = Enum.SurfaceType.SmoothNoOutlines
    debugPart.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
    debugPart.Color = color

    if size then
        debugPart.Size = size
    end

    debugPart.Parent = VisualizationFolder

    return debugPart
end

function Visualization:DrawEdge(edge: Edge.Edge)
    local node0, node1 = edge.Node0, edge.Node1
    -- local root0, root1 = node0.Data.Part, node1.Data.Part
    local pos0, pos1 = node0.Data.Position, node1.Data.Position ---@FIXME: this is so gross 

    local diff = pos0 - pos1
    local debugPart = self:CreateDebugPart(Color3.new(0.035294, 0.921569, 0.035294))
   
    debugPart.Size = Vector3.new(.1, .1, diff.Magnitude)
    debugPart.CFrame = CFrame.new(pos0, pos1) * CFrame.new(0, 0, -diff.Magnitude * .5)

    if self.DebugParts[edge] then
        self.DebugParts[edge]:Destroy()
    end

    self.DebugParts[edge] = debugPart

    return debugPart
end

function Visualization:Clear()

    for _, part in self.DebugParts do
        part:Destroy()
    end

    self.DebugParts = {}
end

return Visualization