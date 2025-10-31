# Chat Prompt Migration - Phi-3 Format

## Summary of Changes

### Files Created
1. **`prompts/chat_response.txt`** - Chat response prompt template (Phi-3 format)
2. **`prompts/chat_opening_line.txt`** - Opening line prompt template (Phi-3 format)

### Files Modified
1. **`scripts/Chat.gd`** - Updated to load prompts from files and handle Phi-3 format

## Prompt Format

### Phi-3 Format
```
<|user|>
You are {npc_name}, a character in a poker game. {backstory}

You are currently playing poker against a human player. Respond to the player in character...

The player said to you: "{player_message}"

Output your response as valid JSON with this format:
{
  "response": "your in-character response here"
}<|end|>
<|assistant|>
```

## Changes in Chat.gd

### Added
1. **`PROMPTS_DIR` constant**: Points to "prompts/" folder
2. **`_load_prompt_file(filename)` function**: Loads template files from prompts folder
3. **Updated `_clean_llm_response()`**: Removes Phi-3 format markers:
   - `<|user|>`, `<|end|>`, `<|assistant|>`

### Modified Functions

#### `_create_chat_prompt(player_message)`
- Loads template from `prompts/chat_response.txt`
- Replaces `{npc_name}`, `{backstory}`, `{player_message}` placeholders
- Uses Phi-3 chat format

#### `_create_opening_line_prompt()`
- Loads template from `prompts/chat_opening_line.txt`
- Replaces `{npc_name}`, `{backstory}` placeholders
- Uses Phi-3 chat format

#### `_extract_json_from_response()`
- Finds the last `<|assistant|>` marker and extracts everything after it
- Removes Phi-3 format markers
- Extracts JSON object boundaries

## Phi-3 Format Structure

### Template Sections
1. **`<|user|>`** - Start of user message/instruction
2. **Instruction and context** - System prompt and character description
3. **`<|end|>`** - End of user message
4. **`<|assistant|>`** - Where the model generates output

### Placeholder Variables
- `{npc_name}` - Replaced with NPC's generated name
- `{backstory}` - Replaced with NPC's generated backstory
- `{player_message}` - Replaced with player's chat message (chat_response only)
- `{conversation_history}` - Replaced with conversation history text

## Testing Checklist

- [ ] Chat response generation works with Phi-3 format
- [ ] Opening line generation works with Phi-3 format
- [ ] LLM response cleaning removes Phi-3 markers correctly
- [ ] Fallback prompts work if files are missing
- [ ] Console shows no errors when loading prompt files

## Benefits

1. **Easier prompt editing**: Edit prompts without modifying code
2. **Consistent format**: All prompts use the same Phi-3 format
3. **Better organization**: All prompts in one folder
4. **Version control friendly**: Prompt changes visible in diffs
5. **Single model**: Phi-3 handles all LLM operations with optimized parameters

## Compatibility

- **Phi-3-mini-4k-instruct**: Supports both LLaMA and Phi-3 instruction formats ✅
- **Fallback system**: If files missing, uses hardcoded Phi-3 format
- **Response cleaning**: Handles both Phi-3 and LLaMA markers

## Note on Model Usage

This project uses Phi-3-mini-4k-instruct-q4 for all LLM operations (both NPC generation and chat). The chat configuration uses optimized parameters (reduced context size and token prediction) for faster response times while maintaining quality.

## File Locations

```
prompts/
├── npc_generation.txt        # NPC generation prompt (Phi-3 format)
├── chat_response.txt          # Chat response prompt (Phi-3 format)
└── chat_opening_line.txt      # Opening line prompt (Phi-3 format)
```

## Notes

- Phi-3 format uses special tokens: `<|user|>`, `<|end|>`, `<|assistant|>`
- The same Phi-3 model is used for both NPC generation and chat with different optimization parameters
- NPC generation uses: context_size=4096, n_predict=512 (detailed backstories)
- Chat uses: context_size=2048, n_predict=100 (faster responses)
- Response cleaning handles Phi-3 markers for clean JSON extraction
