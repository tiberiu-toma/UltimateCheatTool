TELP = {}
TELP.Max = 50

function TELP.GetAll(search)
    search = search or ""

    local itemData = {
        ["blighted_village"] = {
            ["id"] = "blighted_village",
            ["name"] = "Blighted Village",
            ["icon"] = "",
            ["pos"] = { x = 34, y = 394, z = 35 },
            ["trigger"] = "e44f372c-b335-4dc8-8864-f2111c83c6a6"
        },
        ["creche_yllek"] = {
            ["id"] = "creche_yllek",
            ["name"] = "Creche Y'llek",
            ["icon"] = "",
            ["pos"] = { x = 1381, y = -797 },
            ["trigger"] = "4324dbaf-6533-4b0f-8c99-de4e2adbd4ec"
        },
        ["emerald_grove_environs"] = {
            ["id"] = "emerald_grove_environs",
            ["name"] = "Emerald Grove Environs",
            ["icon"] = "",
            ["pos"] = { x = 246, y = 423 },
            ["trigger"] = "cdd91969-67d0-454e-b27b-cf34e542956b",
        },
        ["emerald_grove_environs_hollow"] = {
            ["id"] = "emerald_grove_environs_hollow",
            ["name"] = "Emerald Grove Environs - The Hollow",
            ["icon"] = "",
            ["pos"] = {x = 203.7, y = 517.29, z = 27.25 },
        },
        ["goblin_camp"] = {
            ["id"] = "goblin_camp",
            ["name"] = "Goblin Camp",
            ["icon"] = "",
            ["pos"] = { x = -74, y = 445, z = 11 },
            ["trigger"] = "3b1b1ab2-1962-47cc-8e25-5cfde2a6c32f"
        },
        ["overgrown_ruins"] = {
            ["id"] = "overgrown_ruins",
            ["name"] = "Overgrown Ruins",
            ["icon"] = "",
            ["pos"] = { x = 276, y = 298, z = 2.5 },
            ["trigger"] = "5e857e93-203a-4d4a-bd29-8e97eb34dec6"
        },
        ["roadside_cliffs"] = {
            ["id"] = "roadside_cliffs",
            ["name"] = "Roadside Cliffs",
            ["icon"] = "",
            ["pos"] = { x = 222, y = 326, z = 16.4 },
            ["trigger"] = "4141c0a2-5ba9-42c0-ab18-082426df45e7"
        },
        ["riverside_teahouse"] = {
            ["id"] = "riverside_teahouse",
            ["name"] = "Riverside Teahouse",
            ["icon"] = "",
            ["pos"] = { x = -10, y = 250, z = 1 }
        },
        ["rosymorn_monastery"] = {
            ["id"] = "rosymorn_monastery",
            ["name"] = "Rosymorn Monastery",
            ["icon"] = "",
            ["pos"] = { x = 15, y = 22 },
            ["trigger"] = "6b587ee7-5767-4d3e-8ef4-270976e63ad5"
        },
        ["the_risen_road"] = {
            ["id"] = "the_risen_road",
            ["name"] = "The Risen Road",
            ["icon"] = "",
            ["pos"] = { x = 82, y = 597, z = 32.5 },
            ["trigger"] = "bbe749bf-e6a8-4358-be9c-cd237b8af79d"
        },
        ["trielta_crags"] = {
            ["id"] = "trielta_crags",
            ["name"] = "Trielta Crags",
            ["icon"] = "",
            ["pos"] = { x = -64, y = -148 },
            ["trigger"] = "c68269af-ceac-4f90-9224-040859fe6176"
        },
        ["underdark_ancient_forge"] = {
            ["id"] = "underdark_ancient_forge",
            ["name"] = "Underdark - Ancient Forge",
            ["icon"] = "",
            ["pos"] = { x = -612, y = 294, z = 18.2 },
            ["trigger"] = "3a5474b3-2410-4a9c-80a0-ea6bf5ac4446"
        },
        ["underdark_beach"] = {
            ["id"] = "underdark_beach",
            ["name"] = "Underdark - Beach",
            ["icon"] = "",
            ["pos"] = { x = 21, y = -212 },
            ["trigger"] = "91c3fe06-7d44-4f35-a88a-ea5eb303bb70"
        },
        ["underdark_grymforge"] = {
            ["id"] = "underdark_grymforge",
            ["name"] = "Underdark - Grymforge",
            ["icon"] = "",
            ["pos"] = { x = -647, y = 382, z = 5 },
            ["trigger"] = "01d43e65-d370-46c6-9998-a9f7523221eb"
        },
        ["underdark_myconid_colony"] = {
            ["id"] = "underdark_myconid_colony",
            ["name"] = "Underdark - Myconid Colony",
            ["icon"] = "",
            ["pos"] = { x = 102, y = -101, z = 45 },
            ["trigger"] = "b83f13a0-e988-48f1-9068-ea9be2adffb2"
        },
        ["underdark_selunite_outpost"] = {
            ["id"] = "underdark_selunite_outpost",
            ["name"] = "Underdark - Selûnite Outpost",
            ["icon"] = "",
            ["pos"] = { x = 177, y = -235, z = 58 },
            ["trigger"] = "dddb39d6-c5ac-4470-98c5-395ce81af017"
        },
        ["underdark_sussur_tree"] = {
            ["id"] = "underdark_sussur_tree",
            ["name"] = "Underdark - Sussur Tree",
            ["icon"] = "",
            ["pos"] = { x = -50, y = -138., z = 25 },
            ["trigger"] = "d24b2d8c-a4dc-4367-8da2-c6fa75baa61c"
        },
        ["waukeens_rest"] = {
            ["id"] = "waukeens_rest",
            ["name"] = "Waukeen's Rest",
            ["icon"] = "",
            ["pos"] = { x = -77, y = 570, z = 36 },
            ["trigger"] = "7044aaf2-7ab9-43f6-96f0-08a173fa08b9"
        },
        ["whispering_depths"] = {
            ["id"] = "whispering_depths",
            ["name"] = "Whispering Depths",
            ["icon"] = "",
            ["pos"] = { x = -588, y = -383, z = -10 },
            ["trigger"] = "ad3614e0-8895-45dd-a05d-a78eba584202"
        },
        ["zhentarim_hideout"] = {
            ["id"] = "zhentarim_hideout",
            ["name"] = "Zhentarim Hideout",
            ["icon"] = "",
            ["pos"] = { x = 256, y = -295 },
            ["trigger"] = "f3cf2ab0-4b05-45e4-b2c8-2dda305ac47e"
        },
        ["gauntlet_of_shar"] = {
            ["id"] = "gauntlet_of_shar",
            ["name"] = "Gauntlet of Shar",
            ["icon"] = "",
            ["pos"] = { x = -757, y = -792 },
            ["trigger"] = "7d5d94c7-fa75-41f2-9aef-06b9d42757ea"
        },
        ["grand_mausoleum"] = {
            ["id"] = "grand_mausoleum",
            ["name"] = "Grand Mausoleum",
            ["icon"] = "",
            ["pos"] = { x = -173, y = 80 },
            ["trigger"] = "c6faa212-fb0f-4fc5-a011-662a03a3b09a"
        },
        ["last_light_inn"] = {
            ["id"] = "last_light_inn",
            ["name"] = "Last Light Inn",
            ["icon"] = "",
            ["pos"] = { x = -17, y = 133 },
            ["trigger"] = "94b462c2-9290-4d4d-8bf4-fbf559f03c3f"
        },
        ["moonrise_towers"] = {
            ["id"] = "moonrise_towers",
            ["name"] = "Moonrise Towers",
            ["icon"] = "",
            ["pos"] = { x = -158, y = -99 },
            ["trigger"] = "8fd66a2b-7b29-44f9-b6dd-cd957c91d19c"
        },
        ["reithwin_town"] = {
            ["id"] = "reithwin_town",
            ["name"] = "Reithwin Town",
            ["icon"] = "",
            ["pos"] = { x = -78, y = -46 },
            ["trigger"] = "488ce3e4-2239-4623-9aeb-d34cc18bec58"
        },
        ["road_to_baldurs_gate"] = {
            ["id"] = "road_to_baldurs_gate",
            ["name"] = "Road to Baldur's Gate",
            ["icon"] = "",
            ["pos"] = { x = -263, y = -37 },
            ["trigger"] = "ef45338c-09c7-4904-998f-32c0ad1165b6"
        },
        ["shadowed_battlefield"] = {
            ["id"] = "shadowed_battlefield",
            ["name"] = "Shadowed Battlefield",
            ["icon"] = "",
            ["pos"] = { x = 46, y = 17 },
            ["trigger"] = "7c083353-7e5c-4cb7-ac3e-42fc3a19807f"
        },
        ["verge_of_the_shadows"] = {
            ["id"] = "verge_of_the_shadows",
            ["name"] = "Verge of the Shadows",
            ["icon"] = "",
            ["pos"] = { x = -720, y = -844 },
            ["trigger"] = "5d48728a-9a23-4c6a-8f54-99cfb6fbb269" -- sure?
        },
        ["baldurs_gate"] = {
            ["id"] = "baldurs_gate",
            ["name"] = "Baldur's Gate",
            ["icon"] = "",
            ["pos"] = { x = -198, y = -26 },
            ["trigger"] = "8b1d2cf5-9142-4786-9294-b92b8ec2083f"
        },

        ["basilisk_gate"] = {
            ["id"] = "basilisk_gate",
            ["name"] = "Basilisk Gate",
            ["icon"] = "",
            ["pos"] = { x = 134, y = -38 },
            ["trigger"] = "f0a45122-eca3-4b8f-ad86-c429ca305b3d"
        },

        ["cazadors_dungeon"] = {
            ["id"] = "cazadors_dungeon",
            ["name"] = "Cazador's Dungeon",
            ["icon"] = "",
            ["pos"] = { x = -1928, y = 827 },
            ["trigger"] = "717c1fd4-290a-4fb7-9282-dbcdd17a274b"
        },

        ["city_sewers"] = {
            ["id"] = "city_sewers",
            ["name"] = "City Sewers",
            ["icon"] = "",
            ["pos"] = { x = -98, y = 778 },
            ["trigger"] = "a081bb35-5fcf-4d9b-8831-1da0ce052c6e"
        },

        ["grey_harbour_docks"] = {
            ["id"] = "grey_harbour_docks",
            ["name"] = "Grey Harbour Docks",
            ["icon"] = "",
            ["pos"] = { x = -219, y = -155 },
            ["trigger"] = "1e27d7c2-0914-4717-9a70-37bdcdb3b80b"
        },

        ["heapside_strand"] = {
            ["id"] = "heapside_strand",
            ["name"] = "Heapside Strand",
            ["icon"] = "",
            ["pos"] = { x = 22, y = -135 },
            ["trigger"] = "f6611899-85b6-45e3-8c1e-3b61590a621f"
        },

        ["lower_city_central_wall"] = {
            ["id"] = "lower_city_central_wall",
            ["name"] = "Lower City Central Wall",
            ["icon"] = "",
            ["pos"] = { x = -50, y = -55 },
            ["trigger"] = "97bdf561-7f2b-4618-89ca-5cad0729bd01"
        },

        ["morphic_pool_dock"] = {
            ["id"] = "morphic_pool_dock",
            ["name"] = "Morphic Pool Dock",
            ["icon"] = "",
            ["pos"] = { x = -74, y = 1115 },
            ["trigger"] = "c1ea6981-cfce-495c-8405-3b503df268fd"
        },

        ["rivington"] = {
            ["id"] = "rivington",
            ["name"] = "Rivington",
            ["icon"] = "",
            ["pos"] = { x = -9, y = -117 }
        },

        ["south_span_of_wyrms_crossing"] = {
            ["id"] = "south_span_of_wyrms_crossing",
            ["name"] = "South Span of Wyrm's Crossing",
            ["icon"] = "",
            ["pos"] = { x = 15, y = 74 },
            ["trigger"] = "5561c476-c82d-4239-b4a3-baaf2985ef71",
        },

        ["temple_of_bhaal"] = {
            ["id"] = "temple_of_bhaal",
            ["name"] = "Temple of Bhaal",
            ["icon"] = "",
            ["pos"] = { x = -55, y = 1006 },
            ["trigger"] = "807163bb-8341-49da-a074-c5926bfedf1b"
        },

        ["undercity_ruins"] = {
            ["id"] = "undercity_ruins",
            ["name"] = "Undercity Ruins",
            ["icon"] = "",
            ["pos"] = { x = -140, y = 940 },
            ["trigger"] = "3e423e81-8d84-463e-b50e-ab8c5869bdf6"
        },

        ["wyrms_rock"] = {
            ["id"] = "wyrms_rock",
            ["name"] = "Wyrm's Rock",
            ["icon"] = "",
            ["pos"] = { x = -9, y = 214 },
            ["trigger"] = "71df0a8d-2cda-4e2d-b612-9a5f5a80e771"
        }
        
    }

    local tbl = {}

    if search and search ~= "" then
        for id,data in kpairs(itemData) do 
            local name = data.name 

            if HLP.StrContains(search, name) then 
                tbl[id] = data 
            end
        end
    else 
        tbl = itemData
    end

    --print(HLP.Count(itemData) .. " Total Waypoints")
    return tbl
end