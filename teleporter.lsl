integer CHANNEL = -10001;
float INTERVAL = 10.0;
vector OFFSET = <0.0,0.0,1.2>;

integer number = 1;
list descriptions = [];
list positions = [];
list timestamps = [];

// Function present menu items in more logical ordering.
list orderButtons(list buttons)
{
    return(llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
         + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10));
}

default
{

    state_entry()
    {

        // Announce teleporter and setup timer to maintain teleporter list.
        key owner = llGetOwner();
        string description = llGetObjectDesc();
        if (description == "<Location name>") {
            description = (string)number;
        }
        vector position = llGetPos();
        llRegionSay(CHANNEL, "teleporter\t" + (string)owner + "\t" + description + "\t" + (string)position);
        llSetTimerEvent(INTERVAL);
        
        // Setup listener to receive teleporter announcements and user dialog.
        llListen(CHANNEL, "", "", "");
        
        // Configure sit text and target.
        llSetSitText("Teleport");
        llSitTarget(OFFSET, ZERO_ROTATION);
        
    }

    changed(integer change)
    {
        
        // Check if someone sits on the teleporter.
        if (change & CHANGED_LINK) {
            key id = llAvatarOnSitTarget();
            if (id) {
                if (llGetInventoryNumber(INVENTORY_ANIMATION) >= 1) {
                    llRequestPermissions(id, PERMISSION_TRIGGER_ANIMATION);
                }
                if (llGetInventoryNumber(INVENTORY_SOUND) >= 1) {
                    llPlaySound(llGetInventoryName(INVENTORY_SOUND, 0), 1.0);
                }
                integer count = llGetListLength(descriptions);
                if (count >= 2) {
                    list buttons = orderButtons(llListSort(descriptions, 1, TRUE));
                    llDialog(id, "Select destination:", buttons, CHANNEL);
                }
                else if (count == 1) {
                    vector position = llGetPos();
                    llSleep(0.5);
                    if (llSubStringIndex(llList2String(descriptions, 0), "*") == 0 && !llSameGroup(id)) {
                        llRegionSayTo(id, 0, "Only group members are allowed to teleport to locations marked with '*'");
                        llUnSit(id);
                    }
                    else if (llSubStringIndex(llList2String(descriptions, 0), "!") == 0 && id != llGetOwner()) {
                        llRegionSayTo(id, 0, "Only the owner are allowed to teleport to locations marked with '!'");
                        llUnSit(id);
                    }
                    else {
                        llSetRegionPos(llList2Vector(positions, 0));
                        llUnSit(id);
                        llSetRegionPos(position);
                    }
                }
                else {
                    llSleep(0.5);
                    llUnSit(id);
                }
            }
        }
        
        // Reset the script if the teleporter has changed owner or been moved across a sim border.
        if (change & (CHANGED_OWNER|CHANGED_REGION)) {
            llResetScript();
        }
        
    }

    listen(integer channel, string name, key id, string message)
    {
        
        if (id == llAvatarOnSitTarget()) {
            
            // Teleport avatar to destination.
            integer index = llListFindList(descriptions, [message]);
            vector position = llGetPos();
            if (llSubStringIndex(llList2String(descriptions, index), "*") == 0 && !llSameGroup(id)) {
                llRegionSayTo(id, 0, "Only group members are allowed to teleport to locations marked with '*'");
                llUnSit(id);
            }
            else if (llSubStringIndex(llList2String(descriptions, index), "!") == 0 && id != llGetOwner()) {
                llRegionSayTo(id, 0, "Only the owner is allowed to teleport to locations marked with '!'");
                llUnSit(id);
            }
            else {
                llSetRegionPos(llList2Vector(positions, index));
                llUnSit(id);
                llSetRegionPos(position);
            }
            
        }
        else {
            
            // Parse the received message.
            list tokens = llParseString2List(message, ["\t"], []);
            string check = llList2String(tokens, 0);
            key owner = (key)llList2String(tokens, 1);
            string description = llList2String(tokens, 2);
            vector position = (vector)llList2String(tokens, 3);
            integer timestamp = llGetUnixTime();
            
            // Remove old data from the lists and add current data.
            if (check == "teleporter" && owner == llGetOwner()) {
                integer index = llListFindList(descriptions, [description]);
                if (~index) {
                    descriptions = llDeleteSubList(descriptions, index, index);
                    positions = llDeleteSubList(positions, index, index);
                    timestamps = llDeleteSubList(timestamps, index, index);
                }
                descriptions += description;
                positions += position;
                timestamps += timestamp;
            }
            
            // Renumber this teleporter if another has same number.
            if ((string)number == description) {
                number++;
                if (number > 12) {
                    number = 1;
                }
            }
            
        }
        
    }

    on_rez(integer n)
    {
        
        // Reset the script when the teleporter is rezzed.
        llResetScript();
        
    }

    run_time_permissions(integer perm)
    {
        
        // Play animation when permission has been granted.
        if (perm & PERMISSION_TRIGGER_ANIMATION) {
            llStartAnimation(llGetInventoryName(INVENTORY_ANIMATION,0));
        }
        
    }

    timer()
    {
        
        // Announce the teleporter.
        key owner = llGetOwner();
        string description = llGetObjectDesc();
        if (description == "<Location name>") {
            description = (string)number;
        }
        vector position = llGetPos();
        integer timestamp = llGetUnixTime();
        llRegionSay(CHANNEL, "teleporter\t" + (string)owner + "\t" + description + "\t" + (string)position);
        
        // Delete oldest teleporter from list if it is too old.
        if (llGetListLength(timestamps) && timestamp-llList2Integer(timestamps, 0) > INTERVAL+1.0) {
            descriptions = llDeleteSubList(descriptions, 0, 0);
            positions = llDeleteSubList(positions, 0, 0);
            timestamps = llDeleteSubList(timestamps, 0, 0);
        }
        
    }

}
