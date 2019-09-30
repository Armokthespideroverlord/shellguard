require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"

function init()
  animator.setAnimationState("shield", "recharge")
  
  --Loading stats from config file into self
  self.maxHealth = config.getParameter("shieldHealth")
  self.startHealthPercentage = config.getParameter("startHealthPercentage")
  self.regenPercentage = config.getParameter("regenPercentage")
  self.rechargeTimeAfterHit = config.getParameter("rechargeTimeAfterHit")
  self.cooldownTimeAfterBreak = config.getParameter("cooldownTimeAfterBreak")
  self.maxAnimationRate = config.getParameter("maxAnimationRate")
  
  --Initial stats
  self.currentHealth = 0
  self.rechargeTimer = 0.95
  self.cooldownTimer = 0
  self.active = false
  status.setResource("shieldHealth", self.maxHealth)
  self.shieldHealth = status.resource("shieldHealth")
  self.lastShieldHealth = status.resource("shieldHealth")
  animator.setAnimationRate(1)
end

function update(dt)
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  
  --world.debugText("Cooldown ready in " .. self.cooldownTimer, mcontroller.position(), "red")
  --world.debugText("Recharge ready in " .. self.rechargeTimer, vec2.add(mcontroller.position(), {0,1}), "red")
  --world.debugText("Health is " .. self.shieldHealth, vec2.add(mcontroller.position(), {0,2}), "red")
  
  if not self.active then
	if self.cooldownTimer == 0 then
	  animator.setAnimationState("shield", "recharge")
	  self.rechargeTimer = math.max(0, self.rechargeTimer - dt)
	  if self.rechargeTimer == 0 then
		activateShield()
	  end
	end
  elseif self.active then
	self.shieldHealth = status.resource("shieldHealth")
	
	self.rechargeTimer = math.max(0, self.rechargeTimer - dt)
	
	--Check if we got hit recently by comparing current damage absorption to that of last frame
	if self.shieldHealth ~= self.lastShieldHealth then
	  self.rechargeTimer = self.rechargeTimeAfterHit
	elseif self.shieldHealth ~= self.maxHealth and self.rechargeTimer == 0 then
	  status.setResource("shieldHealth", math.min(self.maxHealth, self.shieldHealth + (self.maxHealth * self.regenPercentage * dt)))
	end
	
	local healthFactor =  1 - (self.shieldHealth / self.maxHealth)
	local animationRate =  1 + (healthFactor * (self.maxAnimationRate - 1))
	animator.setAnimationRate(animationRate)
	--world.debugText("Animation Rate is " .. animationRate, vec2.add(mcontroller.position(), {0,3}), "red")
	
	if status.resource("shieldHealth") <= 0 then
	  breakShield()
	end
  end
  
  self.lastShieldHealth = status.resource("shieldHealth")
end

function activateShield()
  animator.setAnimationState("shield", "activate")
  animator.setLightActive("glow", true)
  animator.setAnimationRate(1)
  animator.playSound("activate")
  status.setResource("shieldHealth", self.startHealthPercentage * self.maxHealth)
  self.active = true
end

function breakShield()
  animator.setAnimationState("shield", "break")
  animator.setLightActive("glow", false)
  animator.setAnimationRate(1)
  animator.playSound("break")
  animator.burstParticleEmitter("break")
  self.cooldownTimer = self.cooldownTimeAfterBreak
  self.rechargeTimer = self.rechargeTimeAfterHit
  self.active = false
end

function uninit()
  status.setResource("shieldHealth", 0)
end

function onExpire()
  status.setResource("shieldHealth", 0)
end