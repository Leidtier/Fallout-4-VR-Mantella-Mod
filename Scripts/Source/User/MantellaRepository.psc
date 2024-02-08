Scriptname MantellaRepository extends Quest
Import SUP_F4SEVR
int textkeycode
string property textinput auto
bool property endFlagMantellaConversationOne auto

Event OnInit()
    ;change the below this is for debug only
    textkeycode=89
    RegisterForKey(textkeycode)
    debug.messagebox("Key registered "+textkeycode)
EndEvent

Event Onkeydown(int keycode)
    if (keycode == textkeycode) && !SUP_F4SEVR.IsMenuModeActive()
        String playerResponse = "False"
        playerResponse = SUP_F4SEVR.ReadStringFromFile("_mantella_text_input_enabled.txt",0,2) 
        if playerResponse == "True" 
            ;Debug.Notification("Forcing Conversation Through Hotkey")
            OpenTextMenu()
        endIf
    endif
Endevent

function OpenTextMenu()
;    TIM:TIM.Open(1,"Enter Mantella text dialogue","", 2, 250)
 ;   RegisterForExternalEvent("TIM::Accept","SetTextInput")
;    RegisterForExternalEvent("TIM::Cancel","NoTextInput")
    ;
    ; Function SetFrequency(string freq)
    ;   Debug.MessageBox("frequency will set at "+ freq)
    ;   UnRegisterForExternalEvent("TIM::Accept")
    ;   UnRegisterForExternalEvent("TIM::Cancel")
    ; EndFunction
    ;
    ; Function NoSetFrequency(string freq)
    ;   Debug.MessageBox("input frequency was aborted at "+ freq)
    ;   UnRegisterForExternalEvent("TIM::Accept")
    ;   UnRegisterForExternalEvent("TIM::Cancel")
    ; EndFunction

endfunction

Function SetTextInput(string text)
    ;Debug.notification("This text input was entered "+ text)
   ; UnRegisterForExternalEvent("TIM::Accept")
  ;  UnRegisterForExternalEvent("TIM::Cancel")
 ;   textinput = text
;    ProcessDialogue(textinput)
EndFunction
    ;
Function NoTextInput(string text)
    ;Debug.notification("Text input cancelled")
  ;  UnRegisterForExternalEvent("TIM::Accept")
  ;  UnRegisterForExternalEvent("TIM::Cancel")
  ;  textinput = ""
EndFunction

Function ProcessDialogue (string text)
    if text != ""
        SUP_F4SEVR.WriteStringToFile("_mantella_text_input_enabled.txt", "False", 0)
        SUP_F4SEVR.WriteStringToFile("_mantella_text_input.txt", textinput, 0)
        ;Debug.notification("Wrote to file "+ textinput)
    endIf
EndFunction