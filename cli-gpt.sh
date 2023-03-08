#!/bin/sh

# ======================================================== #
# ======================== cli gpt ======================= #
# ======================================================== #

DEFAULT_SAVE_FILEPATH="$HOME/chat-export.md"

messages="[]"
num_messages=0
last_message_type=""


# ~~~~~~~~~~~ validate env vars ~~~~~~~~~~~ #

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Please set OPENAI_API_KEY environment variable."
    exit 1
fi

# ~~~~~~~~~ validate dependencies ~~~~~~~~~ #

if ! command -v gum &> /dev/null
then
    echo "gum could not be found. Please install gum from https://github.com/charmbracelet/gum"
    exit
fi

# if linux
if [ "$(uname)" = "Linux" ]; then
    # if xclip is not installed
    if ! command -v xclip &> /dev/null
    then
        echo "xclip could not be found. Please install xclip."
        exit
    fi
fi

# ~~~~~~~~~~~~~~~~~~ code ~~~~~~~~~~~~~~~~~ #

push_message() {
    role="$1"
    content="$2"
    messages=$(echo "$messages" | jq ". += [{\"role\": \"$role\", \"content\": \"$content\"}]")
    num_messages=$((num_messages+1))
}

get_placeholder() {
    # if the chat is empty, return "Your message"
    if [ "$num_messages" -eq 1 ]; then
        echo "Your message (:h for help)"
    else
        echo "Another message (:q to quit, :h for help)"
    fi
}

get_readme() {
    curl -s https://raw.githubusercontent.com/AlexW00/cli-gpt/master/commands.md
}

show_help() {
    get_readme | gum pager --soft-wrap 
}

prompt_user_message() {
    content=$(gum input --placeholder "$(get_placeholder)")
    # if message is empty, q, exit, or ctrl-c
    if [ -z "$content" ] || [ "$content" = ":q" ] || [ "$content" = "exit" ]; then
        last_message_type="exit"
    elif [ "$content" = ":h" ]; then
        last_message_type="help"
    elif [ "$content" = ":s" ]; then
        last_message_type="save"
    elif [ "$content" = ":c" ]; then
        last_message_type="copy"
    else
        push_message "user" "$content"
        last_message_type="message"
    fi
}

parse_chatgpt_response(){
    # return content of first choice and replace newlines with spaces, double quotes with single quotes
    echo "$1" | jq -r '.choices[0].message.content' | sed -e 's/\\n/ /g' | sed -e 's/"/'\''/g'
}

get_chatgpt_response () {
    # only show the result of the curl command
    gum spin --spinner points --show-output --title "Responding..." -- curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
    \"model\": \"gpt-3.5-turbo\",
    \"messages\": $messages
    }"
}

respond(){
    # get response from chatgpt
    response=$(get_chatgpt_response)
    # parse response
    content=$(parse_chatgpt_response "$response")
    # push message
    push_message "assistant" "$content"
}

messages_to_md() {
    md=""
    # loop through messages
    for row in $(echo "${messages}" | jq -r '.[] | @base64'); do
        _jq() {
            echo "${row}" | base64 --decode | jq -r "${1}"
        }
        role=$(_jq '.role')
        # if role != system
        if [ "$role" != "system" ]; then
            content=$(_jq '.content')
            md+="[$role]:\n"
            md+="$content\n\n"
        fi

    done

    echo -e "$md"
}

save_chat() {
    # get filepath
    filepath=$(gum input --placeholder "$DEFAULT_SAVE_FILEPATH")
    # if filepath is empty, use default
    if [ -z "$filepath" ]; then
        filepath="$DEFAULT_SAVE_FILEPATH"
    fi
    # save chat
    messages_to_md > "$filepath"
    # notify user
    echo "Chat saved to $filepath"
}

copy_to_clipboard() {
    str="$1"
    # on linux, use xclip
    if [ "$(uname)" = "Linux" ]; then
        echo "$str" | xclip -selection clipboard
    # on mac, use pbcopy
    elif [ "$(uname)" = "Darwin" ]; then
        echo "$str" | pbcopy
    fi

    echo "Last message copied to clipboard"
}

copy_last_message() {
    # get last message
    last_message=$(echo "$messages" | jq -r '.[-1].content')
    # copy last message to clipboard using xclip
    copy_to_clipboard "$last_message"
}

show_messages() {
    messages_to_md | gum pager --soft-wrap
}

push_message "system" "You are a helpful assistant. The user is interacting with you through the command line."


while true; do
    # get user message
    prompt_user_message

    if [ "$last_message_type" = "message" ]; then
        respond
        show_messages
    elif [ "$last_message_type" = "help" ]; then
        show_help
    elif [ "$last_message_type" = "save" ]; then
        save_chat
    elif [ "$last_message_type" = "copy" ]; then
        copy_last_message
    else
        exit
    fi

done

