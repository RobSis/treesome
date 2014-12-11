--[[
    Treesome: Binary Tree-based tiling layout for Awesome 3

    Github: https://github.com/RobSis/treesome
    License: GNU General Public License v2.0
--]]

local awful     = require("awful")
local beautiful = require("beautiful")
local Bintree   = require("treesome/bintree")
local os        = os
local math      = math
local ipairs    = ipairs
local pairs     = pairs
local table     = table
local tonumber  = tonumber
local tostring  = tostring
local type      = type
local capi =
{
    client = client,
    mouse = mouse
}

module("treesome")
name = "treesome"

-- Layout icon
beautiful.layout_treesome = os.getenv("HOME") .. "/.config/awesome/treesome/layout_icon.png"

-- Configuration
local configuration = {
    focusFirst = true
}

-- Globals
local trees = {}
local forceSplit = nil


-- get an unique identifier of a window
function hash(client)
    return client.window
end

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
                trees[tag].t:swapLeaves(hash(diff[1]), hash(diff[2]))
            end
        end
    end
    trees[tag].clients = p.clients

    -- some client removed. remove (from) tree
    if changed < 0 then
        if n > 0 then
            local tokens = {}
            for i, c in ipairs(p.clients) do
                tokens[i] = hash(c)
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
            if not trees[tag].t or not trees[tag].t:find(hash(c)) then
                if focus == nil then
                    focus = trees[tag].lastFocus
                end

                local focusNode = nil
                local focusGeometry = nil
                local focusId = nil
                if trees[tag].t and focus and hash(c) ~= hash(focus) and not layoutSwitch then
                    -- split focused window
                    focusNode = trees[tag].t:find(hash(focus))
                    focusGeometry = focus:geometry()
                    focusId = hash(focus)
                else
                    -- the layout was switched with more clients to order at once
                    if prevClient then
                        focusNode = trees[tag].t:find(hash(prevClient))
                        nextSplit = (nextSplit + 1) % 2
                        focusId = hash(prevClient)
                    else
                        if not trees[tag].t then
                            -- create as root
                            trees[tag].t = Bintree.new(hash(c))
                            focusId = hash(c)
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

                    if configuration.focusFirst then
                        focusNode:addLeft(Bintree.new(focusId))
                        focusNode:addRight(Bintree.new(hash(c)))
                    else
                        focusNode:addLeft(Bintree.new(hash(c)))
                        focusNode:addRight(Bintree.new(focusId))
                    end
                end
            end
            prevClient = c
        end
        forceSplit = nil
    end

    -- Useless gap.
    local useless_gap = tonumber(beautiful.useless_gap_width)
    if useless_gap == nil then
        useless_gap = 0
    end

    -- draw it
    if n >= 1 then
        for i, c in ipairs(p.clients) do
            local geometry = {
                width = area.width - ( useless_gap * 2.0 ),
                height = area.height - ( useless_gap * 2.0 ),
                x = area.x + useless_gap,
                y = area.y + useless_gap
            }

            local clientNode = trees[tag].t:find(hash(c))
            local path = {}

            trees[tag].t:trace(hash(c), path)
            for i, v in ipairs(path) do
                if i < #path then
                    split = v.split
                    -- is the client left of right from this node
                    direction = path[i + 1].direction

                    if split == "horizontal" then
                        geometry.width = ( geometry.width - useless_gap ) / 2.0

                        if direction == "right" then
                            geometry.x = geometry.x + geometry.width + useless_gap
                        end
                    elseif split == "vertical" then
                        geometry.height = ( geometry.height - useless_gap ) / 2.0

                        if direction == "right" then
                            geometry.y = geometry.y + geometry.height + useless_gap
                        end
                    end
                end
            end

            local sibling = trees[tag].t:getSibling(hash(c))

            c:geometry(geometry)
        end
    end
end
