-- Treesome: Tree-based tiling layour for Awesome 3
-- Licenced under the GNU General Public License v2
--  * (c) 2013, RobSis@github.com
---------------------------------------------------

local ipairs = ipairs
local pairs = pairs
local type = type
local tostring = tostring
local table = table
local math = math
local awful = require("awful")
local capi =
{
    client = client,
    mouse = mouse
}

local Bintree = require("treesome/bintree")
module("treesome")

-- Globals
local config = {
    focusFirst = true
}
trees = {}
name = "treesome"
forceSplit = nil

function table_find(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

function table_diff(table1, table2)
    local diffList = {}
    for i,v in ipairs(table1) do
        if table2[i] ~= v then
            table.insert(diffList, v)
        end
    end
    if #diffList == 0 then
        diffList = nil
    end
    return diffList
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
        if node.data and not table_find(clients, node.data) and
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

function setslave(client)
    if not trees[tostring(awful.tag.selected(capi.mouse.screen))] then
        awful.client.setslave(client)
    end
end

function setmaster(client)
    if not trees[tostring(awful.tag.selected(capi.mouse.screen))] then
        awful.client.setmaster(client)
    end
end

function horizontal()
    forceSplit = "horizontal"
end

function vertical()
    forceSplit = "vertical"
end

function arrange(p)
    local area = p.workarea
    local n = #p.clients

    local tag = tostring(awful.tag.selected(capi.mouse.screen))
    if not trees[tag] then
        trees[tag] = {
            t = nil,
            lastFocus = nil,
            clients = nil,
            n = 0
        }
    end

    if trees[tag] ~= nil then
        focus = capi.client.focus
        if focus ~= nil then
            if awful.client.floating.get(focus) then
                focus = nil
            else
                trees[tag].lastFocus = focus
            end
        end
    end

    -- rearange only on change
    local changed = 0
    local layoutSwitch = false

    if trees[tag].n ~= n then
        if math.abs(n - trees[tag].n) > 1 then
            layoutSwitch = true
        end
        if not trees[tag].n or n > trees[tag].n then
            changed = 1
        else
            changed = -1
        end
        trees[tag].n = n
    else
        if trees[tag].clients then
            local diff = table_diff(p.clients, trees[tag].clients)
            if diff and #diff == 2 then
                trees[tag].t:swapLeaves(diff[1].pid, diff[2].pid)
            end
        end
    end
    trees[tag].clients = p.clients

    -- some client removed. remove (from) tree
    if changed < 0 then
        if n > 0 then
            local tokens = {}
            for i, c in ipairs(p.clients) do
                tokens[i] = c.pid
            end

            trees[tag].t:filterClients(trees[tag].t, tokens)
        else
            trees[tag] = nil
        end
    end

    -- some client added. put it in the tree as a sibling of focus
    local prevClient = nil
    local nextSplit = 0
    if changed > 0 then
        for i, c in ipairs(p.clients) do
            if not trees[tag].t or not trees[tag].t:find(c.pid) then
                if focus == nil then
                    focus = trees[tag].lastFocus
                end

                local focusNode = nil
                local focusGeometry = nil
                local focusId = nil
                if trees[tag].t and focus and c.pid ~= focus.pid and not layoutSwitch then
                    -- split focused window
                    focusNode = trees[tag].t:find(focus.pid)
                    focusGeometry = focus:geometry()
                    focusId = focus.pid
                else
                    -- the layout was switched with more clients to order at once
                    if prevClient then
                        focusNode = trees[tag].t:find(prevClient.pid)
                        nextSplit = (nextSplit + 1) % 2
                        focusId = prevClient.pid
                    else
                        if not trees[tag].t then
                            -- create as root
                            trees[tag].t = Bintree.new(c.pid)
                            focusId = c.pid
                            focusGeometry = {
                                width = 0,
                                height = 0
                            }
                        end
                    end
                end

                if focusNode then
                    if focusGeometry == nil then
                        local splits = {"horizontal", "vertical"}
                        focusNode.data = splits[nextSplit + 1]
                    else
                        if (forceSplit ~= nil) then
                            focusNode.data = forceSplit
                        else
                            if (focusGeometry.width <= focusGeometry.height) then
                                focusNode.data = "vertical"
                            else
                                focusNode.data = "horizontal"
                            end
                        end
                    end

                    if config.focusFirst then
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
        forceSplit = nil
    end

    -- draw it
    if n >= 1 then
        for i, c in ipairs(p.clients) do
            local geometry = {
                width = area.width,
                height = area.height,
                x = area.x,
                y = area.y
            }

            local clientNode = trees[tag].t:find(c.pid)
            local path = {}

            trees[tag].t:trace(c.pid, path)
            for i, v in ipairs(path) do
                if i < #path then
                    split = v.split
                    -- is the client left of right from this node
                    direction = path[i + 1].direction

                    if split == "horizontal" then
                        geometry.width = geometry.width / 2.0

                        if direction == "right" then
                            geometry.x = geometry.x + geometry.width
                        end
                    elseif split == "vertical" then
                        geometry.height = geometry.height / 2.0

                        if direction == "right" then
                            geometry.y = geometry.y + geometry.height
                        end
                    end
                end
            end

            local sibling = trees[tag].t:getSibling(c.pid)

            c:geometry(geometry)
        end
    end
end
