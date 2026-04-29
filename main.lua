local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local InputContainer = require("ui/widget/container/inputcontainer")
local SpinWidget = require("ui/widget/spinwidget")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")

local _ = require("gettext")

local SETTINGS_PREFIX = "twenty_twenty_twenty_"
local ENABLED_KEY = SETTINGS_PREFIX .. "enabled"
local INTERVAL_KEY = SETTINGS_PREFIX .. "interval_minutes"
local REST_KEY = SETTINGS_PREFIX .. "rest_seconds"

local DEFAULT_ENABLED = true
local DEFAULT_INTERVAL_MINUTES = 20
local DEFAULT_REST_SECONDS = 20

local MIN_INTERVAL_MINUTES = 1
local MAX_INTERVAL_MINUTES = 180
local MIN_REST_SECONDS = 1
local MAX_REST_SECONDS = 300

local Screen = Device.screen

local function readSetting(key, default)
    local value = G_reader_settings:readSetting(key)
    if value == nil then
        return default
    end
    return value
end

local function clampNumber(value, min_value, max_value, default)
    value = tonumber(value) or default
    if value < min_value then
        return min_value
    elseif value > max_value then
        return max_value
    end
    return value
end

local RestOverlay = InputContainer:extend{
    name = "twenty_twenty_twenty_rest_overlay",
    covers_fullscreen = true,
    disable_double_tap = true,
}

function RestOverlay:init()
    self.remaining = math.max(0, tonumber(self.seconds) or DEFAULT_REST_SECONDS)
    self.dimen = Screen:getSize()
    self.key_events = {
        Close = { { Device.input.group.Back } },
    }
    self:_buildContent()
end

function RestOverlay:_buildContent()
    local screen_w = Screen:getWidth()
    local screen_h = Screen:getHeight()
    local font_size = math.floor(screen_h * 0.18)
    local area_w = math.floor(screen_w * 0.65)
    local area_h = math.floor(font_size * 1.7)
    self.countdown_dimen = Geom:new{
        x = math.floor((screen_w - area_w) / 2),
        y = math.floor((screen_h - area_h) / 2),
        w = area_w,
        h = area_h,
    }
    self.countdown_text = TextWidget:new{
        text = tostring(self.remaining),
        face = Font:getFace("cfont", font_size),
        bold = true,
        fgcolor = Blitbuffer.COLOR_WHITE,
    }
    self[1] = FrameContainer:new{
        bordersize = 0,
        padding = 0,
        margin = 0,
        background = Blitbuffer.COLOR_BLACK,
        dimen = self.dimen,
        CenterContainer:new{
            dimen = self.dimen,
            FrameContainer:new{
                bordersize = 0,
                padding = 0,
                margin = 0,
                background = Blitbuffer.COLOR_BLACK,
                dimen = Geom:new{ w = area_w, h = area_h },
                CenterContainer:new{
                    dimen = Geom:new{ w = area_w, h = area_h },
                    self.countdown_text,
                },
            },
        },
    }
end

function RestOverlay:onShow()
    self:_scheduleTick()
end

function RestOverlay:_scheduleTick()
    if self.remaining <= 0 then
        self:_finish()
        return
    end
    if self._tick_timer then
        UIManager:unschedule(self._tick_timer)
    end
    self._tick_timer = UIManager:scheduleIn(1, function()
        self._tick_timer = nil
        self.remaining = self.remaining - 1
        self.countdown_text:setText(tostring(self.remaining))
        UIManager:setDirty(self, function()
            return "fast", self.countdown_dimen
        end)
        if self.remaining <= 0 then
            self._tick_timer = UIManager:scheduleIn(1, function()
                self._tick_timer = nil
                self:_finish()
            end)
        else
            self:_scheduleTick()
        end
    end)
end

function RestOverlay:_finish()
    if self._closed then
        return
    end
    self._closed = true
    UIManager:close(self)
    if self.on_done then
        self.on_done()
    end
end

function RestOverlay:onClose()
    self:_finish()
    return true
end

function RestOverlay:onCloseWidget()
    if self._tick_timer then
        UIManager:unschedule(self._tick_timer)
        self._tick_timer = nil
    end
    UIManager:setDirty(nil, "full")
end

local TwentyTwentyTwenty = WidgetContainer:extend{
    name = "20-20-20",
    is_doc_only = false,
}

function TwentyTwentyTwenty:init()
    self.ui.menu:registerToMainMenu(self)
    self:_migrateDefaults()
    if self:isEnabled() then
        self:startTimer()
    end
end

function TwentyTwentyTwenty:_migrateDefaults()
    if G_reader_settings:readSetting(ENABLED_KEY) == nil then
        G_reader_settings:saveSetting(ENABLED_KEY, DEFAULT_ENABLED)
    end
    if G_reader_settings:readSetting(INTERVAL_KEY) == nil then
        G_reader_settings:saveSetting(INTERVAL_KEY, DEFAULT_INTERVAL_MINUTES)
    end
    if G_reader_settings:readSetting(REST_KEY) == nil then
        G_reader_settings:saveSetting(REST_KEY, DEFAULT_REST_SECONDS)
    end
end

function TwentyTwentyTwenty:isEnabled()
    return readSetting(ENABLED_KEY, DEFAULT_ENABLED) ~= false
end

function TwentyTwentyTwenty:getIntervalMinutes()
    return clampNumber(
        readSetting(INTERVAL_KEY, DEFAULT_INTERVAL_MINUTES),
        MIN_INTERVAL_MINUTES,
        MAX_INTERVAL_MINUTES,
        DEFAULT_INTERVAL_MINUTES
    )
end

function TwentyTwentyTwenty:getRestSeconds()
    return clampNumber(
        readSetting(REST_KEY, DEFAULT_REST_SECONDS),
        MIN_REST_SECONDS,
        MAX_REST_SECONDS,
        DEFAULT_REST_SECONDS
    )
end

function TwentyTwentyTwenty:saveIntervalMinutes(value)
    G_reader_settings:saveSetting(
        INTERVAL_KEY,
        clampNumber(value, MIN_INTERVAL_MINUTES, MAX_INTERVAL_MINUTES, DEFAULT_INTERVAL_MINUTES)
    )
end

function TwentyTwentyTwenty:saveRestSeconds(value)
    G_reader_settings:saveSetting(
        REST_KEY,
        clampNumber(value, MIN_REST_SECONDS, MAX_REST_SECONDS, DEFAULT_REST_SECONDS)
    )
end

function TwentyTwentyTwenty:startTimer()
    self:stopTimer()
    if not self:isEnabled() then
        return
    end

    local delay = self:getIntervalMinutes() * 60
    self._interval_timer = UIManager:scheduleIn(delay, function()
        self._interval_timer = nil
        self:showRestOverlay()
    end)
    logger.info("20-20-20: scheduled rest overlay in", delay, "seconds")
end

function TwentyTwentyTwenty:stopTimer()
    if self._interval_timer then
        UIManager:unschedule(self._interval_timer)
        self._interval_timer = nil
    end
end

function TwentyTwentyTwenty:showRestOverlay()
    if self._rest_overlay then
        return
    end
    self._rest_overlay = RestOverlay:new{
        seconds = self:getRestSeconds(),
        on_done = function()
            self._rest_overlay = nil
            self:startTimer()
        end,
    }
    UIManager:show(self._rest_overlay)
end

function TwentyTwentyTwenty:openIntervalPicker(touchmenu_instance)
    UIManager:show(SpinWidget:new{
        title_text = _("Rest interval"),
        info_text = _("Minutes between fullscreen reminders."),
        value = self:getIntervalMinutes(),
        value_min = MIN_INTERVAL_MINUTES,
        value_max = MAX_INTERVAL_MINUTES,
        value_step = 1,
        unit = _("min"),
        ok_text = _("Set"),
        cancel_text = _("Cancel"),
        default_value = DEFAULT_INTERVAL_MINUTES,
        callback = function(spin)
            self:saveIntervalMinutes(spin.value)
            if self:isEnabled() then
                self:startTimer()
            end
            if touchmenu_instance then
                touchmenu_instance:updateItems()
            end
        end,
    })
end

function TwentyTwentyTwenty:openRestPicker(touchmenu_instance)
    UIManager:show(SpinWidget:new{
        title_text = _("Rest countdown"),
        info_text = _("Seconds to keep the black rest screen visible."),
        value = self:getRestSeconds(),
        value_min = MIN_REST_SECONDS,
        value_max = MAX_REST_SECONDS,
        value_step = 1,
        unit = _("sec"),
        ok_text = _("Set"),
        cancel_text = _("Cancel"),
        default_value = DEFAULT_REST_SECONDS,
        callback = function(spin)
            self:saveRestSeconds(spin.value)
            if touchmenu_instance then
                touchmenu_instance:updateItems()
            end
        end,
    })
end

function TwentyTwentyTwenty:addToMainMenu(menu_items)
    menu_items.twenty_twenty_twenty = {
        text = _("20-20-20 Timer"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text_func = function()
                    return self:isEnabled() and _("Disable timer") or _("Enable timer")
                end,
                checked_func = function()
                    return self:isEnabled()
                end,
                callback = function(touchmenu_instance)
                    local enabled = not self:isEnabled()
                    G_reader_settings:saveSetting(ENABLED_KEY, enabled)
                    if enabled then
                        self:startTimer()
                    else
                        self:stopTimer()
                    end
                    if touchmenu_instance then
                        touchmenu_instance:updateItems()
                    end
                end,
                keep_menu_open = true,
            },
            {
                text_func = function()
                    return string.format(_("Interval: %d min"), self:getIntervalMinutes())
                end,
                callback = function(touchmenu_instance)
                    self:openIntervalPicker(touchmenu_instance)
                end,
                keep_menu_open = true,
            },
            {
                text_func = function()
                    return string.format(_("Countdown: %d sec"), self:getRestSeconds())
                end,
                callback = function(touchmenu_instance)
                    self:openRestPicker(touchmenu_instance)
                end,
                keep_menu_open = true,
            },
            {
                text = _("Show rest screen now"),
                callback = function()
                    self:stopTimer()
                    self:showRestOverlay()
                end,
            },
        },
    }
end

function TwentyTwentyTwenty:onClose()
    self:stopTimer()
end

return TwentyTwentyTwenty
