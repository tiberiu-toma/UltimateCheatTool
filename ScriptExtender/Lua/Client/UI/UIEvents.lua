---@class UIEvents
--- A simple global event dispatcher to decouple UI components.
local UIEvents = {}
local listeners = {}

---@param eventName string The name of the event to subscribe to.
---@param callback function The function to call when the event is published.
function UIEvents:Subscribe(eventName, callback)
    if not listeners[eventName] then
        listeners[eventName] = {}
    end
    table.insert(listeners[eventName], callback)
end

---@param eventName string The name of the event to publish.
---@param ... any The arguments to pass to the event listeners.
function UIEvents:Publish(eventName, ...)
    if listeners[eventName] then
        for _, callback in ipairs(listeners[eventName]) do
            callback(...)
        end
    end
end

return UIEvents