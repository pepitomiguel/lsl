integer dialog_channel;
integer textbox_channel;
integer network_channel;
integer dialogHandle;

string target_text = "Teleporter";
string WarpLocation;

vector target_location = <60, 76, 1293>; // convert to vector array for the list of all possible location
vector home_location;

integer channel()
{ 
    return ((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
}


init()
{
    dialog_channel = channel();
    home_location = llGetPos();
    WarpLocation = llGetObjectName();
    network_channel = 0x80000000 | (integer)("0x"+(string)llGetOwner()) + 712880;
    textbox_channel = (integer)llFrand(DEBUG_CHANNEL)*-1;
    llSitTarget(<0, 0, 0.5>, ZERO_ROTATION);
    llSetSitText(target_text);
    llSetText(target_text, <0, 1, 0>, 1.0);    
}

warp(vector pos)
{
    list rules;
    integer num = llCeil(llVecDist(llGetPos(),pos)/10);
    while(num--)rules=(rules=[])+rules+[PRIM_POSITION,pos];
    llSetPrimitiveParams(rules);
}

open_menu(key inputKey, string inputString, list inputList)
{
    dialogHandle = llListen(dialog_channel, "", inputKey, "");
    llDialog(inputKey, inputString, inputList, dialog_channel);
    llSetTimerEvent(60.0);
}

close_menu()
{
    llSetTimerEvent(0);
    llListenRemove(dialogHandle);
}
 
default
{
    on_rez(integer params)
    {
        init();
        open_menu(llGetOwner(), "Mark this teleporter as " + WarpLocation, ["Yes", "Rename"]);
    }

    state_entry()
    {
        init();
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key sitter = llAvatarOnSitTarget();
            if (sitter != NULL_KEY)
            {
                vector offset = (target_location - llGetPos()) / llGetRot();
                warp(target_location);
                llSleep(0.5);
                llUnSit(sitter);
                warp(home_location);
            }
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        if(channel != dialog_channel)
            return;
             
        close_menu();
        
        if(message == "Rename")
            llTextBox(llGetOwner(), "Rename this portal", textbox_channel);
        if(channel == textbox_channel)
            llSetObjectName(message);
        
            
    }
        
    touch_start(integer i)
    {
        llInstantMessage(llDetectedKey(0), "nRight click and select UP to go upstairs.");
    }
    
    timer()
    {
        close_menu();
    }    
}