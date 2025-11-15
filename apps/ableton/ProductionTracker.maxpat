{
	"patcher" : 	{
		"fileversion" : 1,
		"appversion" : 		{
			"major" : 8,
			"minor" : 6,
			"revision" : 0,
			"architecture" : "x64",
			"modernui" : 1
		}
,
		"classnamespace" : "box",
		"rect" : [ 34.0, 87.0, 1372.0, 779.0 ],
		"bglocked" : 0,
		"openinpresentation" : 1,
		"default_fontsize" : 12.0,
		"default_fontface" : 0,
		"default_fontname" : "Arial",
		"gridonopen" : 1,
		"gridsize" : [ 15.0, 15.0 ],
		"gridsnaponopen" : 1,
		"objectsnaponopen" : 1,
		"statusbarvisible" : 2,
		"toolbarvisible" : 1,
		"lefttoolbarpinned" : 0,
		"toptoolbarpinned" : 0,
		"righttoolbarpinned" : 0,
		"bottomtoolbarpinned" : 0,
		"toolbars_unpinned_last_save" : 0,
		"tallnewobj" : 0,
		"boxanimatetime" : 200,
		"enablehscroll" : 1,
		"enablevscroll" : 1,
		"devicewidth" : 256.0,
		"description" : "",
		"digest" : "",
		"tags" : "",
		"style" : "",
		"subpatcher_template" : "",
		"assistshowspatchername" : 0,
		"boxes" : [ 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "Production Tracker v1.0.0",
					"fontsize" : 14.0,
					"fontface" : 1,
					"patching_rect" : [ 15.0, 15.0, 220.0, 22.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 5.0, 2.0, 250.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-title"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "loadbang",
					"patching_rect" : [ 15.0, 50.0, 60.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"id" : "obj-loadbang"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "js tracker.js @autowatch 1",
					"patching_rect" : [ 15.0, 100.0, 160.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "", "", "" ],
					"id" : "obj-tracker",
					"saved_object_attributes" : 					{
						"autowatch" : 1,
						"defer" : 0,
						"watch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "js websocket.js @autowatch 1",
					"patching_rect" : [ 200.0, 100.0, 180.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "", "" ],
					"id" : "obj-websocket",
					"saved_object_attributes" : 					{
						"autowatch" : 1,
						"defer" : 0,
						"watch" : 1
					}

			}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "js ableton-api.js @autowatch 1",
					"patching_rect" : [ 400.0, 100.0, 180.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "", "" ],
					"id" : "obj-abletonapi",
					"saved_object_attributes" : 					{
						"autowatch" : 1,
						"defer" : 0,
						"watch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "udpsend localhost 7400",
					"patching_rect" : [ 200.0, 200.0, 140.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-udpsend"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "udpreceive 7401",
					"patching_rect" : [ 200.0, 250.0, 100.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"id" : "obj-udpreceive"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "live.text",
					"text" : "Connect",
					"mode" : 1,
					"patching_rect" : [ 15.0, 300.0, 75.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 5.0, 75.0, 75.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "", "" ],
					"parameter_enable" : 1,
					"saved_attribute_attributes" : 					{
						"valueof" : 						{
							"parameter_enum" : [ "val1", "val2" ],
							"parameter_longname" : "connect_button",
							"parameter_mmax" : 1,
							"parameter_modmode" : 0,
							"parameter_shortname" : "connect",
							"parameter_type" : 2
						}

					}
,
					"varname" : "connect_button",
					"id" : "obj-connect-btn"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "live.text",
					"text" : "Voice Note",
					"mode" : 1,
					"patching_rect" : [ 100.0, 300.0, 80.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 85.0, 75.0, 80.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "", "" ],
					"parameter_enable" : 1,
					"saved_attribute_attributes" : 					{
						"valueof" : 						{
							"parameter_enum" : [ "val1", "val2" ],
							"parameter_longname" : "voice_note_button",
							"parameter_mmax" : 1,
							"parameter_modmode" : 0,
							"parameter_shortname" : "voice",
							"parameter_type" : 2
						}

					}
,
					"varname" : "voice_note_button",
					"id" : "obj-voice-btn"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "live.text",
					"text" : "Snapshot",
					"mode" : 1,
					"patching_rect" : [ 190.0, 300.0, 80.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 170.0, 75.0, 80.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "", "" ],
					"parameter_enable" : 1,
					"saved_attribute_attributes" : 					{
						"valueof" : 						{
							"parameter_enum" : [ "val1", "val2" ],
							"parameter_longname" : "snapshot_button",
							"parameter_mmax" : 1,
							"parameter_modmode" : 0,
							"parameter_shortname" : "snapshot",
							"parameter_type" : 2
						}

					}
,
					"varname" : "snapshot_button",
					"id" : "obj-snapshot-btn"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "live.toggle",
					"patching_rect" : [ 15.0, 350.0, 15.0, 15.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 5.0, 100.0, 15.0, 15.0 ],
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"parameter_enable" : 1,
					"saved_attribute_attributes" : 					{
						"valueof" : 						{
							"parameter_initial" : [ 1 ],
							"parameter_initial_enable" : 1,
							"parameter_longname" : "auto_track",
							"parameter_mmax" : 1,
							"parameter_modmode" : 0,
							"parameter_shortname" : "auto_track",
							"parameter_type" : 2
						}

					}
,
					"varname" : "auto_track",
					"id" : "obj-autotrack-toggle"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "Auto-track",
					"patching_rect" : [ 35.0, 348.0, 80.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 25.0, 98.0, 80.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-autotrack-label"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "live.toggle",
					"patching_rect" : [ 130.0, 350.0, 15.0, 15.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 130.0, 100.0, 15.0, 15.0 ],
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"parameter_enable" : 1,
					"saved_attribute_attributes" : 					{
						"valueof" : 						{
							"parameter_initial" : [ 0 ],
							"parameter_initial_enable" : 1,
							"parameter_longname" : "send_on_save",
							"parameter_mmax" : 1,
							"parameter_modmode" : 0,
							"parameter_shortname" : "send_on_save",
							"parameter_type" : 2
						}

					}
,
					"varname" : "send_on_save",
					"id" : "obj-onsave-toggle"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "Send on Save",
					"patching_rect" : [ 150.0, 348.0, 100.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 150.0, 98.0, 100.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-onsave-label"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "Status:",
					"patching_rect" : [ 15.0, 380.0, 50.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 5.0, 25.0, 50.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-status-label"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "live.text",
					"text" : "●",
					"mode" : 0,
					"patching_rect" : [ 70.0, 380.0, 20.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 55.0, 25.0, 20.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "", "" ],
					"parameter_enable" : 1,
					"saved_attribute_attributes" : 					{
						"valueof" : 						{
							"parameter_enum" : [ "val1", "val2" ],
							"parameter_longname" : "status_indicator",
							"parameter_mmax" : 1,
							"parameter_modmode" : 0,
							"parameter_shortname" : "status",
							"parameter_type" : 2
						}

					}
,
					"varname" : "status_indicator",
					"bgcolor" : [ 0.5, 0.5, 0.5, 1.0 ],
					"id" : "obj-status-indicator"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "Project:",
					"patching_rect" : [ 15.0, 410.0, 50.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 5.0, 40.0, 50.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-project-label"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "---",
					"patching_rect" : [ 70.0, 410.0, 180.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 55.0, 40.0, 195.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-project-name"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "Session:",
					"patching_rect" : [ 15.0, 440.0, 60.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 5.0, 55.0, 60.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-session-label"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "00:00:00",
					"patching_rect" : [ 80.0, 440.0, 80.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 70.0, 55.0, 80.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-session-timer"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "Events:",
					"patching_rect" : [ 15.0, 470.0, 50.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 5.0, 120.0, 50.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-events-label"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "0",
					"patching_rect" : [ 70.0, 470.0, 40.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 55.0, 120.0, 40.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-event-count"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "Last sync:",
					"patching_rect" : [ 130.0, 470.0, 70.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 120.0, 120.0, 70.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-sync-label"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "comment",
					"text" : "--",
					"patching_rect" : [ 205.0, 470.0, 50.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 190.0, 120.0, 60.0, 20.0 ],
					"numinlets" : 1,
					"numoutlets" : 0,
					"id" : "obj-sync-time"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "pattrstorage production_tracker @savemode 0",
					"patching_rect" : [ 600.0, 100.0, 270.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"saved_object_attributes" : 					{
						"client_rect" : [ 100, 100, 500, 600 ],
						"parameter_enable" : 0,
						"parameter_mappable" : 0,
						"paraminitmode" : 0,
						"savemode" : 0,
						"storage_rect" : [ 200, 200, 800, 500 ]
					}
,
					"id" : "obj-pattrstorage"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "live.object live_set",
					"patching_rect" : [ 400.0, 200.0, 110.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"id" : "obj-live-set"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "live.path live_set",
					"patching_rect" : [ 400.0, 150.0, 100.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"id" : "obj-live-path"
				}

			}
, 			{
				"box" : 				{
					"maxclass" : "newobj",
					"text" : "route connect voice_note snapshot setAutoTrack setSendOnSave",
					"patching_rect" : [ 15.0, 150.0, 400.0, 22.0 ],
					"numinlets" : 1,
					"numoutlets" : 6,
					"outlettype" : [ "", "", "", "", "", "" ],
					"id" : "obj-route-ui"
				}

			}
 ],
		"lines" : [ 			{
				"patchline" : 				{
					"source" : [ "obj-loadbang", 0 ],
					"destination" : [ "obj-tracker", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-loadbang", 0 ],
					"destination" : [ "obj-pattrstorage", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-tracker", 0 ],
					"destination" : [ "obj-route-ui", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-tracker", 0 ],
					"destination" : [ "obj-udpsend", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-udpreceive", 0 ],
					"destination" : [ "obj-tracker", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-connect-btn", 0 ],
					"destination" : [ "obj-tracker", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-voice-btn", 0 ],
					"destination" : [ "obj-tracker", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-snapshot-btn", 0 ],
					"destination" : [ "obj-tracker", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-autotrack-toggle", 0 ],
					"destination" : [ "obj-tracker", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-onsave-toggle", 0 ],
					"destination" : [ "obj-tracker", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-live-path", 0 ],
					"destination" : [ "obj-live-set", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-live-set", 0 ],
					"destination" : [ "obj-abletonapi", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"source" : [ "obj-abletonapi", 0 ],
					"destination" : [ "obj-tracker", 0 ]
				}

			}
 ],
		"dependency_cache" : [ 			{
				"name" : "tracker.js",
				"bootpath" : "~/Stemflow/apps/ableton/code",
				"patcherrelativepath" : "./code",
				"type" : "TEXT",
				"implicit" : 1
			}
, 			{
				"name" : "websocket.js",
				"bootpath" : "~/Stemflow/apps/ableton/code",
				"patcherrelativepath" : "./code",
				"type" : "TEXT",
				"implicit" : 1
			}
, 			{
				"name" : "ableton-api.js",
				"bootpath" : "~/Stemflow/apps/ableton/code",
				"patcherrelativepath" : "./code",
				"type" : "TEXT",
				"implicit" : 1
			}
 ],
		"autosave" : 0
	}

}
