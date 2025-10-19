# Chat Prompt Migration - LLaMA Format

## Summary of Changes

### Files Created
1. **`prompts/chat_response.txt`** - Chat response prompt template (LLaMA format)
2. **`prompts/chat_opening_line.txt`** - Opening line prompt template (LLaMA format)

### Files Modified
1. **`scripts/Chat.gd`** - Updated to load prompts from files

## Prompt Format Change

### Before (Phi-3 Format)
```
<|user|>
You are {npc_name}, a character in a poker game. {backstory}

You are currently playing poker against a human player. The player said to you: "{player_message}"

Respond to the player in character...
<|end|>
<|assistant|>
```

### After (LLaMA Format)
```
<s>
### Instruction:
You are {npc_name}, a character in a poker game. {backstory}

You are currently playing poker against a human player. Respond to the player in character...

### Input:
{player_message}

### Response:
```

## Changes in Chat.gd

### Added
1. **`PROMPTS_DIR` constant**: Points to "prompts/" folder
2. **`_load_prompt_file(filename)` function**: Loads template files from prompts folder
3. **Updated `_clean_llm_response()`**: Now removes LLaMA format markers:
   - `<s>`, `</s>`
   - `### Instruction:`, `### Input:`, `### Response:`

### Modified Functions

#### `_create_chat_prompt(player_message)`
- **Before**: Hardcoded Phi-3 format string
- **After**: 
  - Loads template from `prompts/chat_response.txt`
  - Replaces `{npc_name}`, `{backstory}`, `{player_message}` placeholders
  - Includes fallback hardcoded template if file not found

#### `_create_opening_line_prompt()`
- **Before**: Hardcoded Phi-3 format string
- **After**: 
  - Loads template from `prompts/chat_opening_line.txt`
  - Replaces `{npc_name}`, `{backstory}` placeholders
  - Includes fallback hardcoded template if file not found

## LLaMA Format Structure

### Template Sections
1. **`<s>`** - Start of sequence marker
2. **`### Instruction:`** - System prompt and character description
3. **`### Input:`** - User input or task description
4. **`### Response:`** - Where the model generates output

### Placeholder Variables
- `{npc_name}` - Replaced with NPC's generated name
- `{backstory}` - Replaced with NPC's generated backstory
- `{player_message}` - Replaced with player's chat message (chat_response only)

## Testing Checklist

- [ ] Chat response generation works with new format
- [ ] Opening line generation works with new format
- [ ] LLM response cleaning removes LLaMA markers correctly
- [ ] Fallback prompts work if files are missing
- [ ] Console shows no errors when loading prompt files

## Benefits

1. **Easier prompt editing**: Edit prompts without modifying code
2. **Format flexibility**: Can switch between model formats by editing text files
3. **Better organization**: All prompts in one folder
4. **Version control friendly**: Prompt changes visible in diffs
5. **Reusability**: Same pattern as `npc_generation.txt`

## Compatibility

- **TinyLlama-1.1B-32k-Instruct**: Supports LLaMA instruction format ✅
- **Fallback system**: If files missing, uses hardcoded Phi-3 format
- **Response cleaning**: Handles both Phi-3 and LLaMA markers

## File Locations

```
prompts/
├── npc_generation.txt        # EXISTING: NPC generation prompt (Phi-3)
├── chat_response.txt          # NEW: Chat response prompt (LLaMA)
└── chat_opening_line.txt      # NEW: Opening line prompt (LLaMA)
```

## Notes

- LLaMA format is more structured than Phi-3's chat format
- The `<s>` token marks the beginning of the sequence
- The three-section format (Instruction/Input/Response) is standard for instruction-tuned LLaMA models
- Response cleaning now handles both old and new format markers for backward compatibility
