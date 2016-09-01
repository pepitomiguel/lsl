integer dialog_channel;
integer textbox_channel;
integer network_channel;
integer dialogHandle;
integer secret_key = ;
integer dialog_active;

string target_text = "Teleporter";
string WarpLocation;

list target_location; // list with the corresponding portal name and its vectors.

vector home_location;
vector warp_vector;

integer channel()
{ 
    return ((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
}


init()
{
    dialog_channel = channel();
    home_location = llGetPos();
    WarpLocation = llGetObjectName();
    network_channel = 0x80000000 | (integer)("0x"+(string)llGetOwner()) + secret_key;
    textbox_channel = (integer)llFrand(DEBUG_CHANNEL)*-1;
    target_location = [ WarpLocation+":"+(string)home_location ];
    
    llSitTarget(<0, 0, 0.5>, ZERO_ROTATION);
    llSetSitText(target_text);
    llSetText(target_text, <0, 1, 0>, 1.0);
    
    llRegionSay(network_channel, WarpLocation +":"+ (string)home_location);
    llSetTimerEvent(5.0);
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
    llSetTimerEvent(0);
    dialog_active = TRUE;
    dialogHandle = llListen(dialog_channel, "", inputKey, "");
    llDialog(inputKey, inputString, inputList, dialog_channel);
    llSetTimerEvent(60.0);
}

close_menu()
{
    llSetTimerEvent(0);
    dialog_active = FALSE;
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
                vector offset = (warp_vector - llGetPos()) / llGetRot();
                warp(warp_vector);
                llSleep(0.5);
                llUnSit(sitter);
                warp(home_location); // change the variable given by the listen events
            }
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        if(channel != dialog_channel || channel != textbox_channel)
            return;
             
        close_menu();
        
        if(message == "Rename")
            llTextBox(llGetOwner(), "Rename this portal", textbox_channel);
        if(message == "OK")
        {
            list details = llGetObjectDetails(id,[OBJECT_POS]);
            //ping each warp portal and get the corresponding position vector, if there is no reply remove the warp name
            //listen to command "remove:<warp name>" and remove in the list the corresponding portal.
        }
        if(channel == textbox_channel)
        {
            llSetObjectName(message);
            WarpLocation = llGetObjectName();
            llRegionSay(network_channel, WarpLocation +":"+ (string)home_location);
        }
        // TODO:
        // listen for the message and check if it matches the available portal then extract the corresponding vector then
        // pass it on the variable for the warp function.
        // Listen for the llRegionSay won channel network_channel then scrape the data to be added on the target_location list
            
    }
        
    touch_start(integer i)
    {
        //check if the id is owner then add a menu option to configure if the teleporter acces too group, owner, all, specific group uuid, specific avatar uuid
        //Show all the possible portals depending on the owner's settings.
        
    }
    
    timer()
    {
        if (dialog_active)
            close_menu();
        if(home_location != llGetPos())
        {
            llSay(0,"Position Changed");
            home_location = llGetPos();
            llRegionSay(network_channel, WarpLocation +":"+ (string)home_location);
        }
    }    
}
