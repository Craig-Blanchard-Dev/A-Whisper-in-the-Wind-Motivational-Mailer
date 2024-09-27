list recipient_keys; 
list motivational_messages;
integer sending_active = FALSE;
integer line_count;
integer lines_loaded;
integer interval_seconds = 14400; // Default interval (4 hours)

// Function to load notecard data
load_notecard()
{
    llGetNumberOfNotecardLines("MotivationalQuotes");
}

default
{
    state_entry()
    {
        llSetText("彡 A Whisper in the Wind 彡\n \n Motivational Mailer", <1, 1, 1>, 1.0); // hover text
        llOwnerSay("Reading motivational quotes from notecard...");
        load_notecard();
    }

    dataserver(key query_id, string data)
    {
        if (data == EOF)
        {
            llOwnerSay("Finished reading quotes. Total quotes: " + (string)lines_loaded);
        }
        else if (query_id != NULL_KEY)
        {
            motivational_messages += data; // Add lines to the list
            lines_loaded++;
            llGetNotecardLine("MotivationalQuotes", lines_loaded); // Read the next line
        }
    }

    touch_start(integer total_number)
    {
        llListen(12345, "", llDetectedKey(0), "");
        llDialog(llDetectedKey(0), "A Whisper in the Wind - Motivational Mailer Menu", 
            ["Add Friend", "Remove Friend", "Start Mailer", "Stop Mailer", "Show Friend List", "Send Instant Message", "Send Test to Myself", "Reload Notecard", "Set Interval"], 12345);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == 12345)
        {
            if (message == "Add Friend")
            {
                llListen(12346, "", id, "");
                llOwnerSay("Please enter the friend's key to add.");
                llTextBox(id, "Enter the friend's profile key to add:", 12346);
            }
            else if (message == "Remove Friend")
            {
                llListen(12347, "", id, "");
                llOwnerSay("Please enter the friend's key to remove.");
                llTextBox(id, "Enter the friend's profile key to remove:", 12347);
            }
            else if (message == "Start Mailer")
            {
                if (!sending_active)
                {
                    llOwnerSay("A Whisper in the Wind mailer started!");
                    sending_active = TRUE;
                    llSetTimerEvent(interval_seconds); // Set the timer
                }
            }
            else if (message == "Stop Mailer")
            {
                llOwnerSay("A Whisper in the Wind mailer stopped.");
                sending_active = FALSE;
                llSetTimerEvent(0);
            }
            else if (message == "Show Friend List")
            {
                string desc = llGetObjectDesc(); // Get keys from description
                list key_list = llParseString2List(desc, [", "], []); // Split with comma and space
                string friend_list = "Friend List:\n";

                integer i;
                for (i = 0; i < llGetListLength(key_list); i++)
                {
                    key friend_key = (key)llList2String(key_list, i); // Get keys
                    string friend_name = llKey2Name(friend_key); // Translate key to name
                    friend_list += friend_name + "\n"; // Append name to list
                }

                llInstantMessage(id, friend_list); // Send list of names to owner
            }
            else if (message == "Send Instant Message")
            {
                if (llGetListLength(motivational_messages) > 0)
                {
                    llOwnerSay("Sending an instant motivational message to all friends.");
                    integer i;
                    integer message_index = llRound(llFrand(llGetListLength(motivational_messages)));
                    string inst_message = llList2String(motivational_messages, message_index);
                
                    for (i = 0; i < llGetListLength(recipient_keys); i++)
                    {
                        key recipient = llList2Key(recipient_keys, i);
                        llInstantMessage(recipient, "\n彡 A Whisper in the Wind 彡\n" +
                            "\n" + inst_message + "\n" +
                            "\n.");
                    }
                }
                else
                {
                    llOwnerSay("No quotes available. Please check the notecard.");
                }
            }
            else if (message == "Send Test to Myself")
            {
                if (llGetListLength(motivational_messages) > 0)
                {
                    llOwnerSay("Sending test message to yourself.");
                    integer message_index = llRound(llFrand(llGetListLength(motivational_messages)));
                    string test_message = llList2String(motivational_messages, message_index);
                    key owner = llGetOwner();
                    llInstantMessage(owner, "\n彡 A Whisper in the Wind 彡\n" +
                        "\n" + test_message + "\n" +
                        "\n.");
                }
                else
                {
                    llOwnerSay("No quotes available. Please check the notecard.");
                }
            }
            else if (message == "Reload Notecard")
            {
                llOwnerSay("Reloading motivational quotes from notecard...");
                motivational_messages = []; // Clear the current list
                lines_loaded = 0; // Reset line counter
                load_notecard(); // Reload the notecard
            }
            else if (message == "Set Interval")
            {
                llListen(12348, "", id, ""); // Listen for the interval selection
                llDialog(id, "Choose the interval for sending messages:", 
                    ["1 Hour", "2 Hours", "4 Hours", "8 Hours", "12 Hours"], 12348);
            }
        }
        else if (channel == 12346) // Add friend
        {
            string current_keys = llGetObjectDesc(); // Get keys from description
            string updated_keys = current_keys + ", " + message; // Append new key
            llSetObjectDesc(updated_keys); // Store updated key list
            llOwnerSay("Friend added by key: " + message);
        }
        else if (channel == 12347) // Remove friend
        {
            string current_keys = llGetObjectDesc();
            list key_list = llParseString2List(current_keys, [", "], []); // Split with comma and space

            if (llListFindList(key_list, [message]) != -1)
            {
                integer idx = llListFindList(key_list, [message]);
                key_list = llDeleteSubList(key_list, idx, idx); // Remove key
                string updated_keys = llDumpList2String(key_list, ", "); // Join list back
                llSetObjectDesc(updated_keys); // Update description
                llOwnerSay("Friend removed by key: " + message);
            }
            else
            {
                llOwnerSay("Could not find friend: " + message);
            }
        }
        else if (channel == 12348) // Set interval
        {
            if (message == "1 Hour")
            {
                interval_seconds = 3600; // 1 hour
            }
            else if (message == "2 Hours")
            {
                interval_seconds = 7200; // 2 hours
            }
            else if (message == "4 Hours")
            {
                interval_seconds = 14400; // 4 hours (default)
            }
            else if (message == "8 Hours")
            {
                interval_seconds = 28800; // 8 hours
            }
            else if (message == "12 Hours")
            {
                interval_seconds = 43200; // 12 hours
            }
            llOwnerSay("Message interval set to " + message + ".");
        }
    }

    timer()
    {
        if (llGetListLength(motivational_messages) > 0)
        {
            integer i;
            integer message_index = llRound(llFrand(llGetListLength(motivational_messages)));
            string timed_message = llList2String(motivational_messages, message_index);
            
            for (i = 0; i < llGetListLength(recipient_keys); i++)
            {
                key recipient = llList2Key(recipient_keys, i);
                llInstantMessage(recipient, "\n彡 A Whisper in the Wind 彡\n" +
                    "\n" + timed_message + "\n" +
                    "\n.");
            }

            if (sending_active)
            {
                llSetTimerEvent(interval_seconds); // Reset the timer with the chosen interval
            }
        }
        else
        {
            llOwnerSay("No quotes available. Please check the notecard.");
        }
    }
}
