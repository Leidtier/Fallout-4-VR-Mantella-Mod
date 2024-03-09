Scriptname MantellaEffectScript extends activemagiceffect
Import SUP_F4SEVR
Topic property MantellaDialogueLine auto
GlobalVariable property MantellaWaitTimeBuffer auto

MantellaRepository property repository auto
;string wavfilelocation="Data\\Sound\\Voice\\Mantella.esp\\MutantellaOutput1.wav"
float localMenuTimer
Float meterUnits = 78.74
Actor property PlayerRef auto
ReferenceAlias property TargetRefAlias auto

event OnEffectStart(Actor target, Actor caster)
    String playerRace = PlayerRef.GetRace().GetName()
    Int playerGenderID = PlayerRef.GetActorBase().GetSex()
    String playerGender = ""
    if (playerGenderID == 0)
        playerGender = "Male"
    else
        playerGender = "Female"
    endIf
    String playerName = PlayerRef.GetActorBase().GetName()
    SUP_F4SEVR.WriteStringToFile("_mantella_player_name.txt", playerName, 0)
    SUP_F4SEVR.WriteStringToFile("_mantella_player_race.txt", playerRace, 0)
    SUP_F4SEVR.WriteStringToFile("_mantella_player_gender.txt", playerGender, 0)

    ;cleanupstep below checks if the player is targeting someone and cleans up all conversation if that's the case
    bool casterIsPlayer=false
    ;cleanupprevious Onhit event listeners
    UnregisterForAllHitEvents(TargetRefAlias)
    if caster == PlayerRef
        casterIsPlayer=true
        debug.notification("Cleaning up before starting conversation")
        StopConversations()
    endif
    String activeActors = SUP_F4SEVR.ReadStringFromFile("_mantella_active_actors.txt",0,10)
    String actorCountString = SUP_F4SEVR.ReadStringFromFile("_mantella_actor_count.txt",0,1) 
    int actorCount = actorCountString as int
    String character_selection_enabled = SUP_F4SEVR.ReadStringFromFile("_mantella_character_selection.txt",0,1) 

    string actorName = target.GetDisplayName()
    String casterName = caster.getdisplayname()
    ;debug.messagebox ("MantellaEffectScript:"+casterName+" casting Mantella on "+actorName)
    ;if radiant dialogue between two NPCs, label them 1 & 2
    if (casterName == actorName)
        if actorCount == 0
            actorName = actorName + " 1"
            casterName = casterName + " 2"
        elseIf actorCount == 1
            actorName = actorName + " 2"
            casterName = casterName + " 1"
        endIf
    endIf

    int index = SUP_F4SEVR.SUPStringFind(activeActors, actorName,0,0)
    bool actorAlreadyLoaded = true
    if index == -1
        actorAlreadyLoaded = false
    endIf

    if (actorAlreadyLoaded == false) && (character_selection_enabled == "True")
        TargetRefAlias.ForceRefTo(target)      
        RegisterForHitEvent(TargetRefAlias.GetActorReference())
        String actorId = (target.getactorbase() as form).getformid()
        String actorRefId = target.getformid() 
        ;debug.notification("Actor ID is "+actorId)
        ;MiscUtil.WriteToFile("_mantella_current_actor_id.txt", actorId, append=false) THIS IS HOW THE FUNCTION LOOKS IN SKYRIM
        ;SUP_F4SEVR.WriteStringToFile(string sFilePath,string sText, int iAppend [0 for clean file, 1 for append, 2 for append with new line])
        SUP_F4SEVR.WriteStringToFile("_mantella_current_actor_id.txt",actorId, 0)
        SUP_F4SEVR.WriteStringToFile("_mantella_current_actor_ref_id.txt",actorRefId, 0)
        SUP_F4SEVR.WriteStringToFile("_mantella_current_actor.txt",actorName, 0)
        ;this will eventually be rewritten when multi-NPC conversation is implemented in FO4
        SUP_F4SEVR.WriteStringToFile("_mantella_active_actors.txt",actorName, 1)
        ;debug.messagebox("Current active actors "+SUP_F4SEVR.ReadStringFromFile("_mantella_active_actors.txt",0,10))
        SUP_F4SEVR.WriteStringToFile("_mantella_character_selection.txt","false",0)

        String actorSex = target.getleveledactorbase().getsex()
        SUP_F4SEVR.WriteStringToFile("_mantella_actor_sex.txt", actorSex, 0)

        String actorRace = target.getrace()
        SUP_F4SEVR.WriteStringToFile("_mantella_actor_race.txt", actorRace, 0)

        String actorRelationship = target.getrelationshiprank(PlayerRef)
        SUP_F4SEVR.WriteStringToFile("_mantella_actor_relationship.txt", actorRelationship, 0)

        String actorVoiceType = target.GetVoiceType()
        SUP_F4SEVR.WriteStringToFile("_mantella_actor_voice.txt", actorVoiceType, 0)
        ;the below is to build a substring to use later to find the correct wav file 
        String isEnemy = "False"
        if (target.getcombattarget() == PlayerRef)
            isEnemy = "True"
        endIf
        SUP_F4SEVR.WriteStringToFile("_mantella_actor_is_enemy.txt", isEnemy, 0)

        String currLoc = (caster.GetCurrentLocation() as form).getname()
        if currLoc == ""
            currLoc = "Boston area"
        endIf
        SUP_F4SEVR.WriteStringToFile("_mantella_current_location.txt", currLoc, 0)

        int Time = GetCurrentHourOfDay()
        SUP_F4SEVR.WriteStringToFile("_mantella_in_game_time.txt", Time, 0)

        ;will eventually be modified when multi-NPC conversation are added to FO4
        actorCount += 1
        SUP_F4SEVR.WriteStringToFile("_mantella_actor_count.txt", actorCount, 0)

        if actorCount == 1 ; reset player input if this is the first actor selected
            SUP_F4SEVR.WriteStringToFile("_mantella_text_input_enabled.txt", "False", 0)
            SUP_F4SEVR.WriteStringToFile("_mantella_text_input.txt", "", 0)
            ;NEED TO ENABLE ONCE EVENT TRACKING FOR PLAYER IS ADDED
            ;SUP_F4SEVR.WriteStringToFile("_mantella_in_game_events.txt", "", 0)
        endif
        ;debug.notification("Initial setup finished")
        
        if casterIsPlayer
		    Debug.Notification("Starting conversation with " + actorName)
        elseIf actorCount == 1
            Debug.Notification("Starting radiant dialogue with " + actorName + " and " + casterName)
        endIf

        
        repository.endFlagMantellaConversationOne = false
        bool endConversation = false
        string sayFinalLine
        String sayLineFile = "_mantella_say_line_"+actorCount+".txt"
        int loopCount

        ; Wait for first voiceline to play to avoid old conversation playing
        Utility.Wait(0.5)

        SUP_F4SEVR.WriteStringToFile("_mantella_character_selected.txt", "True", 0)
        while repository.endFlagMantellaConversationOne == false && endConversation == false
            if actorCount == 1
                MainConversationLoop( target, caster, loopCount)
                loopCount+=1
            Else
                ConversationLoop(target, caster, actorName, sayLineFile)
            endif


            if sayFinalLine == "True"
                endConversation = True
                localMenuTimer = -1
            endIf
            sayFinalLine = SUP_F4SEVR.ReadStringFromFile("_mantella_end_conversation.txt",0, 2) 
        endWhile
        debug.notification("Conversation with "+actorName+" has ended")
    Else
        Debug.Notification("NPC not added. Please try again after your next response.")    
    endif
    ;cleanup magicactiveeffect
    self.Dispel()
    ;cleanup Onhit event listener
    UnregisterForAllHitEvents(target)

endevent

function MainConversationLoop(Actor target, Actor caster, int loopCount)
        String sayLine = SUP_F4SEVR.ReadStringFromFile("_mantella_say_line.txt",0,99) 

        if sayLine != "False" && !SUP_F4SEVR.IsMenuModeActive()
            target.SetLookAt(caster, false)
            Utility.wait (0.1)
            ;This function is there to activate the lip file, the audio for MantellaDialogue line is actually 10 seconds of silence.
            target.Say(MantellaDialogueLine, abSpeakInPlayersHead=false)
            ;###the function  internalMantellaAudioPlay is deprecated with F4SE 11.60   ###
            ;internalMantellaAudioPlay(sayline, target) 
            externalMantellaAudioPlay(sayline, target)
            SUP_F4SEVR.WriteStringToFile("_mantella_say_line.txt", "False", 0)
            localMenuTimer = -1
           
        endif
            

        if loopCount % 5 == 0
            ;move Time tracking to this section for it to run less frequently
            int Time = GetCurrentHourOfDay()
            SUP_F4SEVR.WriteStringToFile("_mantella_in_game_time.txt", Time, 0)

            String status = SUP_F4SEVR.ReadStringFromFile("_mantella_status.txt",0,99) 
            if status != "False"
                Debug.Notification(status)
                SUP_F4SEVR.WriteStringToFile("_mantella_status.txt", "False", 0)
                if status == "Listening..."
                    repository.writePlayerState()
                endif
            endIf
            
            ;text input to implement later
            String playerResponse = SUP_F4SEVR.ReadStringFromFile ("_mantella_text_input_enabled.txt",0,2) 
            if playerResponse == "True"
                StartTextTimer()
            endIf
        endIf

        if loopCount % 20 == 0
            String radiantDialogue = SUP_F4SEVR.ReadStringFromFile("_mantella_radiant_dialogue.txt",0,2) 
            if radiantDialogue == "True"
                float distanceBetweenActors = caster.GetDistance(target)
                float distanceToPlayer = ConvertGameUnitsToMeter(caster.GetDistance(PlayerRef))
                ;Debug.Notification(distanceBetweenActors)
                ;TODO: allow distanceBetweenActos limit to be customisable
                if (distanceBetweenActors > 1500) || (distanceToPlayer > repository.radiantDistance) || (caster.GetCurrentLocation() != target.GetCurrentLocation()) || (caster.GetCurrentScene() != None) || (target.GetCurrentScene() != None)
                    Debug.messagebox("Conversation ended, possibly because of distance "+distanceBetweenActors)
                    SUP_F4SEVR.WriteStringToFile("_mantella_end_conversation.txt", "True", 0)
                endIf
            endIf
        endIf
endfunction

function externalMantellaAudioPlay(string sayline, actor target)
    ;Get the player's and target position to determine audio direction
    float game_angle_z = PlayerRef.GetAngleZ()
    float playerpositionX=playerref.getpositionX()
    float playerpositionY=playerref.getpositionY()
    float targetpositionX=target.getpositionX()
    float targetpositionY=target.getpositionY()
    float currentDistance=target.GetDistance(playerref)
    string audio_array = currentDistance as string+","+playerpositionX+","+playerpositionY+","+game_angle_z +","+targetpositionX+","+targetpositionY
    SUP_F4SEVR.WriteStringToFile("_mantella_audio_ready.txt", audio_array, 0)
    if repository.notificationsSubtitlesEnabled
        debug.notification(target.GetDisplayName()+":"+sayline)
    endif
    string checkAudioDistance = currentDistance as string
    ;Start a loop waiting to hear back from Python
    debug.trace("Starting while loop waiting for audio to finish playing")
    While checkAudioDistance != "false" && repository.endFlagMantellaConversationOne == false
        checkAudioDistance= SUP_F4SEVR.ReadStringFromFile("_mantella_audio_ready.txt",0,99)
    endwhile
    repository.ResetEventSpamBlockers() ;this allows eventlistener to become active again
endfunction

function ConversationLoop(Actor target, Actor caster, String actorName, String sayLineFile)
    String sayLine = SUP_F4SEVR.ReadStringFromFile(sayLineFile,0,99)
    if sayLine != "False"
        target.SetLookAt(caster, false)
        Utility.wait (0.1)
        ;This function is there to activate the lip file, the audio for MantellaDialogue line is actually 10 seconds of silence.
        target.Say(MantellaDialogueLine, abSpeakInPlayersHead=false)
        ;###the function  internalMantellaAudioPlay is deprecated with F4SE 11.60   ###
        ;internalMantellaAudioPlay(sayline, target) 
        externalMantellaAudioPlay(sayline, target)
        ; Set sayLine back to False once the voiceline has been triggered
        SUP_F4SEVR.WriteStringToFile(sayLineFile, "False", 0)
        localMenuTimer = -1
    endIf
endFunction

function StartTextTimer()
	localMenuTimer=180
    int localMenuTimerInt = Math.Floor(localMenuTimer)
	Debug.Notification("Awaiting player input for "+localMenuTimerInt+" seconds")
	String Monitorplayerresponse
	String timerCheckEndConversation
	;Debug.Notification("Timer is "+localMenuTimer)
	While localMenuTimer >= 0 && repository.endFlagMantellaConversationOne==false
		;Debug.Notification("Timer is "+localMenuTimer)
		Monitorplayerresponse = SUP_F4SEVR.ReadStringFromFile("_mantella_text_input_enabled.txt",0,2) 
		timerCheckEndConversation = SUP_F4SEVR.ReadStringFromFile("_mantella_end_conversation.txt",0,2) 
		;the next if clause checks if another conversation is already running and ends it.
		if timerCheckEndConversation == "true" ;|| repository.endFlagMantellaConversationOne==true (MAYBE ADD THIS BACK?)
			localMenuTimer = -1
            SUP_F4SEVR.WriteStringToFile("_mantella_say_line.txt", "False", 0)
			return
		endif
		if Monitorplayerresponse == "False"
			localMenuTimer = -1
		endif
		If localMenuTimer > 0
			Utility.Wait(1)
			if !SUP_F4SEVR.IsMenuModeActive()
				localMenuTimer = localMenuTimer - 1
			endif
			;Debug.Notification("Timer is "+localMenuTimer)
		elseif localMenuTimer == 0
			Monitorplayerresponse = "False"
			;added this as a safety check in case the player stays in a menu a long time.
            Monitorplayerresponse = SUP_F4SEVR.ReadStringFromFile("_mantella_text_input_enabled.txt",0,2)
			if Monitorplayerresponse == "True"
				;Debug.Notification("opening menu now")
				repository.OpenTextMenu()
                if repository.textinput != ""
                    SUP_F4SEVR.WriteStringToFile("_mantella_text_input_enabled.txt", "False", 0)
                    SUP_F4SEVR.WriteStringToFile("_mantella_text_input.txt", repository.textinput, 0)
                endIf
			endIf
			localMenuTimer = -1
		endIf
	endWhile
endFunction

;string function setWavLocationAndGetReturnLine(string currentLine)
    ;This function tells FO4 from which wav file to read. It also reads the end of the line to be said and chops the end of the said line if it contains a Mutantella1 or Mutantella2 flag.
;    int Mutantella1_Pos = SUP_F4SEVR.SUPStringFind(currentLine, "Mutantella1",0,0)
;    if Mutantella1_Pos>=0
;        currentLine = SUP_F4SEVR.stringFindSubString(currentLine,0,Mutantella1_Pos-1)
;        wavfilelocation="Data\\Sound\\Voice\\Mantella.esp\\MutantellaOutput1.wav"
;    ElseIf Mutantella1_Pos==-1
;        int Mutantella2_Pos = SUP_F4SEVR.SUPStringFind(currentLine, "Mutantella2",0,0)
;        if Mutantella2_Pos>=0
;            currentLine = SUP_F4SEVR.stringFindSubString(currentLine,0,Mutantella2_Pos-1)
;            wavfilelocation="Data\\Sound\\Voice\\Mantella.esp\\MutantellaOutput2.wav"
;        endif
;    else
;        wavfilelocation="Data\\Sound\\Voice\\Mantella.esp\\MutantellaOutput1.wav"
;    endif
;    return currentLine
;endfunction

int function GetCurrentHourOfDay()
	float Time = Utility.GetCurrentGameTime()
	Time -= Math.Floor(Time) ; Remove "previous in-game days passed" bit
	Time *= 24 ; Convert from fraction of a day to number of hours
	int Hour = Math.Floor(Time) ; Get whole hour
	return Hour
endFunction


Float Function ConvertMeterToGameUnits(Float meter)
    Return Meter * meterUnits
EndFunction

Float Function ConvertGameUnitsToMeter(Float gameUnits)
    Return gameUnits / meterUnits
EndFunction

String lastHitSource = ""
String lastAggressor = ""
Int timesHitSameAggressorSource = 0
Event OnHit(ObjectReference akTarget, ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked, string apMaterial)
    if repository.targetTrackingOnHit 
        String aggressor
        if akAggressor == Game.GetPlayer()
            aggressor = "The player"
        else
            aggressor = akAggressor.getdisplayname()
        endif
        string hitSource = akSource.getname()
        String selfName = TargetRefAlias.GetActorReference().getdisplayname()
        ; avoid writing events too often (continuous spells record very frequently)
        ; if the actor and weapon hasn't changed, only record the event every 5 hits
        if ((hitSource != lastHitSource) && (aggressor != lastAggressor)) || (timesHitSameAggressorSource > 5)
            lastHitSource = hitSource
            lastAggressor = aggressor
            timesHitSameAggressorSource = 0
            
            if (hitSource == "None") || (hitSource == "")
                ;Debug.MessageBox(aggressor + " punched "+selfName+".")
                SUP_F4SEVR.WriteStringToFile("_mantella_in_game_events.txt", aggressor + " punched "+selfName+".\n", 2)
            elseif hitSource == "Mantella"
                ; Do not save event if Mantella itself is cast
            elseif akAggressor == TargetRefAlias.GetActorReference()
                if TargetRefAlias.GetActorReference().getleveledactorbase().getsex() == 0
                    SUP_F4SEVR.WriteStringToFile("_mantella_in_game_events.txt", selfName+" hit himself with " + hitSource+".\n", 2)
                else
                    SUP_F4SEVR.WriteStringToFile("_mantella_in_game_events.txt", selfName+" hit herself with " + hitSource+".\n", 2)
                endIf
            else
                ;Debug.MessageBox(aggressor + " hit "+selfName+" with a(n) " + hitSource)
                SUP_F4SEVR.WriteStringToFile("_mantella_in_game_events.txt", aggressor + " hit "+selfName+" with " + hitSource+".\n", 2)
            endIf
        else
            timesHitSameAggressorSource += 1
        endIf
    endif
    ;reapply RegisterForHitEvent, necessary for Onhit to work properly
    RegisterForHitEvent(TargetRefAlias.GetActorReference())
EndEvent

Function StopConversations()
    repository.endFlagMantellaConversationOne = True
    Utility.Wait(0.5)
    repository.endFlagMantellaConversationOne = False
EndFunction