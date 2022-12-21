RCS ON.
CLEARSCREEN.
PRINT "ENGINE ON".
LOCK THROTTLE TO 1.
STAGE.
WAIT 5.
PRINT "LAUNCH".
STAGE.
SET AscentPitch TO 90.
PRINT "VERTICAL ASCENT".
LOCK STEERING TO HEADING(0, AscentPitch).
WAIT UNTIL ORBIT:APOAPSIS > 75000.

LOCK THROTTLE TO 0.

SET Azimuth TO 90.
SET PLIST TO SHIP:PARTSTAGGED("Stage1Tank"). 
CLEARSCREEN.
LOCK STEERING TO HEADING(Azimuth, 0).
STAGE.
WAIT 5.
PRINT "WAITING FOR APOAPSIS".
WAIT UNTIL (ETA:APOAPSIS<1).
LOCK THROTTLE TO 1.
SET CirkData  TO ApoBurn.
SET bool TO 0.
UNTIL (CirkData[4]<0)
{
	if bool = 0 {if PLIST[0]:RESOURCES[1]:Amount = 0 {STAGE. WAIT 2. STAGE. WAIT 2. STAGE. LOCK THROTTLE TO 1. SET bool TO 1.}}
	SET CirkData  TO ApoBurn.
	LOCK STEERING TO HEADING(Azimuth, CirkData[0]).
	clearscreen.
	print "Fi: "+CirkData[0].	
	print "Vh: "+CirkData[1].
	print "Vz: "+CirkData[2].	
	print "Vorb: "+CirkData[3].	
	print "dVh: "+CirkData[4].		
	print "DeltaA: "+CirkData[5].	
	if (CirkData[4]>20)
	{
		WAIT 0.01.	
	}
}
LOCK THROTTLE TO 0.

wait 5.

set config:ipu to 2000.
runoncepath("0:/rsvp/main.ks").
local options is lexicon("create_maneuver_nodes", "both", "verbose", true, "final_orbit_type", "none").
rsvp:goto(eve, options).

wait 60. //Время для дополнения маневров

SET Node TO ALLNODES.
remove Node[1].

runpath("0:/doManeuver.ks").
wait 20. //На удаление маневра
runpath("0:/doManeuver.ks").
wait 20. //На удаление маневра
runpath("0:/doManeuver.ks").
wait 5.
stage.

//Считает угол к горизонту в апоцентре при циркуляризации.
FUNCTION ApoBurn
{
	set Vh to VXCL(Ship:UP:vector, ship:velocity:orbit):mag. //горизонтальная скорость
	set Vz to VDOT(Ship:UP:vector, ship:velocity:orbit). //вертикальная скорость

	set Rad to ship:body:radius+ship:altitude. // Радиус орбиты.
	set Vorb to sqrt(ship:body:Mu/Rad). //Это 1я косм. на данной высоте.

	set g_orb to ship:body:Mu/Rad^2. //Ускорение своб. падения на этой высоте.
	set ACentr to Vh^2/Rad. //Ускорение, которое дает центробежная сила.
	set DeltaA to g_orb-ACentr. //Уск своб падения минус центр. ускорение.
	
	set ThrIsp to EngThrustIsp. //EngThrustIsp возвращает суммарную тягу и средний Isp по всем активным двигателям.
	set AThr to ThrIsp[0]*Throttle/(ship:mass). //Ускорение, которое сообщают ракете активные двигатели при тек. массе. 

	set Fi to arcsin(DeltaA/AThr)-Max(Min(Vz*3,2),-2). // Считаем угол к горизонту так, чтобы держать вертикальную скорость = 0.
	set dVh to Vorb-Vh. //Дельта до первой косм.
	RETURN LIST(Fi, Vh, Vz, Vorb, dVh, DeltaA).	//Возвращаем лист с данными.
}

//EngThrustIsp возвращает суммарную тягу и средний Isp по всем активным двигателям.
FUNCTION EngThrustIsp
{
	//создаем пустой лист ens
  set ens to list().
  ens:clear.
  set ens_thrust to 0.
  set ens_isp to 0.
	//запихиваем все движки в лист myengines
  list engines in myengines.
	
	//забираем все активные движки из myengines в ens.
  for en in myengines {
    if en:ignition = true and en:flameout = false {
      ens:add(en).
    }
  }
	//собираем суммарную тягу и Isp по всем активным движкам
  for en in ens {
    set ens_thrust to ens_thrust + en:availablethrust.
    set ens_isp to ens_isp + en:isp*en:availablethrust.
  }
  //Тягу возвращаем суммарную, а Isp средний.
  RETURN LIST(ens_thrust, ens_isp/ens_thrust).
}