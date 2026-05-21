Config = {}

-- ██████╗ ██████╗ ██╗██╗   ██╗███████╗████████╗██╗  ██╗██████╗ ██╗   ██╗
-- ██╔══██╗██╔══██╗██║██║   ██║██╔════╝╚══██╔══╝██║  ██║██╔══██╗██║   ██║
-- ██║  ██║██████╔╝██║██║   ██║█████╗     ██║   ███████║██████╔╝██║   ██║
-- ██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝     ██║   ██╔══██║██╔══██╗██║   ██║
-- ██████╔╝██║  ██║██║ ╚████╔╝ ███████╗   ██║   ██║  ██║██║  ██║╚██████╔╝
-- ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝

Config.Framework = "auto" -- Framework type: esx, qb, auto
Config.Target = "auto" -- Target system: ox, qb, qtarget, auto
Config.PaymentType = "both" -- Payment method: cash, bank, both
Config.Locale = "en" -- Localization language: cs, en, hu

Config.BanCheater = true -- Ban cheaters when they try to exploit: true/false
Config.Cooldown = 1000 -- Purchase cooldown in milliseconds (1000ms = 1s)

Config.DriveThru = {
    {
        name = "Burgershot",
        coords = vector4(-1178.6779, -891.7973, 13.7439, 312.6534),
        pedModel = "s_m_m_fastfood_01",
        targetLabelKey = "order_target",
        targetIcon = "fas fa-hamburger",
        blip = {
            enabled = true,
            sprite = 106,
            color = 5,
            scale = 0.8,
            name = "Burgershot Drive-Thru"
        },
        items = {
            { name = "hamburger", labelKey = "bs_burger_label", price = 15, descKey = "bs_burger_desc", icon = "hamburger" },
            { name = "cheeseburger", labelKey = "bs_cheese_label", price = 18, descKey = "bs_cheese_desc", icon = "cheese" },
            { name = "fries", labelKey = "bs_fries_label", price = 8, descKey = "bs_fries_desc", icon = "utensils" },
            { name = "cola", labelKey = "bs_cola_label", price = 5, descKey = "bs_cola_desc", icon = "glass-water" },
            { name = "donut", labelKey = "bs_donut_label", price = 6, descKey = "bs_donut_desc", icon = "cookie-bite" }
        }
    },
}
