DebugBodySet = nil --"f1bc6e5c-9a1b-418b-8c23-23b8d98caf36"--"ebcd43a0-38c3-4925-ae09-3305b9c5b986" 
DebugHeadSet = nil --"0e9b1afa-1a25-4bfa-aab4-a9534e2c089c" 

BDSMHeads = {
    ["cry"] = {
        ["anim"] = "cd8b98d1-5ae2-f4f7-ce9d-8b47a3252b4d",
        ["set"] = "7759a120-aa4c-49f8-aeae-1809b84749a1",
    },
    ["pain"] = {
        ["anim"] = "6c8eec07-d28e-7541-f87f-153c04865906",
        ["set"] = "5bd4af51-4b2f-4e84-995a-3fc9dc1fd8dc",
    },
    ["mindmeld"] = {
        ["anim"] = "df63ac75-0233-19fd-581c-09a9444750eb",
        ["set"] = "34687f5b-5208-4935-913a-f3c2d739bb2b",
    },
    ["growl"] = {
        ["anim"] = "e3a4ce47-1532-457d-a8e7-9c8207beefe6",
        ["set"] = "48b4aa8c-fa7b-4ff7-8828-8ec844ac3be3",
    }
}

BDSMAnims = {
    -- Gut goblin camp
    ["BDSM_Shackle"] = {
        ["name"] = "he9072dc53de34f81a56e4572316677d1",
        ["anim"] = "7bf442fb-f7fb-8910-92a8-f9e445da3d74",--"GOB_GOBLINPRIEST_CHAINS",
        ["type"] = "looping",
        ["bodyset"] = "820a4ea1-4fc9-444e-8042-4715eb76ef71",
        ["headset"] = "pain"
    },

    -- Zhent tied suffer
    ["BDSM_TieToChair"] = {
        ["name"] = "hf4c7ff7c81404307bd9f982b977328e1",
        ["anim"] = "4247af9d-c355-ebff-3eb8-defa878c67c1",--"TIED_TO_CHAIR",
        ["type"] = "looping",
        ["bodyset"] = "a48d426c-a1b6-4b60-9969-98714545ffe1",
        ["headset"] = "pain"
    },

    -- Command grovel spell
    ["BDSM_ForceKneel"] = {
        ["name"] = "h85e9baa312242708262ab5688d5ec6e1",
        ["anim"] = "BDSM_ON_YOUR_KNEES",
        ["type"] = "status",
    },

    -- Liam goblin camp
    ["BDSM_TortureRack"] = {
        ["name"] = "h50ea9f9f74eb4512b0501ade8fcdba71",
        ["anim"] = "258f2415-5be9-d727-84b2-71edfb0acc18",
        ["type"] = "looping",
        ["props"] = {"29a86e01-7151-4d1e-8a00-9af12dbe701b"},
        ["bodyset"] = "9b09ebd2-c8a6-462a-bee1-0f4b1a9bd3e5",
        ["headset"] = "pain"
    },

    -- Emmeline shar temple
    ["BDSM_Suspend"] = {
        ["name"] = "h50ea9f9f74eb4512b05deneidkeir8491",
        ["anim"] = "3893ef3b-b573-ddd0-a0dd-996a15b689c8",
        ["type"] = "looping",
        --["props"] = {"75ee291e-e6b4-4864-af95-1786ab72af2f"},
        ["bodyset"] = "95936d8f-d09d-4efe-51ef-87a55a45a721",--"288bb492-fb5f-4ef5-ac32-1c6d75aad1f1",
        ["headset"] = "mindmeld"
    },

    -- Omeluum iron throne
    ["BDSM_TortureChair"] = {
        ["name"] = "h50ea9f9f74eb4512b05de1eudjrue8eue1",
        ["anim"] = "65ce41ee-23cc-4904-2cc9-e50c31ce4165",
        ["type"] = "looping",
        ["props"] = {"05d09388-19e3-4840-818a-5e32d88063ef"},
        ["bodyset"] = "472044bb-f3fa-41f9-994c-dc7d4fb977de",
        ["headset"] = "pain"
    },

    -- Durge camp scene
    ["BDSM_StruggleBound"] = {
        ["name"] = "h50ea9f9f74ebedjfurieenwd893dn34n1",
        ["anim"] = "7051b419-128e-14f0-b36b-16dccea2dbda",
        ["type"] = "looping",
        ["bodyset"] = "7f18da75-7a7f-4537-bb03-35cf24e762a9",
        ["headset"] = "pain"
    },

    -- Caz vampire spawn
    ["BDSM_HoverChain"] = {
        ["name"] = "h35c466f860a140c49a0248ad94819d501",
        ["anim"] = "a15ac178-f81f-f844-d92b-43e88e353346",
        ["type"] = "looping",
        ["bodyset"] = "e55fce35-fcc5-40cf-85e5-e5ae23937e5e",
        ["headset"] = "cry"
    },

    -- Nautiloid bed
    --[[["BDSM_TortureBed"] = {
        ["name"] = "h1ca2eb1c11914ca99b3be083b681fd5a1",
        ["anim"] = "5772fd4a-5649-cf16-d94e-b23a9f8d1a17",
        ["type"] = "looping",
        ["bodyset"] = "b5fb4105-fa2f-46d2-9f68-9c8202c707a2",
        ["headset"] = "cry"
    },]]
}