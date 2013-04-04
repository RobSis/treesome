-- bintree.lua
-- Class representing the binary tree
local Bintree = {}
Bintree.__index = Bintree


function Bintree.new(data, left, right)
   local node = {
       data = data,
       left = left,
       right = right,
   }
   return setmetatable(node,Bintree)
end

function Bintree:addLeft(child)
    if self ~= nil then
        self.left = child
        return self.left
    end
end

function Bintree:addRight(child)
    if self ~= nil then
        self.right = child
        return self.right
    end
end

function Bintree:find(data)
    if data == self.data then
        return self
    end

    local output = nil
    if type(self.left) == "table" then
        output = self.left:find(data)
    end

    if type(self.right) == "table" then
        output = output or self.right:find(data) or nil
    end

    return output
end

-- remove leaf and replace parent by sibling
function Bintree:removeLeaf(data)
    local output = nil
    if self.left ~= nil then
        if self.left.data == data then
            local newSelf = {
                data = self.right.data,
                left = self.right.left,
                right = self.right.right
            }
            self.data = newSelf.data
            self.left = newSelf.left
            self.right = newSelf.right
            return true
        else
            output = self.left:removeLeaf(data) or nil
        end
    end

    if self.right ~= nil then
        if self.right.data == data then
            local newSelf = {
                data = self.left.data,
                left = self.left.left,
                right = self.left.right
            }
            self.data = newSelf.data
            self.left = newSelf.left
            self.right = newSelf.right
            return true
        else
            return output or self.right:removeLeaf(data) or nil
        end
    end
end

function Bintree:getSibling(data)
    if data == self.data then
        return nil
    end

    local output = nil
    if type(self.left) == "table" then
        if self.left.data == data then
            return self.right
        end
        output = self.left:getSibling(data) or nil
    end

    if type(self.right) == "table" then
        if self.right.data == data then
            return self.left
        end
        output = output or self.right:getSibling(data) or nil
    end

    return output or nil
end

function Bintree:getParent(data)
    local output = nil
    if type(self.left) == "table" then
        if self.left.data == data then
            return self
        end
        output = self.left:getParent(data) or nil
    end

    if type(self.right) == "table" then
        if self.right.data == data then
            return self
        end
        return output or self.right:getParent(data) or self
    end
end

function Bintree:swapLeaves(data1, data2)
    local leaf1 = self:find(data1)
    local leaf2 = self:find(data2)

    local temp = nil
    if leaf1 and leaf2 then
       temp = leaf1.data
       leaf1.data = leaf2.data
       leaf2.data = temp
    end
end

function Bintree.show(node, level)
    if level == nil then
        level = 0
    end
    if node ~= nil then
        print(string.rep(" ", level) .. "Node[" .. node.data .. "]")
        Bintree.show(node.left, level + 1)
        Bintree.show(node.right, level + 1)
    end
end

return Bintree
