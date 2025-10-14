# SpacePoker LLM Prototype

This is a technical spike to validate the integration of a local LLM with Godot Engine using the `godot-llm` addon.

## Files Created

### Core Components
- **`scripts/LLMClient.gd`** - Autoload singleton that wraps the godot-llm addon
  - Provides centralized LLM communication
  - Handles async requests with signals
  - Includes error handling and status management
  
- **`scenes/SpikeTest.tscn`** - Minimal test scene for the prototype
  - Simple UI with input field, send button, and output area
  - Disposable test interface for validation
  
- **`scripts/SpikeTest.gd`** - Test scene script
  - Handles UI interactions
  - Connects to LLMClient signals
  - Displays requests, responses, and errors

### Project Configuration
- **`project.godot`** - Updated with:
  - `LLMClient` autoload singleton
  - `godot_llm` addon enabled

## Setup Requirements

1. **LLM Model**: Ensure `llms/llm.gguf` exists (Phi-3-mini model)
2. **Addon**: The `godot-llm` addon should be in `addons/godot_llm/`
3. **Project Reload**: Restart Godot editor to load the autoload singleton

## Testing the Prototype

1. Open the SpikeTest scene: `scenes/SpikeTest.tscn`
2. Run the scene
3. Enter text in the input field
4. Click "Send" or press Enter
5. Observe the async communication:
   - UI shows "Processing..." state
   - Loading indicator appears
   - Response appears when completed
   - Errors are handled gracefully

## Success Criteria

✅ **Text Input/Output**: Send text prompt and receive LLM response  
✅ **Non-blocking UI**: Interface remains responsive during processing  
✅ **Error Handling**: Graceful handling of LLM failures  
✅ **Async Communication**: Proper signal-based async handling  
✅ **Reusable Architecture**: LLMClient can be used by other game components  

## Architecture Benefits

- **Separation of Concerns**: LLMClient isolates LLM complexity
- **Signal-based Communication**: Clean async pattern for UI updates
- **Error Resilience**: Comprehensive error handling and user feedback
- **Extensible Design**: Easy to add features like streaming responses
- **Debug-friendly**: Extensive logging for troubleshooting

## Next Steps

After successful validation:
1. Integrate LLMClient into main game for NPC personality generation
2. Add chat functionality to the poker game interface
3. Implement personality extraction from LLM-generated backstories
4. Create rule-based AI that uses personality factors for game decisions

## Technical Notes

- **Model Path**: Configured for `res://llms/llm.gguf`
- **Context Size**: 2048 tokens (sufficient for chat responses)
- **Response Length**: Limited to 150 tokens (reasonable for game chat)
- **Temperature**: 0.7 (balanced creativity for personalities)
- **Threading**: 4 CPU threads (adjust based on target hardware)