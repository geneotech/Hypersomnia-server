custom_intents = create_inverse_enum {
	"QUIT",
	"ZOOM_CAMERA"
}

main_input_context = create_input_context {
	intents = { 
		[mouse.raw_motion] 		= intent_message.AIM,
		[keys.W] 				= intent_message.MOVE_FORWARD,
		[keys.S] 				= intent_message.MOVE_BACKWARD,
		[keys.A] 				= intent_message.MOVE_LEFT,
		[keys.D] 				= intent_message.MOVE_RIGHT,

		[keys.LSHIFT] 			= intent_message.SWITCH_LOOK,
		
		[keys.ESC] 				= custom_intents.QUIT,
		[mouse.wheel]			= custom_intents.ZOOM_CAMERA
	}
}