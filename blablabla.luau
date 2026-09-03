--!nonstrict

local rs = game:GetService("ReplicatedStorage")
local r_s = game:GetService("RunService")

local _comm = rs:WaitForChild("_comm")

local check_per_movement = 5

local token = {}
local max_token = 30
local per_fill = 5

local stored_info = {}
local p_info = {}

p_info.__index = p_info

function p_info.profile_creation(p)

	local self = setmetatable({}, p_info)

	local uid = p.UserId

	self.name = p.Name
	self.p_id = uid

	self.strike = 0

	stored_info[uid] = self

	return self
end

local uyu_cfg = {}

function uyu_cfg.get_profile(p)

	local uid = p.UserId

	if stored_info[uid] then return stored_info[uid] end

	return p_info.profile_creation(p)
end

function uyu_cfg.movement_handler(p)

	local profile = uyu_cfg.get_profile(p)
	
	local ch = p.Character or p.CharacterAdded:Wait()
	local hrp = ch:WaitForChild("HumanoidRootPart")
	local hmd = ch:WaitForChild("Humanoid")

	local acc_WS = hmd.WalkSpeed
	local acc_pos = hrp.Position

	local t_multipler = tick()

	task.wait(check_per_movement)

	local new_pos = hrp.Position

	local change_in_pos = (new_pos - acc_pos).Magnitude

	if change_in_pos > ((tick() - t_multipler) * acc_WS) + 5 then

		warn(p.Name .. " -> [malicious movement] {strike_count = " .. profile.strike .. "}")
	end
end


function uyu_cfg.overTokenUsage_handler(p)

	local profile = uyu_cfg.get_profile(p)

	local token_rf = r_s.Heartbeat:Connect(function(dt)

	token[p.UserId] = math.min

		(
			(token[p.UserId] or max_token) + per_fill * dt, max_token
		)
	end)

	for _, comm in pairs(_comm:GetChildren()) do

		local uid = p.UserId

		local p_conn = {}

   		p_conn[comm.Name .. "_" .. uid] = comm.OnServerEvent:Connect(function(sender)

        	if sender ~= p then return end

        	token[p.UserId] = math.max((token[p.UserId] or max_token) - 1, 0)

        	if token[p.UserId] < 1 then
				
                warn(p.Name .. " -> [false c-s communication] {strike_count = " .. profile.strike .. "}")

				token_rf:Disconnect()

				for _, event in p_conn do event:Disconnect() end
				table.clear(p_conn)
        	end
    	end)
	end
end

return uyu_cfg
