local Bintree = require("lib/bintree")
local math = math
local ipairs = ipairs
local api =
{
    tag = awful.tag,
    client = client
}

local treesome = {}
treesome.name = "treesome"
treesome.trees = {}

treesome.config = {
    focusFirst = true
}


function table.find(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

-- get ancestors of node with given data
function Bintree:trace(data, path, dir)
    if path then
        table.insert(path, {split=self.data, direction=dir})
    end

    if data == self.data then
        return path
    end

    if type(self.left) == "table" then
        if (self.left:trace(data, path, "left")) then
            return true
        end
    end

    if type(self.right) == "table" then
        if (self.right:trace(data, path, "right")) then
            return true
        end
    end

    if path then
        table.remove(path)
    end
end

-- remove all leaves with data that don't appear in given table
function Bintree:filterClients(node, clients)
    if node then
        if node.data and not table.find(clients, node.data) and
            node.data ~= "horizontal" and node.data ~= "vertical" then
            self:removeLeaf(node.data)
        end

        local output = nil
        if node.left then
            self:filterClients(node.left, clients)
        end

        if node.right then
            self:filterClients(node.right, clients)
        end
    end
end


function treesome.arrange(p)
    local area = p.workarea
    local n = #p.clients

    local tag = tostring(api.tag.selected(1))
    if not treesome.trees[tag] then
        treesome.trees[tag] = { t = nil, n = 0 }
    end

    -- rearange only on change
    local changed = 0
    local layoutSwitch = false
    if treesome.trees[tag].n ~= n then
        if math.abs(n - treesome.trees[tag].n) > 1 then
            layoutSwitch = true
        end
        if not treesome.trees[tag].n or n > treesome.trees[tag].n then
            changed = 1
        else
            changed = -1
        end
        treesome.trees[tag].n = n
    end

    -- some client removed. remove (from) tree
    if changed < 0 then
        if n > 0 then
            local tokens = {}
            for i, c in ipairs(p.clients) do
                tokens[i] = c.pid
            end

            treesome.trees[tag].t:filterClients(treesome.trees[tag].t, tokens)
        else
            treesome.trees[tag] = nil
        end
    end

    -- some client added. put it in the tree as a sibling of focus
    local prevClient = nil
    if changed > 0 then
        for i, c in ipairs(p.clients) do
            if not treesome.trees[tag].t or not treesome.trees[tag].t:find(c.pid) then
                focus = api.client.focus

                local focusNode = nil
                local focusGeometry = nil
                local focusId = nil
                if treesome.trees[tag].t and focus and c.pid ~= focus.pid and not layoutSwitch then
                    -- split focused window
                    focusNode = treesome.trees[tag].t:find(focus.pid)
                    focusGeometry = focus:geometry()
                    focusId = focus.pid
                else
                    -- client moved to this tag
                    -- or the layout was switched
                    if prevClient then
                        focusNode = treesome.trees[tag].t:find(prevClient.pid)
                        focusGeometry = prevClient:geometry()
                        focusId = prevClient.pid
                    else
                        if not treesome.trees[tag].t or
                                not treesome.trees[tag].t:firstLeaf() then
                            treesome.trees[tag].t = Bintree.new(c.pid)
                            focusId = c.pid
                            focusGeometry = {
                                width = 0,
                                height = 0
                            }
                        else
                            focusNode = treesome.trees[tag].t:firstLeaf()
                            focusId = focusNode.data
                            focusGeometry = {
                                width = 0,
                                height = 0
                            }
                        end

                    end
                end

                if focusNode then
                    -- TODO make user able to select
                    if (focusGeometry.width <= focusGeometry.height) then
                        focusNode.data = "horizontal"
                    else
                        focusNode.data = "vertical"
                    end

                    if treesome.config.focusFirst then
                        focusNode:addLeft(Bintree.new(focusId))
                        focusNode:addRight(Bintree.new(c.pid))
                    else
                        focusNode:addLeft(Bintree.new(c.pid))
                        focusNode:addRight(Bintree.new(focusId))
                    end
                end
            end
            prevClient = c
        end
    end

    -- draw it
    if n >= 1 and changed ~= 0 then
        for i, c in ipairs(p.clients) do
            local newWidth = area.width
            local newHeight = area.height
            local newX = area.x
            local newY = area.y

            local clientNode = treesome.trees[tag].t:find(c.pid)
            local path = {}

            treesome.trees[tag].t:trace(c.pid, path)
            for i, v in ipairs(path) do
                if i < #path then
                    split = v.split
                    -- is the client left of right from this node
                    direction = path[i + 1].direction

                    if split == "vertical" then
                        newWidth = newWidth / 2.0

                        if direction == "right" then
                            newX = newX + newWidth
                        end
                    elseif split == "horizontal" then
                        newHeight = newHeight / 2.0

                        if direction == "right" then
                            newY = newY + newHeight
                        end
                    end
                end
            end

            local sibling = treesome.trees[tag].t:getSibling(c.pid)

            local geometry = {
                width = newWidth,
                height = newHeight,
                x = newX,
                y = newY,
            }
            c:geometry(geometry)
            -- lower for maximized windows
            c:lower()
        end
    end
end

return treesome
