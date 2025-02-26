local transferred = {}
local base = {}

-- manual fixes:
if mods["space-age"] then
  for i, req in pairs(data.raw.technology["big-mining-drill"].prerequisites) do
    if req == "electric-mining-drill" then
      data.raw.technology["big-mining-drill"].prerequisites[i] = nil
    end
  end
  -- data.raw.technology["big-mining-drill"].prerequisites[2] = nil
  -- data.raw.technology["planet-discovery-vulcanus"].prerequisites[#data.raw.technology["planet-discovery-vulcanus"].prerequisites+1] = "electric-mining-drill"
end

::continue::

local continue = false

-- transfer unlocks to previous technologies
for t, technology in pairs(data.raw.technology) do

  -- adjust prerequisites for transferred technologies
  ::doitagain::
  local again = false
  local req = {}
  local fix = {}

  if technology.prerequisites and #technology.prerequisites > 0 then
    -- adjust prerequisites
    for i, prerequisite in pairs(technology.prerequisites) do
      if not req[prerequisite] then
        if transferred[prerequisite] then
          technology.prerequisites[i] = transferred[prerequisite]
          again = true
        elseif base[prerequisite] then
          technology.prerequisites[i] = nil
        end
        req[prerequisite] = true
      else -- get rid of duplicates
        technology.prerequisites[i] = nil
      end
    end
  elseif technology.research_trigger and not base[t] then -- has no prerequisites, is base level tech
    technology.prerequisites = nil
    base[t] = true
    continue = true
  end
  
  -- repeat if anything happened to follow chains to their end
  if again then ::doitagain:: end

  -- if research trigger
  if technology.research_trigger and not transferred[t] and technology.prerequisites and #technology.prerequisites == 1 then
    -- it was transferred to...
    transferred[t] = table.deepcopy(technology.prerequisites[1])
    continue = true
  end
end

-- check again if needed
if continue then goto continue end

-- go through technologies and move their unlocks to the prerequesites
for t, technology in pairs(data.raw.technology) do
  if technology.research_trigger and not technology.enabled and (base[t] or transferred[t]) then
    if technology.prerequisites and technology.effects then
      for p, prereq in pairs(technology.prerequisites) do
        for _, effect in pairs(technology.effects) do
          data.raw.technology[prereq].effects[#data.raw.technology[prereq].effects+1] = effect
        end  
      end
    elseif technology.effects then -- no prerequisite, base technology
      for _, effect in pairs(technology.effects) do
        if effect.type == "unlock-recipe" then
          data.raw.recipe[effect.recipe].enabled = true
        end
      end  
    end
    technology.enabled = false
    technology.research_trigger = nil
    technology.unit = {count = 1, time = 1, ingredients = {{"automation-science-pack", 1}}}
  end
end

-- get rid of hanging tables, compactify others
for _, technology in pairs(data.raw.technology) do
  if technology.prerequisites and #technology.prerequisites == 0 then
    technology.prerequisites = nil -- get rid of hanging tables
  elseif technology.prerequisites then -- compactify other tables
    local reqs = technology.prerequisites
    technology.prerequisites = {}
    for _, prereq in pairs(reqs) do
      technology.prerequisites[#technology.prerequisites+1] = prereq
    end
  end
end