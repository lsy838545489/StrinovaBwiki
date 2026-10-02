-- 自动生成的《剑星》攻击技能数据模块
local SkillData = {}

SkillData["AirDropAttack1"] = {
    name = "落空决杀",
    icon = "SI_AirDropAttack1.png",
    desc = "一跃而下决杀敌人。只能对未进入战斗状态的敌人使用。",
    posX = -85,
    posY = -85,
    requires = {}
}

SkillData["BackStab1"] = {
    name = "伏击",
    icon = "SI_BackStab1.png",
    desc = "从敌人身后施展决杀。只能对未进入战斗状态的敌人使用。",
    posX = -170,
    posY = -170,
    requires = {"AirDropAttack1"}
}

SkillData["DashAttack2"] = {
    name = "决杀突进",
    icon = "SI_DashAttack2.png",
    desc = "只能在通过伏击或落空决杀击败敌人后使用。向附近的敌人发起冲锋攻击，可击倒敌人。",
    posX = -255,
    posY = -255,
    requires = {"BackStab1"}
}

SkillData["AssassainationUpgrade1_1"] = {
    name = "贝塔能量窃取",
    icon = "SI_AssassainationUpgrade1_1.png",
    desc = "伏击或落空决杀成功时补充更多的贝塔能量。",
    posX = -123,
    posY = -338,
    requires = {"BackStab1"}
}

SkillData["NormalSkillUpgrade3_1"] = {
    name = "一级贝塔能量补充",
    icon = "SI_NormalSkillUpgrade3_1.png",
    desc = "攻击时可补充更多贝塔能量。",
    posX = 85,
    posY = -85,
    requires = {}
}

SkillData["NormalSkillUpgrade3_2"] = {
    name = "二级贝塔能量补充",
    icon = "SI_NormalSkillUpgrade3_2.png",
    desc = "攻击时可补充更多贝塔能量。比一级贝塔能量补充更有效。",
    posX = 170,
    posY = -170,
    requires = {"NormalSkillUpgrade3_1"}
}

SkillData["NormalSkillUpgrade4_1"] = {
    name = "贝塔连锁",
    icon = "SI_NormalSkillUpgrade4_1.png",
    desc = "增强部分组合连击的最后一击。一旦击中目标，可造成更高伤害，令敌人硬直，并补充爆发能量。",
    posX = 226,
    posY = -82,
    requires = {"NormalSkillUpgrade3_1"}
}

SkillData["StrongAttackAdditionalCombo1"] = {
    name = "一级猛攻",
    icon = "SI_StrongAttackAdditionalCombo1.png",
    desc = "连续攻击敌人。这是组合连击技能。",
    posX = 0,
    posY = 120,
    requires = {}
}

SkillData["LightAttackAdditionalCombo2"] = {
    name = "一级袭扰",
    icon = "SI_LightAttackAdditionalCombo2.png",
    desc = "快速攻击敌人。这是组合连击技能。",
    posX = 0,
    posY = 240,
    requires = {"StrongAttackAdditionalCombo1"}
}

SkillData["StrongAttackAdditionalCombo2"] = {
    name = "二级猛攻",
    icon = "SI_StrongAttackAdditionalCombo2.png",
    desc = "连续攻击敌人，并且发起冲锋。这是组合连击技能。",
    posX = -138,
    posY = 197,
    requires = {"StrongAttackAdditionalCombo1"}
}

SkillData["DashAttack1"] = {
    name = "突进",
    icon = "SI_DashAttack1.png",
    desc = "向敌人发起冲锋。这是组合连击技能。 ",
    posX = 138,
    posY = 197,
    requires = {"StrongAttackAdditionalCombo1"}
}

SkillData["LightAttackAdditionalCombo3"] = {
    name = "二级袭扰",
    icon = "SI_LightAttackAdditionalCombo3.png",
    desc = "快速进攻，然后冲向敌人击晕对方。这是组合连击技能。",
    posX = 0,
    posY = 360,
    requires = {"LightAttackAdditionalCombo2"}
}

SkillData["StrongAttackAdditionalCombo3"] = {
    name = "三级猛攻",
    icon = "SI_StrongAttackAdditionalCombo3.png",
    desc = "连续攻击敌人并冲到敌人身后。这是组合连击技能。",
    posX = -206,
    posY = 295,
    requires = {"StrongAttackAdditionalCombo2"}
}

SkillData["DashAttack1Combo1"] = {
    name = "一级连锁突进",
    icon = "SI_DashAttackCombo1.png",
    desc = "向敌人发起冲锋，额外施放组合连击。这是组合连击技能。",
    posX = 206,
    posY = 295,
    requires = {"DashAttack1"}
}

SkillData["AirGuardBreak1"] = {
    name = "飞天重击",
    icon = "SI_AirGuardBreak1.png",
    desc = "腾空而起，攻击敌人，然后落地。无视敌人的格挡。这是组合连击技能。",
    posX = -338,
    posY = 123,
    requires = {"StrongAttackAdditionalCombo1"}
}

SkillData["DashAttack1Combo2"] = {
    name = "二级连锁突进",
    icon = "SI_DashAttackCombo2.png",
    desc = "冲向敌人，然后横扫四方，可令敌人眩晕。这是组合连击技能。",
    posX = 338,
    posY = 123,
    requires = {"DashAttack1Combo1"}
}

SkillData["LightAttackAdditionalCombo1"] = {
    name = "三级袭扰",
    icon = "SI_LightAttackAdditionalCombo1.png",
    desc = "攻击敌人，以连续劈砍结束攻击。这是组合连击技能。",
    posX = 0,
    posY = 480,
    requires = {"LightAttackAdditionalCombo3"}
}

SkillData["StrongAttackAdditionalCombo4"] = {
    name = "四级猛攻",
    icon = "SI_StrongAttackAdditionalCombo4.png",
    desc = "连续攻击敌人并冲刺发动杀招。这是组合连击技能。",
    posX = -275,
    posY = 393,
    requires = {"StrongAttackAdditionalCombo3"}
}

SkillData["DashAttack3"] = {
    name = "闪电突进",
    icon = "SI_DashAttack3.png",
    desc = "增加突进的冲锋距离及攻击力。",
    posX = 275,
    posY = 393,
    requires = {"DashAttack1"}
}

SkillData["LightAttackAdditionalCombo4"] = {
    name = "四级袭扰",
    icon = "SI_LightAttackAdditionalCombo4.png",
    desc = "快速攻击，然后一跃而起，施展强力一击。这是组合连击技能。",
    posX = 0,
    posY = 600,
    requires = {"LightAttackAdditionalCombo1"}
}

SkillData["DashAttack4"] = {
    name = "极限突进",
    icon = "SI_DashAttack4.png",
    desc = "增加突进的冲锋距离及攻击力。比闪电突进更有效。",
    posX = 344,
    posY = 491,
    requires = {"DashAttack3"}
}

return SkillData