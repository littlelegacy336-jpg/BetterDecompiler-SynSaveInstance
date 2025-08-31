local ClassList
local GlobalSettings, GlobalBasicSettings = settings(), UserSettings()

local service = setmetatable({}, {
	__index = function(Self, Name)
		local svc = game:GetService(Name) 
			or GlobalSettings:GetService(Name) 
			or GlobalBasicSettings:GetService(Name)
		Self[Name] = svc
		return svc
	end,
})

local function ArrayToDictionary(tbl, hybrid)
	local dict = {}
	if hybrid == "adjust" then
		for k, v in tbl do
			if type(k) == "number" then
				dict[v] = true
			elseif type(v) == "table" then
				dict[k] = ArrayToDictionary(v, "adjust")
			else
				dict[k] = v
			end
		end
	else
		for _, v in tbl do
			dict[v] = true
		end
	end
	return dict
end

local function FetchAPI()
	local url = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json"
	local raw = game:HttpGet(url, true)
	local api = service.HttpService:JSONDecode(raw).Classes
	local classList = {}

	for _, apiClass in api do
		local class = {
			Tags = apiClass.Tags and ArrayToDictionary(apiClass.Tags) or {},
			Superclass = apiClass.Superclass,
			Properties = {}
		}

		for _, member in apiClass.Members do
			if member.MemberType == "Property" then
				local tags = member.Tags and ArrayToDictionary(member.Tags)
				local prop = {
					Name = member.Name,
					Category = member.ValueType.Category,
					Default = member.Default,
					ValueType = member.ValueType.Name,
					Special = tags and tags.NotScriptable or nil
				}
				class.Properties[member.Name] = prop
			end
		end

		classList[apiClass.Name] = class
	end

	return classList
end

local ok, result = pcall(FetchAPI)
if not ok then
	warn("API Fetch Failed:", result)
	return
end
ClassList = result

local logFolder = Instance.new("Folder")
local logOutput = "\n"

for className, classInfo in ClassList do
	local success, resultOrErr = pcall(Instance.new, className)
	local instance, errMsg

	if success then
		instance = resultOrErr
	else
		errMsg = resultOrErr
		instance = game:FindFirstChildWhichIsA(className, true) 
			or game:FindFirstChild(className, true)
			or (classInfo.Tags.Service and service[className]) 
	end

	if instance then
		local ok2, parentErr = pcall(function()
			instance.Parent = logFolder
		end)
		if not ok2 and (not string.find(parentErr, "locked", 1, true)) then
			logOutput ..= className .. ": " .. parentErr .. "\n"
		end
	elseif not (errMsg and string.find(errMsg, "Unable to create an Instance", 1, true)) then
		logOutput ..= "! " .. className .. ": " .. tostring(errMsg) .. "\n"
	end
end

warn("Finished")
writefile("!missing2.txt", logOutput)
