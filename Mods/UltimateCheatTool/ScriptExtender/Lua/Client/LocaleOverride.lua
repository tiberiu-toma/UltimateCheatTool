LCL = {}

Ext.Events.SessionLoaded:Subscribe(function()
    LCL.ApplyOverrides()
end)

function LCL.ApplyOverrides()
    for handle, text in pairs(LocaleText) do
        Ext.Loca.UpdateTranslatedString(handle, text)
    end
end

function LCL.Get(str, fallback) 
	fallback = fallback or str
	
	for k,v in pairs(LocaleText) do
		if k == str then
			return v
		end
	end

    local translated = Ext.Loca.GetTranslatedString(str, fallback)
    if translated and translated ~= "" then
        return LCL.PreprocessXML(translated)
    end

    return fallback
end

function LCL.PreprocessXML(str)
    if not str or str == "" then
        return str
    end

    -- First, handle <br> tags by converting them to newlines
    str = str:gsub("<[Bb][Rr]>", "\n")
    -- Then, strip all other XML/HTML-like tags
    str = str:gsub("<[^>]+>", "")
    -- Finally, trim whitespace from the start and end
    return HLP.Trim(str)
end