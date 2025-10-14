# LLM Prototype Testing Instructions

## Pre-requisites ✅
- [x] LLM model file exists: `llms/llm.gguf` (2.4GB) 
- [x] godot-llm addon installed: `addons/godot_llm/`
- [x] Project configured with autoload and enabled addon

## Testing Steps

### 1. Launch the Prototype
1. Open Godot Editor
2. Load the SpacePoker project
3. **CRITICAL**: Close and restart the Godot editor to ensure autoloads are properly loaded
4. After restarting, the main scene should be set to `scenes/SpikeTest.tscn`
5. Press F5 or click "Play" to run the prototype
6. If you see "LLMClient not available" error, restart the editor again

### 2. Validate UI Responsiveness
1. Enter any text in the input field (e.g., "Hello, how are you?")
2. Click "Send" or press Enter
3. **Expected**: UI should immediately show:
   - Button changes to "Processing..."
   - Input field becomes disabled
   - "[SYSTEM] Processing your request..." appears
   - Status shows "LLM Status: Processing"

### 3. Validate LLM Response
1. Wait for processing to complete (may take 10-30 seconds)
2. **Expected**: 
   - Button returns to "Send"
   - Input field becomes editable
   - LLM response appears with "[LLM]" prefix
   - Status returns to "LLM Status: Ready"

### 4. Test Error Handling
1. Try sending an empty message
2. **Expected**: "[ERROR] Please enter some text first." appears
3. Try sending multiple requests rapidly
4. **Expected**: "[ERROR] LLM is already processing a request. Please wait."

### 5. Test Multiple Interactions
1. Send several different prompts
2. Use "Clear Output" button
3. **Expected**: Conversation history is maintained and can be cleared

## Success Criteria Validation

| Criteria | Test Method | Status |
|----------|-------------|---------|
| Text Input/Output | Send "Hello" → Receive response | ⏳ |
| Non-blocking UI | UI remains responsive during processing | ⏳ |
| Error Handling | Send empty text → See error message | ⏳ |
| Async Communication | Button states change appropriately | ⏳ |
| Reusable Architecture | LLMClient singleton accessible | ✅ |

## Troubleshooting

### If LLM doesn't initialize:
- Check console for "LLMClient: GDLlama initialized successfully"
- Verify model file exists at correct path
- Ensure godot-llm addon is enabled in project settings

### If responses are slow:
- This is normal for local LLM processing
- Consider reducing `n_predict` in LLMClient.gd
- Monitor system resources (CPU/RAM usage)

### If addon not found:
- Restart Godot editor
- Check `addons/godot_llm/` folder exists
- Verify addon is enabled in project settings

## Console Output to Monitor

**Successful initialization:**
```
LLMClient: Initializing...
LLMClient: GDLlama initialized successfully
SpikeTest: Initializing test scene
SpikeTest: Ready for testing
```

**Successful request/response:**
```
SpikeTest: Sending input: Hello
LLMClient: Sending prompt: Hello...
LLMClient: Text generation completed
SpikeTest: Received response: [response text]...
```

## Next Development Steps

Once prototype is validated:
1. Restore main scene to original start_scene.tscn
2. Integrate LLMClient into main game architecture
3. Implement NPC personality generation
4. Add chat interface to poker game view