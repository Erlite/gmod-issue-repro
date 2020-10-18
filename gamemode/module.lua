Module = {}
Module.__index = Module

function Module:new(inName, inDescription, inLoadOrder)
    -- If inName is a table and the other arguments are nil, this means we need to set the table's metadata to a Module and validate it.
    if (inName && istable(inName)) && !inDescription && !inLoadOrder then
        setmetatable(inName, Module)
        if inName:Validate() then
            return inName
        else
            error("Invalid copy constructor used (invalid/nil table)")
            return nil
        end
    end
    
    local md =
    {
        name = inName,
        description = inDescription,
        loadOrder = inLoadOrder
    }
    md:Validate()
    setmetatable(md, Module)
    return md
end

function Module:GetName()
    return self.name
end

function Module:GetDescription()
    return self.description
end

function Module:GetLoadOrder()
    return self.loadOrder
end

function Module:Validate()
    return self.name && #self.name != 0 && self.description && #self.description != 0 && self.loadOrder
end

setmetatable(Module, {__call = Module.new})