--[[
    Script: Data Store Handler
    Author: LipzDev

    Usage:
        Example:
            local DataStore = DataService.new('ds-name', Player.UserId) -- creates a new data store with the name 'ds-name'
            
            DataStore:SetSettings({
                MAX_ATTEMPTS = 5,
                AUTO_SAVE    = false,
                AUTO_SAVE_INTERVAL = 0 
            })

            DataStore:ExternalDatabase('https://firebase.com/stuffhereidk', {
                WHEN_FAILS = true,
                LOADBACK   = false
            }) 

            DataStore:SetDefaultData({
                Money = 20,
                Inventory = {
                    "Basic sword"
                }
            })

            --> Increase
            local Money = DataStore:Increase(Player, 'Money', 1)
            
            print(Money) -- 21

            --> Decrease
            local Money = DataStore:Decrease(Player, 'Money', 1)

            print(Money) -- 20

            --> Set
            local Money = DataStore:Set(Player, 'Money', 30)

            print(Money) -- 30

            --> Get 
            local Money = DataStore:Get(PLayer, 'Money', {
                Value = 50
            })

            print(Money) -- 20

            --> Reach/Equal
            local Money = DataStore:WhenReach(Player, 'Money', 50, function(this)
                levelUp()
            end)
]]

--// Services
local DataStoreService = game:GetService('DataStoreService')
local Players = game:GetService('Players')

--// Vars
local dataStores = {}

--// Local Functions
local function retry(player, dsFunction, dsInstance, ...)
    local args = {...}
    local data = {}

    local suc,err = false, nil
    
    local tries = 0
    local maxTries = dsInstance.settings.MAX_ATTEMPTS

    local dataStore = = dsInstance.dataStore

    while tries < maxTries or not suc do
        tries += 1

        suc, err = pcall(function()
            data = dataStore[dsFunction](dataStore, unpack(args))
        end)

        if not suc then 
            warn('[DATA SERVICE]: Error: ', err)

            if tries == 3 and dsFunction == 'GetAsync' then
                player:Kick('Data was not able to get loaded!')
            end

            wait(1)
        else
            print('[DATA SERVICE]: Everything went ok while saving/loading ', player.Name, "'s data!")
        end
    end

    return data
end

local function newPlayer(player, dsInstance)
    dsInstance.sessionData[player] = dsInstance.defaultData

    print('[DATA SERVICE]: ', player.Name, ' is a new player, generating new data to him!')
end

local function autoSave(dsInstance)
    local waitInterval = dsInstance.AUTO_SAVE_INTERVAL
    local playerList = players:GetPlayers()    

    while true do
        for _, player in ipairs(playerList) do
            self:Save(player)
        end

        wait(waitInterval)
    end
end

--// Module
local DataService = {} 
DataService.__index = DataService

function DataService.new(dsName, scope)
    local self = setmetatable({
        dataStore = DataStoreService:GetDataStore(dsName, scope),
        
        defaultData = {},

        sessionData = {},
        settings = {
            MAX_ATTEMPTS = 3,
            AUTO_SAVE    = false,
            AUTO_SAVE_INTERVAL = 60
        },

        autoSaveThread = nil
    }, DataService)

    dataStores[dsName] = self

    return self 
end

--// Methods
function DataService:SetSettings(settings)    
    local autoSaveInterval = settings.AUTO_SAVE_INTERVAL
    
    if autoSaveInterval then
        settings.AUTO_SAVE_INTERVAL = autoSaveInterval < 60 and 60 or autoSaveInterval
    
        warn('[DATA SERVICE]: Auto save interval was below the minimum number and it was changed to the minimum ( 60 sec )')
    end
    
    self.settings = settings
end

function DataService:GetSettings()
    return self.settings
end

function DataService:ExternalDatabase(url, settings)
    --> Cooming soon!
end

function DataService:SetDefaultData(defaultData)
    self.defaultData = defaultData
end

function DataService:Save(player)
    local playerData = self.sessionData[player]

    retry(player, 'SetAsync', self, player.UserId, playerData)
end

function DataService:Load(player)
    local playerData = retry(player, 'GetAsync', self, player.UserId)

    if not playerData then
        newPlayer(player, self)
    end
end

function DataService:StartAutoSave()
    self.autoSaveThread = coroutine.create()
end

function DataService:StopAutoSave()
    coroutine.yield(self.autoSaveThread) 
end

return DataService
