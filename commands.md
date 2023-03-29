# Commands

## Flags

(all flags are optional)

- help: `-h`, `--help`
- set model: `-m`, `--model` + `=<model name>` (default = `gpt-3.5-turbo`)
  - e.g. `./cli-gpt -m=gpt-4`
- start with initial prompt: `-p`, `--prompt` + `=<prompt name>`
  - e.g. `./cli-gpt -p="what is 2+2?"`
- list available system prompts: `-ls`, `--list-system-prompts`
- use system prompt: `-s`, `--system-prompt` + `=<prompt name>`
  - e.g. `./cli-gpt -p=default`

## Chat

In the chat, you can use the following commands:

- `:h` - show this help message
- `:q` - quit the program
- `:c` - copy the last message to the clipboard
- `:s` - save the entire chat to a file
