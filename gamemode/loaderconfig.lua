--[[
    This is the configuration table for our module loader.
    Feel free to change the load order of *your* modules.
--]]

loaderConfig = 
{
    splash = -- Super duper cool splash screen for cool kids like us.
    {
        ".---------------------------------------------------.",
		" Not a super cool splash screen because repro       '",
        "'---------------------------------------------------'",
    },
                             
    --[[
        Load order for modules. DO NOT MODIFY THE ORDER OF THE MODULES. 
        If you modify the order, we'll just assume you know what you're doing and you're void of our help, really.
        Same goes for modifying our module_name.lua files.
    --]]
    loadOrder =
    {
        "logging",  -- logging first, can be used by other modules and doesn't depend on any        
        -- Add your custom modules below, I don't recommend touching any of the above.
    }
}